"""
**Interface**
### L_str(s::String) -> ::String
------------------
Creates a literal string
#### example
```
x = 5
L"dollar_signx" # pretend dollar_sign is a dollar sign.
```
"""
macro L_str(s::String)
    s
end

"""
**Interface**
### properties!(c::Servable, s::Servable) -> _
------------------
Copies properties from s,properties into c.properties.
#### example
```
comp = Component()
othercomp = Component()
othercomp["opacity"] = "100%"
properties!(comp, othercomp)

comp["opacity"]
        100%
```
"""
properties!(c::Servable, s::Servable) = merge!(c.properties, s.properties)

"""
**Interface**
### has_children(c::Component) -> ::Bool
------------------
Returns true if the given component has children.
#### example
```
c = Component()
otherc = Component()
push!(c, otherc)

has_children(c)
    true
has_children(otherc)
    false
```
"""
function has_children(c::Component)
    if length(c[:children]) != 0
        return true
    else
        return false
    end
end

"""
**Interface**
### push!(s::Component, d::Component ...) -> ::Component
------------------
Adds the child or children d to s.properties[:children]
#### example
```
c = Component()
otherc = Component()
push!(c, otherc)
```
"""
push!(s::Component, d::Component ...) = [push!(s[:children], c) for c in d]

"""
**Interface**
### getindex(s::Component, symb::Symbol) -> ::Any
------------------
Returns a property value by symbol or name.
#### example
```
c = p("hello", text = "Hello world")
c[:text]
    "Hello world!"

c["opacity"] = "50%"
c["opacity"]
    "50%"
```
"""
getindex(s::Component, symb::Symbol) = s.properties[symb]

"""
**Interface**
### getindex(::Servable, ::String) -> ::Any
------------------
Returns a property value by string or name.
#### example
```
c = p("hello", text = "Hello world")
c[:text]
    "Hello world!"

c["opacity"] = "50%"
c["opacity"]
    "50%"
```
"""
getindex(s::Servable, symb::String) = s.properties[symb]

"""
**Interface**
### setindex!(s::Servable, a::Any, symb::Symbol) -> _
------------------
Sets the property represented by the symbol to the provided value.
#### example
```
c = p("world")
c[:text] = "hello world!"
```
"""
setindex!(s::Servable, a::Any, symb::Symbol) = s.properties[symb] = a

"""
**Interface**
### setindex!(s::Servable, a::Any, symb::String) -> _
------------------
Sets the property represented by the string to the provided value. Use the
appropriate web-format, such as "50%" or "50px".
#### example
```
c = p("world")
c["align"] = "center"
```
"""
setindex!(s::Servable, a::Any, symb::String) = s.properties[symb] = a
#==
Styles
==#
"""
**Interface**
### style!(c::Servable, s::Style) -> _
------------------
Applies the style to a servable.
#### example
```
serv = p("wow")
mystyle = Style("mystyle", color = "lightblue")
style!(serv, mystyle)
```
"""
style!(c::Servable, s::Style) = begin
    if contains(s.name, ".")
        c.properties[:class] = string(split(s.name, ".")[2])
    else
        c.properties[:class] = s.name
    end
    push!(c, s)
end

"""
**Interface**
### style!(c::Servable, s::Pair ...) -> _
------------------
Applies the style pairs to the servable's "style" property.
#### example
```
mycomp = p("mycomp")
style!(mycomp, "background-color" => "lightblue", "color" => "white")
```
"""
function style!(c::Servable, s::Pair ...)
    c["style"] = "'"
    for style in s
        k, v = style[1], style[2]
        c["style"] = c["style"] * "$k: $v;"
    end
    c["style"] = c["style"] * "'"
end

"""
**Interface**
### style!(::Style, ::Style) -> _
------------------
Copies the properties from the second style into the first style.
#### example
```
style1 = Style("firsts")
style2 = Style("seconds")
style1["color"] = "orange"
style!(style2, style1)

style2["color"]
    "orange"
```
"""
style!(s::Style, s2::Style) = merge!(s.properties, s2.properties)

"""
**Interface**
### animate!(s::Style, a::Animation) -> _
------------------
Sets the Animation as a property of the style.
#### example
```
anim = Animation("fade_in")
anim[:from] = "opacity" => "0%"
anim[:to] = "opacity" => "100%"

animated_style = Style("example")
animate!(animated_style, anim)
```
"""
function animate!(s::Style, a::Animation)
    s["animation-name"] = string(a.name)
    s["animation-duration"] = string(a.length) * "s"
    if a.iterations == 0
        s["animation-iteration-count"] = "infinite"
    else
        s["animation-iteration-count"] = string(a.iterations)
    end
    s.extras = s.extras * a.f()
