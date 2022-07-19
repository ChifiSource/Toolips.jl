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
comp = AbstractComponent()
othercomp = AbstractComponent()
othercomp["opacity"] = "100%"
properties!(comp, othercomp)

comp["opacity"]
        100%
```
"""
properties!(c::Servable, s::Servable) = merge!(c.properties, s.properties)

"""
**Interface**
### getproperties(c::AbstractComponent) -> ::Dict
------------------
Returns a Dict of properties inside of c.
#### example
```
props = properties(c)
```
"""
getproperties(c::AbstractComponent) = c.properties

"""
**Interface**
### children(c::AbstractComponent) -> ::Vector{Servable}
------------------
Returns Vector{Servable} of children inside of c.
#### example
```
children(c)
```
"""
children(c::AbstractComponent) = c.properties[:children]

"""
**Interface**
### copy(c::AbstractComponent) -> ::AbstractComponent
------------------
copies c.
#### example
```
c = p("myp")
t = copy!(c)
```
"""
function copy(c::Component{Any})
    props = copy(c.properties)
    extras = copy(c.extras)
    tag = copy(c.tag)
    name = copy(c.name)
    comp = AbstractComponent(name, tag, props)
    comp.extras = extras
    comp
end

"""
**Interface**
### has_children(c::AbstractComponent) -> ::Bool
------------------
Returns true if the given component has children.
#### example
```
c = AbstractComponent()
otherc = AbstractComponent()
push!(c, otherc)

has_children(c)
    true
has_children(otherc)
    false
```
"""
function has_children(c::AbstractComponent)
    if length(c[:children]) != 0
        return true
    else
        return false
    end
end

"""
**Interface**
### push!(s::AbstractComponent, d::AbstractComponent ...) -> ::AbstractComponent
------------------
Adds the child or children d to s.properties[:children]
#### example
```
c = AbstractComponent()
otherc = AbstractComponent()
push!(c, otherc)
```
"""
push!(s::AbstractComponent, d::AbstractComponent ...) = [push!(s[:children], c) for c in d]

"""
**Interface**
### getindex(s::AbstractComponent, symb::Symbol) -> ::Any
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
getindex(s::AbstractComponent, symb::Symbol) = s.properties[symb]

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
        c.properties[:class] = split(s.name, ".")[2]
        push!(c.extras, s)
end

"""
**Interface**
### :(s::Style, name::String, ps::Vector{Pair{String, String}})
------------------
Creates a sub-style of a given style with the pairs provided in ps.
#### example
```
s = Style("buttonstyle", color = "white")
s["background-color"] = "blue"
s:"hover":["background-color" => "blue"]
```
"""
function (:)(s::Style, name::String, ps::Vector{Pair{String, String}})
    newstyle = Style("$(s.name):$name")
    [push!(newstyle.properties, p) for p in ps]
    push!(s.extras, newstyle)
end

(:)(s::Style, name::String) = s.extras[string(split(name, ":")[2])]::AbstractComponent
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
    style!(c, [p for p in s])
end

"""
**Interface**
### style!(c::Servable, s::Vector{Pair}) -> _
------------------
Applies the style pairs to the servable's "style" property.
#### example
```
mycomp = p("mycomp")
style!(mycomp, ["background-color" => "lightblue", "color" => "white"])
```
"""
function style!(c::Servable, s::Vector{Pair{String, String}})
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
    push!(s.extras, a)
end

"""
**Interface**
### animate!(s::AbstractComponent, a::Animation) -> _
------------------
Sets the animation of a AbstractComponent directly
#### example
```
anim = Animation("fade_in")
anim[:from] = "opacity" => "0%"
anim[:to] = "opacity" => "100%"

myp = p("myp", text = "I fade in!")
animate!(myp, anim)
```
"""
function animate!(s::AbstractComponent, a::Animation)
    push!(s.extras, a)
    if a.iterations == 0
        iters = "infinite"
    else
        iters = string(a.iterations)
    end
    if "style" in keys(s.properties)
        sty = c["style"]
        sty[length(sty)] = " "
        sty = sty * "'animation-name: $(a.name); animation-duration: $(a.length)"
        sty = sty * "animation-iteration-count: $iters;'"
        c["style"] = sty
    else
        str = "'animation-name: $(a.name); animation-duration: $(a.length);"
        str = str * "animation-iteration-count: $iters;'"
        c["style"] = str
    end
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
    delete!(a.properties, "$key%")
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
    delete!(a.properties, string(key))
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
    if n in keys(anim.properties)
        anim.properties[n] = anim.properties[n] * "$prop: $value;"
    else
        push!(anim.properties, "$n%" => "$prop: $value; ")
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
    if n in keys(anim.properties)
        anim.properties[n] = anim.properties[n] * "$prop: $value; "
    else
        push!(anim.properties, "$n" => "$prop: $value; ")
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
c = AbstractComponent()
c2 = AbstractComponent()
comps = components(c, c2)
    Vector{Servable}(AbstractComponent(), AbstractComponent())

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
a vector of components could potentially become a Vector{AbstractComponent}, for example
and this is not the dispatch that is used universally across the package.
#### example
```
c = AbstractComponent()
c2 = AbstractComponent()
components(c, c2)
    Vector{Servable}(AbstractComponent(), AbstractComponent())
