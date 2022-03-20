mutable struct Route
    path::String
    page::Any
    function Route(path::String = "", page::Any = "")
        new(path, page)
    end
end

mutable struct ServerTemplate
    ip::String
    port::Integer
    routes::AbstractVector
    remove::Function
    add::Function
    start::Function
    function ServerTemplate(ip::String, port::Int64,
        routes::AbstractVector = [])
        add, remove, start = funcdefs(routes, ip, port)
        new(ip, port, routes, remove, add, start)
    end

    function ServerTemplate()
        port = 8001
        ip = "127.0.0.1"
        ServerTemplate(ip, port)
    end
end

function funcdefs(routes::AbstractVector, ip::String, port::Integer)
    add(r::Route) = push!(routes, r)
    remove(i::Int64) = deleteat!(routes, i)
    start() = _start(routes, ip, port)
    return(add, remove, start)
end

function _start(routes::AbstractVector, ip::String, port::Integer)
    server = Sockets.listen(Sockets.InetAddr(parse(IPAddr, ip), port))
    # TODO Logging
    println("Starting server on port ", string(port))
    routefunc = generate_router(routes, server)
    @async HTTP.listen(routefunc, ip, port; server = server)
    println("Successfully started Toolips server on port ", port, "\n")
    println("You may visit it now at http://" * string(ip) * ":" * string(port))
    return(server)
end

function _start(routes::AbstractVector, ip::String, port::Integer)
    server = Sockets.listen(Sockets.InetAddr(parse(IPAddr, ip), port))
    println("Starting server on port ", string(port))
    routefunc = generate_router(routes, server)
    @async HTTP.listen(routefunc, ip, port; server = server)
    println("Successfully started server on port ", port, "\n")
    println("You may visit it now at http://" * string(ip) * ":" * string(port))
    return(server)
end
function generate_router(routes::AbstractVector, server)
    route_paths = Dict([route.path => route.page for route in routes])
    # CORE routing server lies here.
    routeserver = function serve(http)
    HTTP.setheader(http, "Content-Type" => "text/html")
    fullpath = http.message.target
    # Checks for argument data, because this is not in the route.
    if contains(http.message.target, '?')
         fullpath = split(http.message.target, '?')[1]
    end

     if fullpath in keys(route_paths)
        write(http, route_paths[fullpath].f(http))
     else
         write(http, route_paths["404"].f(http))
     end

 end # serve()
    return(routeserver)
end
function stop!(x::Any)
    close(x)
end
