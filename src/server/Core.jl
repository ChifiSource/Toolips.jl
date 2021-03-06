include("Extensions.jl")

"""
### Route
- path::String
- page::Function -
A route is added to a ServerTemplate using either its constructor, or the
ServerTemplate.add(::Route) method. Each route calls a function.
The Route type is commonly constructed using the do syntax with the
route(::Function, ::String) method.
##### example
```
# Constructors
route = Route("/", p(text = "hello"))

function example(c::Connection)
    write!(c, "hello")
end

route = Route("/", example)

# method
route = route("/") do c
    write!(c, "Hello world!")
    write!(c, p(text = "hello"))
    # we can also use extensions!
    c[:logger].log("hello world!")
end
```
------------------
##### field info
- path::String - The path to route to the function, e.g. "/".
- page::Function - The function to route the path to.
------------------
##### constructors
- Route(path::String, f::Function)
"""
mutable struct Route
    path::String
    page::Function
    function Route(path::String, f::Function)
        new(path, f)
    end
end

"""
### ServerTemplate
- ip**::String**
- port**::Integer**
- routes**::Vector{Route}**
- extensions**::Dict**
- remove**::Function**
- add**::Function**
- start**::Function** -
The ServerTemplate is used to configure a server before
running. These are usually made and started inside of a main server file.
##### example
```
st = ServerTemplate()

webserver = ServerTemplate.start()
```
------------------
##### field info
- ip**::String** - IP the server should serve to.
- port**::Integer** - Port to listen on.
- routes**::Vector{Route}** - A vector of routes to provide to the server
- extensions**::Vector{ServerExtension}** - A vector of extensions to load into
the server.
- remove(::Int64)**::Function** - Removes routes by index.
- remove(::String)**::Function** - Removes routes by name.
- remove(::Symbol)**::Function** - Removes extension by Symbol representing
type, e.g. :Logger
- add(::Route ...)**::Function** - Adds the routes to the server.
- add(::ServerExtension ...)**::Function** - Adds the extensions to the server.
- start()**::Function** - Starts the server.
------------------
##### constructors
- ServerTemplate(ip::String = "127.0.0.1", port::Int64 = 8001,
            routes::Vector{Route} = Vector{Route}());
            extensions::Vector{ServerExtension} = [Logger()]
            connection::Type)
"""
mutable struct ServerTemplate
    ip::String
    port::Integer
    routes::Vector{Route}
    extensions::Dict
    remove::Function
    add::Function
    start::Function
    function ServerTemplate(ip::String = "127.0.0.1", port::Int64 = 8000,
        routes::Vector{Route} = Vector{Route}();
        extensions::Vector = [Logger()],
        connection::Type = Connection)
        extensions::Dict = Dict([Symbol(typeof(se)) => se for se in extensions])
        add, remove, start = serverfuncdefs(routes, ip, port, extensions,
        connection)
        new(ip, port, routes, extensions, remove, add, start)::ServerTemplate
    end
end

"""
### WebServer <: ToolipsServer
- host::String
- routes::Dict
- extensions::Dict
- server::Any - 
A web-server is given as a return from a ServerTemplate whenever
ServerTemplate.start() is ran. It can be rerouted with route! and indexed
similarly to the Connection, with Symbols representing extensions and Strings
representing routes.
##### example
```
st = ServerTemplate()
ws = st.start()
routes(ws)
...
extensions(ws)
...
route!(ws, "/") do c::Connection
    write!(c, "hello")
end
```
"""
mutable struct WebServer <: ToolipsServer
    host::String
    routes::Dict
    extensions::Dict
    server::Any
end

"""
**Core**
### serverfuncdefs(::AbstractVector, ::String, ::Integer,
::Dict) -> (::Function, ::Function, ::Function)
------------------
This method is used internally by a constructor to generate the functions add,
start, and remove for the ServerTemplate.
#### example

"""
function serverfuncdefs(routes::AbstractVector, ip::String, port::Integer,
    extensions::Dict, connection::Type)
    add(r::Route ...) = [push!(routes, route) for route in r]
    add(e::ServerExtension ...) = [push!(extensions, ext[1] => ext[2]) for ext in e]
    remove(i::Int64) = deleteat!(routes, i)
    remove(s::String) = deleteat!(findall(routes, r -> r.path == s)[1])
    remove(s::Symbol) = deleteat!(findall(extensions,
                                e -> Symbol(typeof(e)) == s))
    start() = _start(routes, ip, port, extensions, connection)
    return(add, remove, start)
end

"""
**Core - Internals**
### _start(routes::AbstractVector, ip::String, port::Integer,
extensions::Dict, c::Type) -> ::WebServer
------------------
This is an internal function for the ServerTemplate. This function is binded to
    the ServerTemplate.start field.
#### example
```
st = ServerTemplate()
st.start()
```
"""
function _start(routes::AbstractVector, ip::String, port::Integer,
     extensions::Dict, c::Type)
    server = Sockets.listen(Sockets.InetAddr(parse(IPAddr, ip), port))
    if has_extension(extensions, Logger)
        extensions[:Logger].log(1,
         "Toolips Server starting on port " * string(port))
    end
    routefunc, rdct, extensions = generate_router(routes, server, extensions, c)
    @async HTTP.listen(routefunc, ip, port, server = server)
    if has_extension(extensions, Logger)
        extensions[:Logger].log(2,
         "Successfully started server on port " * string(port))
         extensions[:Logger].log(1,
         "You may visit it now at http://" * string(ip) * ":" * string(port))
    end
    return(WebServer(ip, rdct, extensions, server))::WebServer
end

"""
**Core - Internals**
### generate_router(routes::AbstractVector, server::Any, extensions::Dict,
            conn::Type)
------------------
This method is used internally by the **_start** method. It returns a closure
function that both routes and calls functions.
#### example
```
server = Sockets.listen(Sockets.InetAddr(parse(IPAddr, ip), port))
if has_extension(extensions, Logger)
    extensions[Logger].log(1,
     "Toolips Server starting on port " * string(port))
end
routefunc, rdct, extensions = generate_router(routes, server, extensions,
                                                Connection)
@async HTTP.listen(routefunc, ip, port, server = server)
```
"""
function generate_router(routes::AbstractVector, server, extensions::Dict,
    conn::Type)
    route_paths = Dict{String, Function}([route.path => route.page for route in routes])
    # Load Extensions
    ces::Dict = Dict{Any, Any}()
    fes::Vector{ServerExtension} = Vector{ServerExtension}()
    for extension in extensions
        if typeof(extension[2].type) == Symbol
            if extension[2].type == :connection
                push!(ces, extension)
        elseif extension[2].type == :routing
                extension[2].f(route_paths, extensions)
            elseif extension[2].type == :func
                push!(fes, extension[2])
            end
        else
            if :connection in extension[2].type
                push!(ces, extension)
            end
            if :routing in extension[2].type
                extension[2].f(route_paths, extensions)
            end
            if :func in extension[2].type
                push!(fes, extension[2])
            end
        end
    end
    # Routing func
    routeserver::Function = function serve(http::HTTP.Stream)
        fullpath::String = http.message.target
        if contains(http.message.target, "?")
            fullpath = split(http.message.target, '?')[1]
        end
        c::AbstractConnection = conn(route_paths, http, ces)
        if fullpath in keys(route_paths)
            [extension.f(c) for extension in fes]
            route_paths[fullpath](c)
        else
            [extension.f(c) for extension in fes]
            route_paths["404"](c)
        end
    end # serve()
    return(routeserver, route_paths, extensions)
end
