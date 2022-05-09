include("Extensions.jl")
mutable struct Connection
    routes::Dict
    http::HTTP.Stream
    extensions::Dict
    function Connection(routes::Dict, http::HTTP.Stream,extensions::Vector{Any})
        new(routes, http, extensions)::Connection
    end
end
write!(c::Connection, s::Any) = write!(http, s)
write!(c::Connection, s::Servable) = write(http, s.f(c))

"""
### Route{T}
- path::String
- page::T
------------------
##### Field Info
- **path::String**
The path, e.g. "/" at which to direct to the given component.
- **page::T** (::Function || T <: Component)
The servable to serve at this given route.
------------------
##### Constructors
- Route(path::String, f::Function)
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
- extensions
------------------
##### Field Info
- ip**::String**
- port**::Integer**
- routes**::Vector{Route}**
------------------
##### Constructors
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

function serverfuncdefs(routes::AbstractVector, ip::String, port::Integer,
    extensions::Dict)
    add(r::Route{Function}) = push!(routes, r)
    add(r::Route{Servable}) = push!(routes, r)
    add(e::Any ...) = [push!(extensions, ext[1] => ext[2]) for ext in e]
    remove(i::Int64) = deleteat!(routes, i)
    start() = _start(routes, ip, port, extensions)
    return(add, remove, start)
end

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
    routefunc = generate_router(routes, server, extensions)
    @async HTTP.listen(routefunc, ip, port, server = server)
    if logger != nothing
        logger.log(2, "Successfully started server on port " * string(port))
        logger.log(1,
        "You may visit it now at http://" * string(ip) * ":" * string(port))
    end
    return(server)
end

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
        HTTP.setheader(http, "Content-Type" => "text/html")
        fullpath::String = http.message.target
        if contains(fullpath, '?')
            fullpath = split(http.message.target, '?')[1]
        end
        c::Connection = Connection(route_paths, http, ces)
        if fullpath in keys(route_paths)
            if typeof(route_paths[fullpath]) <: Servable
                route_paths[fullpath].f(c)
                [extension.f(c) for extension in fes]
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
    return(routeserver)
end