```
"""
components(cs::Servable ...) = Vector{Servable}([s for s in cs])

"""
**Interface**
### write!(c::AbstractConnection, s::Servable ...) -> _
------------------
Writes Servables as Vector{Servable}
#### example
```
write!(c, p("mycomp", text = "hello!"), p("othercomp", text = "hi!"))
```
"""
write!(c::AbstractConnection, s::Servable ...) = write!(c, Vector{Servable}(s))

"""
**Interface**
### write!(c::AbstractConnection, s::Vector{AbstractComponent}) -> _
------------------
A catch-all for when Vectors are accidentally stored as Vector{Any}.
#### example
```
write!(c, ["hello", p("mycomp", text = "hello!")])
```
"""
function write!(c::AbstractConnection, s::Vector{Any})
    for servable in s
        write!(c, s)
    end
end

"""
**Interface**
### write!(c::AbstractConnection, s::Vector{AbstractComponent}) -> _
------------------
A catch-all for when Vectors are accidentally stored as Vector{AbstractComponent}.
#### example
```
write!(c, [p("mycomp", text = "bye")])
```
"""
function write!(c::AbstractConnection, s::Vector{AbstractComponent})
    for servable in s
        write!(c, s)
    end
end

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
route(r::String, f::Function) = Route(r, f)::Route

"""
**Interface**
### routes(::Route ...) -> ::Vector{Route}
------------------
Turns routes provided as arguments into a Vector{Route} with indexable routes.
This is useful because this is the type that the ServerTemplate constructor
likes. This function is also used as a "getter" for ToolipsServers and Connections,
see ?(routes(::ToolipsServer)) & ?(routes(::AbstractConnection))
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
routes(rs::AbstractRoute ...) = Vector{AbstractRoute}([r for r in rs])

"""
**Interface**
### routes(ws::ToolipsServer) -> ::Dict{String, Function}
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
routes(ws::ToolipsServer) = ws.routes

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
extensions(c::AbstractConnection) = c.extensions

"""
**Interface**
### extensions(ws::ToolipsServer) -> ::Dict{Symbol, ServerExtension}
------------------
Returns the server's extensions.
#### example
```
ws = MyProject.start()
extensions(ws)
    :Logger => Logger(blah blah blah)
```
"""
extensions(ws::ToolipsServer) = ws.extensions
#==
    Server
==#
"""
**Interface**
### kill!(ws::ToolipsServer) -> _
------------------
Closes the web-server.
#### example
```
ws = MyProject.start()
kill!(ws)
```
"""
function kill!(ws::ToolipsServer)
    close(ws.server)
end

"""
**Interface**
### route!(f::Function, ws::ToolipsServer, r::String) -> _
------------------
Reroutes a server's route r to function f.
#### example
```
ws = MyProject.start()
route!(ws, "/") do c
    c[:Logger].log("rerouted!")
end
```
"""
function route!(f::Function, ws::ToolipsServer, r::String)
    ws.routes[r] = f
end

"""
**Interface**
### route!(ws::ToolipsServer, r::String, f::Function) -> _
------------------
Reroutes a server's route r to function f.
#### example
```
ws = MyProject.start()

function myf(c::Connection)
    write!(c, "pasta")
end
route!(ws, "/", myf)
```
"""
route!(ws::ToolipsServer, r::String, f::Function) = route!(f, ws, r)

"""
**Interface**
### route!(ws::ToolipsServer, r::Route) -> _
------------------
Reroutes a server's route r.
#### example
```
ws = MyProject.start()
r = route("/") do c

end
route!(ws, r)
```
"""
route!(ws::ToolipsServer, r::Route) = ws[r.path] = r.page

"""
**Interface**
### getindex(ws::ToolipsServer, s::Symbol) -> ::ServerExtension
------------------
Indexes the extensions in ws.
#### example
```
ws = MyProject.start()
ws[:Logger].log("hi")
```
"""
function getindex(ws::ToolipsServer, s::Symbol)
    ws.extensions[s]
end



#==
show
==#
"""
**Internals**
### showchildren(x::AbstractComponent) -> ::String
------------------
Get the children of x as a markdown string.
#### example
```
c = divider("example")
child = p("mychild")
push!(c, child)
s = showchildren(c)
println(s)
"##### children
|-- mychild
```
"""
function showchildren(x::AbstractComponent)
    prnt = "##### children \n"
    for c in x[:children]
        prnt = prnt * "|-- " * string(c) * " \n "
        for subc in c[:children]
            prnt = prnt * "   |---- " * string(subc) * " \n "
        end
    end
    prnt
end

"""
**Interface**
### string(c::AbstractComponent) -> ::String
------------------
Shows c as a string representation of itself.
#### example
```
c = divider("example", align = "center")
string(c)
    "divider: align = center"
```
"""
function string(c::AbstractComponent)
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

function show(io::Base.TTY, c::AbstractComponent)
    children = showchildren(c)
    display("text/markdown", """##### $(c.tag)
        $(string(c))
        $children
        """)

end

function show(IO::IO, c::AbstractComponent)
    myc = SpoofConnection()
    write!(myc, c)
    display("text/html", myc.http.text)
end

function display(m::MIME{Symbol("text/html")}, c::AbstractComponent)
    myc = SpoofConnection()
    write!(myc, c)
    display("text/html", myc.http.text)
end
