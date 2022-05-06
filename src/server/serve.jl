include("log.jl")
mutable struct Connection
    routes::Dict
    http::HTTP.Stream
    extensions::Vector{Function}
    servables::Vector{Servable}
    function Connection(routes::Dict, http::HTTP.Stream;
        extensions::Vector{Function} = Vector{Function}())
        new(routes, http, extensions, servables)::Connection
    end
end
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
- Route(path::String, page::Function)
- Route(path::String, page::Page)
- Route(path::String, page::FormComponent)
- Route(path::String, page::Component)
"""
mutable struct Route
    path::String
    page::Page
    function Route(path::String, page::Page)
        new(path, page)
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
- logger**::Logger**
- add**::Function**
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
        extensions = [e for e in extensions]
        add, remove, start = serverfuncdefs(routes, ip, port, extensions)
        new(ip, port, routes, extensions, remove, add, start)
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
    for extension in extensions
    # Routing func
    routeserver::Function = function serve(http)
        HTTP.setheader(http, "Content-Type" => "text/html")
        fullpath::String = http.message.target
        if contains(http.message.target, '?')
            fullpath = split(http.message.target, '?')[1]
        end

        if fullpath in keys(route_paths)
            if typeof(route_paths[fullpath]) <: Servable
                c::Connection = Connection(route_paths, http, servables)
                route_paths[fullpath].f(c)
            else

            end
        else
            if typeof(route_paths["404"]) != Page
                write(http, route_paths["404"](http))
            else
                write(http, route_paths["404"].f(http))
        end
     end

 end # serve()
    return(routeserver)
end
function stop!(x::Any)
    close(x)
end