end

"""
**Interface**
### delete_keyframe!(a::Animation, key::Int64) -> _
------------------
Deletes a given keyframe from an animation by keyframe percentage.
#### example
```
anim = Animation("")
anim[0] = "opacity" => "0%"
delete_keyframe!(anim, 0)
```
"""
function delete_keyframe!(a::Animation, key::Int64)
    delete!(s.keyframes, "$key%")
end

"""
**Interface**
### delete_keyframe!(a::Animation, key::Symbol) -> _
------------------
Deletes a given keyframe from an animation by keyframe name.
#### example
```
anim = Animation("")
anim[:to] = "opacity" => "0%"
delete_keyframe!(anim, :to)
```
"""
function delete_keyframe!(a::Animation, key::Symbol)
    delete!(s.keyframes, key)
end

"""
**Interface**
### setindex!(anim::Animation, set::Pair, n::Int64) -> _
------------------
Sets the animation at the percentage of the Int64 to modify the properties of
pair.
#### example
```
a = Animation("world")
a[0] = "opacity" => "0%"
```
"""
function setindex!(anim::Animation, set::Pair, n::Int64)
    prop = string(set[1])
    value = string(set[2])
    n = string(n)
    if n in keys(anim.keyframes)
        anim.keyframes[n] = anim.keyframes[n] * "$prop: $value;"
    else
        push!(anim.keyframes, "$n%" => "$prop: $value; ")
    end
end

"""
**Interface**
### setindex!(anim::Animation, set::Pair, n::Symbol) -> _
------------------
Sets the animation at the corresponding key-word's position. Usually these are
:to and :from.
#### example
```
a = Animation("world")
a[:to] = "opacity" => "0%"
```
"""
function setindex!(anim::Animation, set::Pair, n::Symbol)
    prop = string(set[1])
    value = string(set[2])
    n = string(n)
    if n in keys(anim.keyframes)
        anim.keyframes[n] = anim.keyframes[n] * "$prop: $value; "
    else
        push!(anim.keyframes, "$n" => "$prop: $value; ")
    end
end

"""
**Interface**
### push!(c::AbstractConnection, data::Any) -> _
------------------
A "catch-all" for pushing data to a stream. Produces a full response with
**data** as the body.
#### example
```

```
"""
push!(c::AbstractConnection, data::Any) = write!(c.http, HTTP.Response(200, body = string(data)))
#==
Serving/Routing
==#
"""
**Interface**
### write!(c::AbstractConnection, s::Servable) -> _
------------------
Writes a Servable's return to a Connection's stream. This is usually used in
a routing function or a route where ::Connection is provided as an argument.
#### example
```
serv = p("mycomp", text = "hello")

rt = route("/") do c::Connection
    write!(c, serv)
end
```
"""
write!(c::AbstractConnection, s::Servable) = s.f(c)

"""
**Interface**
### write!(c::AbstractConnection, s::Vector{Servable}) -> _
------------------
Writes all servables in s to c.
#### example
```
c = Component()
c2 = Component()
comps = components(c, c2)
    Vector{Servable}(Component(), Component())

write!(c, comps)
```
"""
function write!(c::AbstractConnection, s::Vector{Servable})
    for s::Servable in s
        write!(c, s)
    end
end

"""
**Interface**
### components(cs::Servable ...) -> ::Vector{Servable}
------------------
Creates a Vector{Servable} from multiple servables. This is useful because
a vector of components could potentially become a Vector{Component}, for example
and this is not the dispatch that is used universally across the package.
#### example
```
c = Component()
c2 = Component()
components(c, c2)
    Vector{Servable}(Component(), Component())
```
"""
components(cs::Servable ...) = Vector{Servable}([s for s in cs])

"""
"""
write!(c::AbstractConnection, s::Servable ...) = write!(c, Vector{Servable}(s))

"""
**Interface**
### write!(c::AbstractConnection, s::String) -> _
------------------
Writes the String into the Connection as HTML.
#### example
```
write!(c, "hello world!")
```
"""
write!(c::AbstractConnection, s::String) = write(c.http, s)

"""
**Interface**
### write!(::AbstractConnection, ::Any) -> _
------------------
Attempts to write any type to the Connection's stream.
#### example
```
d = 50
write!(c, d)
```
"""
write!(c::AbstractConnection, s::Any) = write(c.http, s)

