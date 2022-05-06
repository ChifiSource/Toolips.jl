include("log.jl")

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
- logger**::Logger**
- remove**::Function**
- add**::Function**
- public**::String**
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
    logger::Logger
    remove::Function
    add::Function
    start::Function
    public::String
    function ServerTemplate(ip::String = "127.0.0.1", port::Int64 = 8001,
        routes::Vector{Route} = Vector{Route}(); logger::Logger = Logger(),
        public::String = "public")
        add, remove, start = funcdefs(routes, ip, port, logger, public)
        new(ip, port, routes, logger, remove, add, start, public)
    end
end

function funcdefs(routes::AbstractVector, ip::String, port::Integer,
    logger::Logger, public::String)
    add(r::Route{Function}) = push!(routes, r)
    add(r::Route{Component}) = push!(routes, r)
    add(r::Route{Page}) = begin push!(routes, r)
        for comp in r.page.components
            if typeof(comp) != Function
                if typeof(comp) <: FormComponent
                    push!(routes, Route(comp.action, fn(comp.onAction)))
                end
            end
        end
    end
    add(r::Route{FormComponent}) = begin push!(routes, r);
        push!(routes, Route(r.page.action, fn(r.page.onAction)))
    end
    remove(i::Int64) = deleteat!(routes, i)
    start() = _start(routes, ip, port, logger, public)
    return(add, remove, start)
end

function _start(routes::AbstractVector, ip::String, port::Integer,
    logger::Logger, public::String)
    public_rs = route_from_dir(public)
    routes = vcat(routes, public_rs)
    server = Sockets.listen(Sockets.InetAddr(parse(IPAddr, ip), port))
    logger.log(1, "Toolips Server starting on port " * string(port))
    routefunc = generate_router(routes, server, logger)
    @async HTTP.listen(routefunc, ip, port, server = server)
    logger.log(2, "Successfully started server on port " * string(port))
    logger.log(1,
    "You may visit it now at http://" * string(ip) * ":" * string(port))
    return(server)
end
function generate_router(routes::AbstractVector, server, logger::Logger)
    route_paths = Dict([route.path => route.page for route in routes])
    servables::OddFrame = OddFrame(:ID => [], :properties => [], :tag => [])
    # CORE routing server lies here.
    routeserver = function serve(http)
        HTTP.setheader(http, "Content-Type" => "text/html")
        fullpath = http.message.target
        if contains(http.message.target, '?')
            fullpath = split(http.message.target, '?')[1]
        end
        if fullpath in keys(route_paths)
            if typeof(route_paths[fullpath]) == Function
                write(http, route_paths[fullpath](http))
            else
                route_paths[fullpath].f(http, server = server,
                logger = logger, routes = route_paths, servables = servables)
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
