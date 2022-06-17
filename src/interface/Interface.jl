"""
**Interface**
### L_str -> _
------------------
Creates a literal string
#### example

"""
macro L_str(s::String)
    s
end

"""
**Interface**
### properties!(::Servable, ::Servable) -> _
------------------
Copies properties from s,properties into c.properties.
#### example

"""
properties!(c::Servable, s::Servable) = merge!(c.properties, s.properties)

function has_children(c::Component)
    if length(c[:children]) != 0
        return true
    else
        return false
    end
end
"""
**Interface**
### push!(::Component, ::Component ...) -> ::Component
------------------

#### example

"""
push!(s::Component, d::Servable ...) = [push!(s[:children], c) for c in d]

"""
**Interface**
### push!(::Component, ::Component) ->
------------------

#### example

"""
push!(s::Component, d::Servable) = push!(s[:children], d)

"""
**Interface**
### getindex(::Servable, ::Symbol) -> ::Any
------------------
Returns a property value by symbol or name.
#### example

"""
getindex(s::Servable, symb::Symbol) = s.properties[symb]

"""
**Interface**
### getindex(::Servable, ::String) -> ::Any
------------------
Returns a property value by string or name.
#### example

"""
getindex(s::Servable, symb::String) = s.properties[symb]

"""
**Interface**
### setindex!(::Servable, ::Symbol, ::Any) -> ::Any
------------------
Sets the property represented by the symbol to the provided value.
#### example

"""
setindex!(s::Servable, a::Any, symb::Symbol) = s.properties[symb] = a

"""
**Interface**
### setindex!(::Servable, ::String, ::Any) -> ::Any
------------------
Sets the property represented by the string to the provided value.
#### example

"""
setindex!(s::Servable, a::Any, symb::String) = s.properties[symb] = a

#==
Styles
==#
"""
**Interface**
### animate!(::StyleComponent, ::Animation) -> _
------------------
Sets the Animation as a rule for the StyleComponent. Note that the
    Animation still needs to be written to the same Connection, preferably in
    a StyleSheet.
#### example

"""
function animate!(s::StyleComponent, a::Animation)
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
### style!(::Servable, ::Style) -> _
------------------
Applies the style to a servable.
#### example

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
"""
function style!(c::Servable, s::Pair ...)
    c["style"] = ""
    for style in s
        k, v = style[1], style[2]
        c["style"] = c["style"] * "$k: $v;"
    end
end

"""
**Interface**
### style!(::Style, ::Style) -> _
------------------
Copies the properties from the second style into the first style.
#### example

"""
style!(s::Style, s2::Style) = merge!(s.properties, s2.properties)

"""
**Interface**
### delete_keyframe!(::Animation, ::String) -> _
------------------
Deletes a given keyframe from an animation by keyframe name.
#### example

"""
function delete_keyframe!(s::Animation, key::String)
    delete!(s.keyframes, key)
end

"""
**Interface**
### setindex!(::Animation, ::Pair, ::Int64) -> _
------------------
Sets the animation at the percentage of the Int64 to modify the properties of
pair.
#### example

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
### setindex!(::Animation, ::Pair, ::Int64) -> _
------------------
Sets the animation at the corresponding key-word's position.
#### example

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
### push!(::Animation, p::Pair) -> _
------------------
Pushes a keyframe pair into an animation.
#### example

"""
push!(anim::Animation, p::Pair) = push!(anim.keyframes, [p[1]] => p[2])

"""
"""
push!(c::AbstractConnection, data::Any) = write!(c.http, HTTP.Response(200, body = string(data)))
#==
Serving/Routing
==#
"""
**Interface**
### write!(::AbstractConnection, ::Servable) -> _
------------------
Writes a Servable's return to a Connection's stream.
#### example

"""
write!(c::AbstractConnection, s::Servable) = s.f(c)

"""
"""
components(cs::Servable ...) = Vector{Servable}([s for s in cs])

"""
**Interface**
### write!(c::AbstractConnection, s::Vector{Servable}) -> _
------------------
Writes, in order of element, each Servable inside of a Vector of Servables.
#### example

"""
function write!(c::AbstractConnection, s::Vector{Servable})
    for s::Servable in s
        write!(c, s)
    end
end

"""
"""
write!(c::AbstractConnection, s::Servable ...) = write!(c, Vector{Servable}(s))

"""
**Interface**
### write!(::AbstractConnection, ::String) -> _
------------------
Writes the String into the Connection as HTML.
#### example

"""
write!(c::AbstractConnection, s::String) = write(c.http, s)

"""
**Interface**
### write!(::AbstractConnection, ::Any) -> _
------------------
Attempts to write any type to the Connection's stream.
#### example

"""
write!(c::AbstractConnection, s::Any) = write(c.http, s)

"""
**Interface**
### startread!(::AbstractConnection) -> _
------------------
Resets the seek on the Connection.
#### example

"""
startread!(c::AbstractConnection) = startread(c.http)

"""
**Interface**
### route!(::AbstractConnection, ::Route) -> _
------------------
Modifies the routes on the Connection.
#### example

"""
route!(c::AbstractConnection, route::Route) = push!(c.routes, route.path => route.page)

"""
**Interface**
### unroute!(::AbstractConnection, ::String) -> _
------------------
Removes the route with the key equivalent to the String.
#### example

"""
unroute!(c::AbstractConnection, r::String) = delete!(c.routes, r)

"""
**Interface**
### route!(::Function, ::AbstractConnection, ::String) -> _
------------------
Routes a given String to the Function.
#### example

"""
route!(f::Function, c::AbstractConnection, route::String) = push!(c.routes, route => f)

"""
**Interface**
### route(::Function, ::String) -> ::Route
------------------
Creates a route from the Function.
#### example

"""
route(f::Function, r::String) = Route(r, f)::Route

"""
"""
route(r::String, f::Function) = route(f, r)

"""
**Interface**
### routes(::Route ...) -> ::Vector{Route}
------------------
Turns routes provided as arguments into a Vector{Route} with indexable routes.
This is useful because this is the type that the ServerTemplate constructor
likes.
#### example

"""
routes(rs::Route ...) = Vector{Route}([r for r in rs])

routes(ws::WebServer) = ws.routes
routes(c::AbstractConnection) = c.routes

extensions(c::Connection) = c.routes
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
