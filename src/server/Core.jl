abstract type ToolipsServer end

"""
### Connection
- routes::Dict
- http::HTTP.Stream
- extensions::Dict
The connection type is passed into route functions and pages as an argument.
This is both for functions, as well as Servable.f() methods. This constructor
    should not be called directly. Instead, it is called by the server and
    passed through the function pipeline. Indexing a Connection will return
        the extension named with that symbol.
##### example
```
                  #  v The Connection
home = route("/") do c
    c[:logger].log("We can index extensions.")
    c.routes["/"] = c::Connection -> write!(c, "rerouting!")
    httpstream = c.http
end
```
------------------
##### Field Info
- **routes::Dict** - A dictionary of routes where the keys
are the routed URL and the values are the functions to
those keys.
- **http::HTTP.Stream** - The stream for this current peer's connection.
- **extensions::Dict** - A dictionary of extensions to load with the
name to reference as keys and the extension as the pair.
------------------
##### Constructors
- Connection
"""
mutable struct Connection
    routes::Dict
    http::HTTP.Stream
    extensions::Dict
    function Connection(routes::Dict, http::HTTP.Stream,extensions::Dict)
        new(routes, http, extensions)::Connection
    end
end

include("Extensions.jl")

"""
### Route{T}
- path::String
- page::T
A route is added to a ServerTemplate using either its constructor, or the
ServerTemplate.add(::Route) method. Each route calls either a particular
servable or function; the type of which denoted by T. The Route type is
    commonly constructed using the do syntax with the route(::Function, String)
    method.
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
##### fields
- **path::String**
The path, e.g. "/" at which to direct to the given component.
- **page::T** (::Function || T <: Component)
The servable to serve at this given route.
------------------
##### constructors
- Route(path::String, f::Function) **where**
- Route(path::String, s::Servable)
"""
mutable struct Route{T}
    path::String
    page::T
    function Route(path::String, f::Function)
        new{Function}(path, f)
    end
    function Route(path::String, s::Servable)
        new{typeof(s)}(path, s)
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
- start**::Function**
The ServerTemplate is used to configure a server before
running. These are usually made and started inside of a main server file.
------------------
##### Field Info
- ip**::String**
- port**::Integer**
- routes**::Vector{Route}**
- extensions**::Dict**
- remove**::Function**
- add**::Function**
- start**::Function**
------------------
##### Constructors
ServerTemplate(ip::String, port::Int64, routes::Dict; extensions::Dict)
"""
mutable struct ServerTemplate
    ip::String
    port::Integer
    routes::Vector{Route}
    extensions::Dict
    remove::Function
    add::Function
    start::Function
    function ServerTemplate(ip::String = "127.0.0.1", port::Int64 = 8001,
        routes::Vector{Route} = Vector{Route}();
        extensions::Dict = Dict(:logger => Logger()))
        add, remove, start = serverfuncdefs(routes, ip, port, extensions)
        new(ip, port, routes, extensions, remove, add, start)::ServerTemplate
    end
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
    extensions::Dict)
    add(r::Route{Function}) = push!(routes, r)
    add(r::Route{Servable}) = push!(routes, r)
    add(e::Any ...) = [push!(extensions, ext[1] => ext[2]) for ext in e]
    remove(i::Int64) = deleteat!(routes, i)
    start() = _start(routes, ip, port, extensions)
    return(add, remove, start)
end

"""
"""
mutable struct WebServer <: ToolipsServer
    host::String
    routes::Dict
    extensions::Dict
    server::Any
end

"""
**Core**
### _start(routes::AbstractVector, ip::String, port::Integer,
extensions::Dict) -> (::Sockets.HTTPServer)
------------------
This is an internal function for the ServerTemplate. This function is binded to
    the ServerTemplate.start field.
#### example

"""
function _start(routes::AbstractVector, ip::String, port::Integer,
     extensions::Dict)
    server = Sockets.listen(Sockets.InetAddr(parse(IPAddr, ip), port))
    logger = nothing
    try
        logger = extensions[:logger]
        logger.log(1, "Toolips Server starting on port " * string(port))
    catch
        logger = nothing
    end
    routefunc, rdct, extensions = generate_router(routes, server, extensions)
    @async HTTP.listen(routefunc, ip, port, server = server)
    if logger != nothing
        logger.log(2, "Successfully started server on port " * string(port))
        logger.log(1,
        "You may visit it now at http://" * string(ip) * ":" * string(port))
    end
    return(WebServer(ip, rdct, extensions, server))
end

"""
**Core**
### generate_router(routes::AbstractVector, server::Any, extensions::Dict)
------------------
This method is used internally by the **_start** method. It returns a closure
function that both routes and calls functions.
#### example

"""
function generate_router(routes::AbstractVector, server, extensions::Dict)
    route_paths = Dict([route.path => route.page for route in routes])
    # Load Extensions
    ces::Dict = Dict()
    fes::Vector{ServerExtension} = Vector{ServerExtension}()
    for extension in extensions
        if extension[2].type == :connection
            push!(ces, extension)
        elseif extension[2].type == :routing
            extension[2].f(route_paths)
        elseif extension[2].type == :func
            push!(fes, extension[2])
        end
    end
    # Routing func
    routeserver::Function = function serve(http::HTTP.Stream)
#        HTTP.setheader(http, "Content-Type" => "text/html")
        fullpath::String = http.message.target
        if contains(fullpath, '?')
            fullpath = split(http.message.target, '?')[1]
        end
        c::Connection = Connection(route_paths, http, ces)
        if fullpath in keys(route_paths)
            if typeof(route_paths[fullpath]) <: Servable
                [extension.f(c) for extension in fes]
                route_paths[fullpath].f(c)
            else
                route_paths[fullpath](c)
            end
        else
            if typeof(route_paths["404"]) <: Servable
                route_paths[fullpath].f(c)
                [extension.f(c) for extension in fes]
            else
                route_paths["404"](c)
            end
        end
    end # serve()
    return(routeserver, route_paths, extensions)
end
