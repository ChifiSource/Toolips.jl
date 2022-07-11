include("Extensions.jl")

"""
"""
mutable struct MissingExtensionError <: Exception
    extension::Type
    f::Function
    function MissingExtensionError(extension::Symbol, f::Function)
        if ~(extension <: ServerExtension)
            throw(ArgumentError("The type provided to exception is not a ServerExtension!"))
        end
        new(extension, f)
    end
end

function showerror(io::IO, e::MissingExtensionError)
    print(io, """Missing Extension Error!
    You are missing the extension $(string(e.extension)), which is required
    by the function $(string(e.f))""")
end

mutable struct ExtensionError <: Exception
    extension::Type
    error::Exception
    message::String
    function ExtensionError(extension::String, error::Exception)
        if ~(extension <: ServerExtension)
            throw(ArgumentError("The type provided to exception is not a ServerExtension!"))
        end
        new(extension, error)
    end
end

function showerror(io::IO, e::ExtensionError)
    print(io, """An extension has caused an error""")
end

mutable struct ConnectionError{fallback} <: Exception
    connection::AbstractConnection
    connection_retry::AbstractConnection
    function ConnectionError(connection::AbstractConnection,
        connection_retry::AbstractConnection; fallback::Bool = false)
        new{fallback}(connection, connection_retry)
    end
end



function warn(c::Connection, e::Exception)
    buff = IOBuffer()
    showerror(buff, e)
    if has_extension(c, :Logger)
        c.logger.log(2, "! Server warning: Error in server \n" * String(buff.data))
    else
        @warn String(buff.data)
    end
end
function warn(e::Exception)
    buff = IOBuffer()
    showerror(buff, e)
    @warn String(buff.data)
end

mutable struct RouteException <: Exception
    route::String
    error::Exception
    RouteException(route::String, error::Exception) = new(route, error)
end

function showerror(io::IO, e::RouteException)
    print(io, "Route $(e.route) on server")
end

mutable struct CoreError <: Exception
    message::String
    CoreError(message::String) = new(message)
end

showerror(io::IO, e::CoreError) = print(io, "Toolips Core Error: $(e.message)")

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
    port::Integer
    routes::Dict
    extensions::Vector{ServerExtension}
    server::Any
    add::Function
    remove::Function
    start::Function
    function WebServer(host::String = "127.0.0.1", port::Integer = 8000;
        routes::Vector{Route} = routes(route("/",
        (c::Connection) -> write!(c, p(text = "Hello world!")))),
        extensions::Vector{ServerExtension} = [Logger()])
        if ~(connection <: AbstractConnection)
            throw(CoreError("'connection' server argument is not a Connection."))
        end
        server = :inactive
        add::Function, remove::Function = serverfuncdefs(routes, host, port)
        start()::Function = _start(host, port, routes, extensions, server)
        new(host, port, routes, extensions, server, add, remove, start)::WebServer
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
mutable struct ServerTemplate{T <: ToolipsServer} <: ToolipsServer
    ip::String
    port::Integer
    routes::Vector{Route}
    extensions::Vector{ServerExtension}
    remove::Function
    add::Function
    start::Function
    function ServerTemplate(host::String = "127.0.0.1", port::Integer = 8000,
        rs::Vector{Route} = Vector{Route}();
        routes::Vector{Route} = routes(route("/",
        (c::Connection) -> write!(c, p(text = "Hello world!")))),
        extensions::Vector{ServerExtension} = [Logger()],
        server::Type = WebServer)
        if length(rs) != 0
            @warn """positional routes for Server templates will be deprecated,
            use ServerTemplate(routes = routes(homeroute)) with routes key-word
            argument instead. This argument is currently vestigal"""
            routes = vcat(routes, rs)
        end
        if ~(server <: ToolipsServer)
            throw(CoreError("Server provided as ServerType is not a ToolipsServer!"))
        end
        servertype = server
        add::Function, remove::Function = serverfuncdefs(routes, extensions)
        start()::Function = _st_start(host, port, routes, extensions, servertype)
        new{servertype}(host, port, routes, extensions, remove, add, start)::ServerTemplate
    end
end

function getindex(v::Vector{ServerExtension}, t::Type)
    # my god, it's beautiful.
    if ~(t <: ServerExtension)
        throw(ExtensionError(t, ArgumentError("$t is not a ServerExtension!")))
    end
    v[findall((x::ServerExtension) -> typeof(x) == t, v)[1]]::ServerExtension
end