"""
**Interface**
### startread!(::AbstractConnection) -> _
------------------
Resets the seek on the Connection. This function is only meant to be used on
post bodies.
#### example
```
post = getpost(c)
    "hello"
post = getpost(c)
    ""
startread!(c)
post = getpost(c)
    "hello"
```
"""
startread!(c::AbstractConnection) = startread(c.http)

"""
**Interface**
### route!(c::AbstractConnection, route::Route) -> _
------------------
Modifies the route on the Connection.
#### example
```
route("/") do c::Connection
    r = route("/") do c::Connection
        write!(c, "hello")
    end
    route!(c, r)
end
```
"""
route!(c::AbstractConnection, route::Route) = push!(c.routes, route.path => route.page)

"""
**Interface**
### unroute!(::AbstractConnection, ::String) -> _
------------------
Removes the route with the key equivalent to the String.
#### example
```
# One request will kill this route:
route("/") do c::Connection
    unroute!(c, "/")
end
```
"""
unroute!(c::AbstractConnection, r::String) = delete!(c.routes, r)

"""
**Interface**
### route!(::Function, ::AbstractConnection, ::String) -> _
------------------
Routes a given String to the Function.
#### example
```
route("/") do c
    route!(c, "/") do c
        println("tacos")
    end
end
```
"""
route!(f::Function, c::AbstractConnection, route::String) = push!(c.routes, route => f)

"""
**Interface**
### route(f::Function, r::String) -> ::Route
------------------
Creates a route from the Function. The function should take a Connection or
AbstractConnection as a single positional argument.
#### example
```
route("/") do c::Connection

end
```
"""
route(f::Function, r::String) = Route(r, f)::Route

"""
**Interface**
### route(r::String, f::Function) -> ::Route
------------------
Creates a route from the Function. The function should take a Connection or
AbstractConnection as a single positional argument.
#### example
```
function example(c::Connection)
    write!(c, h("myh", 1, text = "hello!"))
end
r = route("/", example)
```
"""
route(r::String, f::Function) = route(r, f)

"""
**Interface**
### routes(::Route ...) -> ::Vector{Route}
------------------
Turns routes provided as arguments into a Vector{Route} with indexable routes.
This is useful because this is the type that the ServerTemplate constructor
likes. This function is also used as a "getter" for WebServers and Connections,
see ?(routes(::WebServer)) & ?(routes(::AbstractConnection))
#### example
```
r1 = route("/") do c::Connection
    write!(c, "pickles")
end
r2 = route("/pickles") do c::Connection
    write!(c, "also pickles")
end
rts = routes(r1, r2)
```
"""
routes(rs::Route ...) = Vector{Route}([r for r in rs])

"""
**Interface**
### routes(ws::WebServer) -> ::Dict{String, Function}
------------------
Returns the server's routes.
#### example
```
ws = MyProject.start()
routes(ws)
    "/" => home
    "404" => fourohfour
```
"""
routes(ws::WebServer) = ws.routes

"""
**Interface**
### routes(c::Connection) -> ::Dict{String, Function}
------------------
Returns the server's routes.
#### example
```
route("/") do c::Connection
    routes(c)
end
```
"""
routes(c::AbstractConnection) = c.routes

"""
**Interface**
### extensions(c::Connection) -> ::Dict{Symbol, ServerExtension}
------------------
Returns the server's extensions.
#### example
```
route("/") do c::Connection
    extensions(c)
end
```
"""
extensions(c::Connection) = c.extensions

"""
**Interface**
### extensions(ws::WebServer) -> ::Dict{Symbol, ServerExtension}
------------------
Returns the server's extensions.
#### example
```
ws = MyProject.start()
extensions(ws)
    :Logger => Logger(blah blah blah)
```
"""
extensions(ws::WebServer) = ws.extensions
#==
    Server
==#
"""
**Interface**
### kill!(ws::WebServer) -> _
------------------

#### example

"""
function kill!(ws::WebServer)
    close(ws.server)
end

"""
"""
function route!(f::Function, ws::WebServer, r::String)
    ws.routes[r] = f
end

"""
"""
route!(ws::WebServer, r::String, f::Function) = route!(f, ws, r)

route!(ws::WebServer, r::Route) = ws[r.path] = r.page

"""
"""
function getindex(ws::WebServer, s::Symbol)
    ws.extensions[s]
end

"""
"""
function getindex(c::AbstractConnection, s::Symbol)
    if ~(s in keys(c.extensions))
        getindex(c, eval(s))
    end
    return(c.extensions[s])
end

function getindex(c::AbstractConnection, t::Type)
    for e in c.extensions
        if e isa t
            return(e)
        end
    end
end

