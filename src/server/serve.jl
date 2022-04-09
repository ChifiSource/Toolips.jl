include("log.jl")
mutable struct Route{T}
    path::String
    page::T
    function Route(path::String = "", page::Function = http -> "")
        new{Function}(path, page)
    end
    function Route(path::String, page::Page)
        new{Page}(path, page)
    end
    function Route(path::String, page::FormComponent)
        new{FormComponent}(path, page)
    end
    function Route(path::String, page::Component)
        new{typeof(page)}(path, page)
    end
end

function route_from_dir(dir::String)
    dirs = readdir(dir)
    routes::Vector{String} = []
    for directory in dirs
        if isfile("$dir/" * directory)
            push!(routes, "$dir/$directory")
        else
            if ~(directory in routes)
                newread = dir * "/$directory"
                newrs = route_from_dir(newread)
                [push!(routes, r) for r in newrs]
            end
        end
    end
    rts::Vector{Route} = []
    for directory in routes
        if isfile("$dir/" * directory)
            push!(rts, Route("$directory", file("$dir/" * directory)))
        end
    end
    rts
end

mutable struct ServerTemplate
    ip::String
    port::Integer
    routes::Vector{Route}
    logger::Logger
    remove::Function
    add::Function
    start::Function
    public::String
    function ServerTemplate(ip::String, port::Int64,
        routes::Vector{Route} = []; logger::Logger = Logger(),
        public::String = "public")
        add, remove, start = funcdefs(routes, ip, port, logger, public)
        new(ip, port, routes, logger, remove, add, start, public)
    end

    function ServerTemplate(;logger::Logger = Logger(), public::String = "public")
        port = 8001
        ip = "127.0.0.1"
        ServerTemplate(ip, port, []; logger = logger, public = public)
    end
    function ServerTemplate(ip::String, port::Integer;
        logger::Logger = Logger(), public::String = "public")
        ServerTemplate(ip, port, []; logger = logger, public = public)
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
    merge!(routes, public_rs)
    server = Sockets.listen(Sockets.InetAddr(parse(IPAddr, ip), port))
    logger.log(1, "Toolips Server starting on port " * string(port))
    routefunc = generate_router(routes, server, logger)
    @async HTTP.listen(routefunc, ip, port; server = server)
    logger.log(2, "Successfully started server on port " * string(port))
    logger.log(1,
    "You may visit it now at http://" * string(ip) * ":" * string(port))
    return(server)
end
function generate_router(routes::AbstractVector, server, logger::Logger)
    route_paths = Dict([route.path => route.page for route in routes])
    # CORE routing server lies here.
    # - Router itself is merely a function that gets called with the http
    #  stream. This trickles down the line all the way to the interface methods.
    routeserver = function serve(http)
    HTTP.setheader(http, "Content-Type" => "text/html")
    fullpath = http.message.target
    # Checks for argument data, because this is not in the route.
    if contains(http.message.target, '?')
         fullpath = split(http.message.target, '?')[1]
    end

     if fullpath in keys(route_paths)
         if typeof(route_paths[fullpath]) == Function
             write(http, route_paths[fullpath](http))
         else
             write(http, route_paths[fullpath].f(http))
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
