using Sockets
using HTTP
abstract type RoseBudServer end
mutable struct Route <: Component
    req_type::String
    req_dir::String
    components::Page
    response::Function
    function Route(type::String, dir::String, components::Page ...)
        response() = [render(component) for component in components]
        new(req_type, dir, componentes, response)
    end
end
macro route(dir::String, components::Page) Route(Page.type, dir, components) end

mutable struct RoseBud <: RoseBudServer
    ip::String
    port::Int64
    router::HTTP.Router
    routes::Vector{Route}
    run::Function
    add::Function
    function RoseBud()
        router = HTTP.Router()
        routes = []
        ip = "127.0.0.1"
        port = 8000
        run() = _run(ip, port, routes, router)
        add(route::Route) = _add(route)
        new(ip, port, run, add)
    end
    function RoseBud(ip::String, port::Int64)
        router = HTTP.Router()
        routes = []
        run() = _run(ip, port, routes, router)
        add(route::Route) = _add(route, routes)
        new(ip, port, run, add)
    end

end

function _run(ip::String, port::Int64, routes::Vector{Route}, ROUTER::HTTP.Router)
    for route in routes
        HTTP.@register(ROUTER, route.req_type, route.req_dir, route.response())
    end
    HTTP.serve(ROUTER, ip, port)
end

function _add(route::Route, routes::Vector{Route})
    push!(routes, route)
end
# response example: (anonymous function)
# req->HTTP.Response(200, "Bye!")