function getindex(d::Dict, t::Type)
    for s in values(d)
        if typeof(s) == t
            return(s)
        end
    end
end

function getindex(vs::Vector{Servable}, str::String)
    for s in vs
        if s.name == str
            return(s)
        end
    end
end

function has_extension(c::AbstractConnection, t::Type)
    se = c[s]
    if typeof(se) <: ServerExtension
        return(true)
    else
        return(false)
    end
end



function has_extension(d::Dict, t::Type)
    se = d[t]
    if typeof(se) <: ServerExtension
        return(true)
    else
        return(false)
    end
end

"""
"""
getindex(c::AbstractConnection, s::String) = c.routes[s]

"""
"""
setindex!(c::AbstractConnection, val::Function, s::String) = c.routes[s] = val

#==
Request/Args
==#
"""
**Interface**
### getargs(::AbstractConnection) -> ::Dict
------------------
The getargs method returns arguments from the HTTP header (GET requests.)
Returns a full dictionary of these values.
#### example

"""
function getargs(c::AbstractConnection)
    target::String = split(c.http.message.target, '?')[2]
    target = replace(target, "+" => " ")
    args = split(target, '&')
    argsplit(args)
end

"""
"""
function argsplit(args::Any)
    arg_dict::Dict = Dict()
    for arg in args
        keyarg = split(arg, '=')
        x = ParseNotEval.parse(keyarg[2])
        push!(arg_dict, Symbol(keyarg[1]) => x)
    end
    return(arg_dict)
end
"""
**Interface**
### getargs(::AbstractConnection, ::Symbol) -> ::Dict
------------------
Returns the requested arguments from the target.
#### example
"""
function getarg(c::AbstractConnection, s::Symbol)
    getargs(c)[s]
end

"""
**Interface**
### getarg(::AbstractConnection, ::Symbol, ::Type) -> ::Vector
------------------
This method is the same as getargs(::HTTP.Stream, ::Symbol), however types are
parsed as type T(). Note that "Cannot convert..." errors are possible with this
method.
#### example
"""
function getarg(c::AbstractConnection, s::Symbol, T::Type)
    parse(T, getargs(http)[s])
end

"""
"""
function getip(c::AbstractConnection)
    str = c.http.message["User-Agent"]
    spl = split(str, "/")
    ipstr = ""
    for sub in spl
        if contains(sub, ".")
            if length(findall(".", sub)) > 1
                ipstr = split(sub, " ")[1]
            end
        end
    end
    return(ipstr)
end

"""
**Interface**
### postarg(::AbstractConnection, ::String) -> ::Any
------------------
Get a body argument of a POST response by name.
#### example

"""
function postarg(c::AbstractConnection, s::String)
    nothing
end


getpost(c::AbstractConnection) = string(read(c.http))
"""
**Interface**
### postargs(::AbstractConnection, ::Symbol, ::Type) -> ::Dict
------------------
Get arguments from the request body.
#### example

"""
function postargs(c::AbstractConnection)
    string(http.message.body)
end

string(r::Vector{UInt8}) = String(UInt8.(r))
"""
**Interface**
### get() -> ::Dict
------------------
Quick binding for an HTTP GET request.
#### example

"""
function get(url::String)
    r = HTTP.request("GET", url)
    string(r.body)
end

"""
**Interface**
### post() ->
------------------
Quick binding for an HTTP POST request.
#### example

"""
function post(url::String)
    r = HTTP.request("POST", url)
    string(r.body)
end

"""
**Interface**
### download!() ->
------------------
Downloads a file to a given user's computer.
#### example
"""
function download!(c::AbstractConnection, uri::String)
    write(c.http, HTTP.Response( 200, body = read(uri, String)))
end

"""
**Interface**
### navigate!(::AbstractConnection, ::String) -> _
------------------
Routes a connected stream to a given URL.
#### example

"""
function navigate!(c::AbstractConnection, url::String)
    HTTP.get(url, response_stream = c.http, status_exception = false)
end

#==
show
==#
function showchildren(x)
    prnt = "##### children \n"
    for c in x[:children]
        prnt = prnt * "|-- " * string(c) * " \n "
        for subc in c[:children]
            prnt = prnt * "   |---- " * string(subc) * " \n "
        end
    end
    prnt
end

function string(c::Component)
    base = c.name
    properties = ": "
    for pair in c.properties
        key, val = pair[1], pair[2]
        if ~(key == :children)
            properties = properties * "  $key = $val  "
        end
    end
    base * properties
end

function show(x::Component)
    prnt = showchildren(x)
    header = "### " * string(x) * "\n"
    display("text/markdown", header * prnt)
end
