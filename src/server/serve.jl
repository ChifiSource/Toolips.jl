import Base: display
function display(d::Any, m::Any, app)
    println(d, "outer html")
    # Calling show will make sure a server is running and serves dependencies
    # from AssetRegistry and a websocket connection gets established.
    show(d, string(m), app) #<- prints the html + scripts webio needs to work into io
    println(d, "close outer html")
end

mutable struct Route
    path::String
    page::Page
    function Route(path::String, page::Page)

    end
end

mutable struct ToolipServer
    ip::String
    port::Integer
    routes::AbstractVector
    remove::Function
    add::Function
    start::Function
    function ToolipServer(ip::String, port::Int64)
        routes = []
        add, remove, start = funcdefs(routes, ip, port)
        new(ip, port, routes, remove, add, start)
    end

    function ToolipServer()
        port = 8001
        ip = "127.0.0.1"
        ToolipServer(ip, port)
    end
end

function funcdefs(routes::AbstractVector, ip::String, port::Integer)
    add(r::Route) = push!(routes, r)
    remove(i::Int64) = deleteat!(routes, i)
    start() = _start(routes, ip, port)
    return(add, remove, start)
end

function _start(routes::AbstractVector, ip::String, port::Integer)
    server = WebIO.listen(Sockets.InetAddr(parse(IPAddr, ip), port))
    println("Starting server on port ", string(port))
    routefunc = generate_router(routes, server)
    @async HTTP.listen(routefunc, ip, port; server = server)
    println("Successfully started Toolips server on port ", port, "\n")
    println("You may visit it now at http://" * string(ip) * ":" * string(port))
    return(server)
end

function generate_router(routes::AbstractVector, server)
    z = 5
    ui = button()
    m = WebIO.WEBIO_APPLICATION_MIME()
    routeserver = function serve(http)
     HTTP.setheader(http, "Content-Type" => "text/html")
     write(http, "target uri: $(http.message.target)<BR>")
     write(http, "request body:<BR><PRE>")
     write(http, read(http))
     write(http, "</PRE>")
     HTTP.setheader(http, "Content-Type" => string(m))
     accept(server) do webio
         show(webio, string(ui))
     end
    end
    return(routeserver)
end
function stop!(x::Any)
    close(x)
end
#== Closing server will stop HTTP.listen.
close(server)
HTTP.listen("127.0.0.1", 8081) do http
           HTTP.setheader(http, "Content-Type" => "text/html")
           write(http, "target uri: $(http.message.target)<BR>")
           write(http, "request body:<BR><PRE>")
           write(http, read(http))
           write(http, "</PRE>")
           write(http, "<h1>HELLO!</h1>")
           return
           end
==#
