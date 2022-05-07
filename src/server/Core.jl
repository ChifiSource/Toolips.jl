include("log.jl")
mutable struct Connection
    routes::Dict
    http::HTTP.Stream
    extensions::Vector{Any}
    function Connection(routes::Dict, http::HTTP.Stream,extensions::Vector{Any})
        new(routes, http, extensions)::Connection
    end
end
write!(c::Connection, s::Any) = write!(http, s)
write!(c::Connection, s::Servable) = write(http, s.f(c))

"""
Must contain field
SE.type!
"""
abstract type ServerExtension end

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
mutable struct Route{S}
    path::String
    page::Page
    function Route(path::String, page::Page)
        new(path, page)
    end
end

routes(rs::Route ...) = Vector{Route}([r for r in rs])
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
- Route(path::String, page::Function)
- Route(path::String, page::Page)
- Route(path::String, page::FormComponent)
- Route(path::String, page::Component)
"""
mutable struct ServerTemplate
    ip::String
    port::Integer
    routes::Vector{Route}
    extensions::Vector{Any}
    remove::Function
    add::Function
    start::Function
    function ServerTemplate(ip::String = "127.0.0.1", port::Int64 = 8001,
        routes::Vector{Route} = Vector{Route}();
        extensions::Any ...)
        extensions::Vector = [e for e in extensions]
        add, remove, start = serverfuncdefs(routes, ip, port, extensions)
        new(ip, port, routes, extensions, remove, add, start)::ServerTemplate
    end
end

function serverfuncdefs(routes::AbstractVector, ip::String, port::Integer,
    extensions::Vector)
    add(r::Route{Function}) = push!(routes, r)
    add(r::Route{Component}) = push!(routes, r)
    add(e::Any ...) = [push!(extensions, ext[1] => ext[2]) for ext in e]
    remove(i::Int64) = deleteat!(routes, i)
    start() = _start(routes, ip, port, extensions)
    return(add, remove, start)
end

function _start(routes::AbstractVector, ip::String, port::Integer, extensions::Vector{Any})
    server = Sockets.listen(Sockets.InetAddr(parse(IPAddr, ip), port))
    logger.log(1, "Toolips Server starting on port " * string(port))
    routefunc = generate_router(routes, server, logger)
    @async HTTP.listen(routefunc, ip, port, server = server)
    logger.log(2, "Successfully started server on port " * string(port))
    logger.log(1,
    "You may visit it now at http://" * string(ip) * ":" * string(port))
    return(server)
end

function generate_router(routes::AbstractVector, server, extensions::Any)
    route_paths = Dict([route.path => route.page for route in routes])
    # Load Extensions
    ces::Vector{ServerExtension} = Vector{ServerExtension}()
    fes::Vector{ServerExtension} = Vector{ServerExtension}()
    for extension in extensions
        if extension.type == :connection
            push!(ces, extension)
        elseif extension.type == :routing
            extension.f(route_paths)
        elseif extension.type == :func
            push!(fes, extension)
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

function stop!(x::Any)
    close(x)
end