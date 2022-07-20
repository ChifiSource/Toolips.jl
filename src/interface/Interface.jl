




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