function getindex(v::Vector{ServerExtension}, s::Symbol)
    getindex(v, eval(s))
end

"""
**Core**
### serverfuncdefs(routes**::AbstractVector**, extensions::Dict) -> add::Function, remove::Function
------------------
This method is a binding to create server functions from your routes and extensions
dictionary.
#### example

"""
function serverfuncdefs(routes::Vector{Route}, extensions::Vector{ServerExtension})
    # oo baby what a beautiful function.
    add(r::Route ...)::Function = [push!(routes, route) for route in r]
    add(e::ServerExtension ...) = [push!(extensions, ext) for ext in e]
    remove(i::Int64)::Function = deleteat!(routes, i)
    remove(s::String) = deleteat!(findall(routes, r -> r.path == s)[1])
    remove(s::Symbol) = deleteat!(findall(extensions,
                                e -> Symbol(typeof(e)) == s))
    return(add::Function, remove::Function)
end

function _st_start(ip::String, port::Integer, routes::Vector{Route},
    extensions::Vector{ServerExtension}, servertype::Type)
    server::ToolipsServer = servertype(ip, port, routes = routes,
    extensions = extensions)
    server.start()
    return(server)::ToolipsServer
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
function _start(ip::String, port::Integer, routes::Vector{Route},
     extensions::Vector{ServerExtension}, server::Any)
     f(routes, ip, port, extensions, server, stype) = begin
         server = Sockets.listen(Sockets.InetAddr(parse(IPAddr, ip), port))
     if has_extension(extensions, Logger)
         extensions[:Logger].log(1,
          "Toolips Server starting on port $port")
      else
          @warn "Toolips Server starting on port $port"
     end
     routefunc, rdct, extensions = generate_router(routes, server, extensions, c)
     try
         @async HTTP.listen(routefunc, ip, port, server = server)
     catch e
         throw(CoreError("Could not start Server $ip:$port; $(string(e))"))
     end
     if has_extension(extensions, Logger)
         extensions[:Logger].log(2,
          "Successfully started server on port $port")
          extensions[:Logger].log(1,
          "You may visit it now at http://$ip:$port")
      else
          @warn "Successfuly started server on port $port"
          @warn "You may visit it now at http://$ip:$port"
     end
     return(server)
     end
     f
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
function generate_router(routes::Vector{Route}, server::Any,
    extensions::Vector{ServerExtension})
    route_paths = Dict{String, Function}([route.path => route.page for route in routes])
    # Load Extensions
    ces::Vector{ServerExtension} = Vector{ServerExtension}()
    fes::Vector{ServerExtension} = Vector{ServerExtension}()
    for extension in extensions
        if typeof(extension.type) == Symbol
            if extension.type == :connection
                push!(ces, extension)
        elseif extension.type == :routing
            try
                extension.f(route_paths, extensions)
            catch e
                throw(ExtensionError(typeof(extension), e))
            end
        elseif extension.type == :func
                push!(fes, extension)
        end
        else
            if :connection in extension.type
                push!(ces, extension)
            end
            if :routing in extension.type
                try
                    extension.f(route_paths, extensions)
                catch e
                    try
                        extension.f(route_paths, Dict(
                        [Symbol(typeof(e)) => e for e in extensions]))
                        @warn """extension.f with dict of server extensions set
                         to be deprecated. instead, use Vector{ServerExtension.}"""
                     catch
                         throw(ExtensionError(typeof(extension), e))
                     end
                end
            end
            if :func in extension.type
                push!(fes, extension)
            end
        end
    end
    # Routing func
    routeserver::Function = function serve(http::HTTP.Stream)
        fullpath::String = http.message.target
        if contains(http.message.target, "?")
            fullpath = split(http.message.target, '?')[1]
        end
        if fullpath in keys(route_paths)
            try
                [extension.f(c) for extension in fes]
            catch e
                throw(ExtensionError(typeof(extension[2]), e))
            end
            try
                try
                    cT::Type = methods(route_paths[fullpath])[1].sig.parameters[2]
                    c::AbstractConnection = cT(route_paths, http, ces)
                catch
                    c::Connection = Connection(route_paths, http, ces)
                end
                route_paths[fullpath](c)
            catch e
                throw(RouteException(fullpath, e))
            end
            return
        else
            [extension.f(c) for extension in fes]
            try
                route_paths["404"](c)
                return
            catch
                warn(
                RouteException("404",
                CoreError("Tried to return 404, but there is no \"404\" route.")
                ))
                return
            end
        end
    end # serve()
    return(routeserver, route_paths, extensions)
end
