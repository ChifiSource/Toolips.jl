#==
map
- identifiers
- get/post requests
- abstract routes
- connections
- routes
- route! (router / route to)
- extensions
- server templates
- exceptions
- CLI
- `start!`
- router generator
==#
string(r::Vector{UInt8}) = String(UInt8.(r))

abstract type Identifier end

mutable struct IP4 <: Identifier
    ip::String
    port::Int64
end

(:)(ip::String, port::Int64) = IP4(ip, port)

string(ip::IP4) = begin
    if ip.port == 0
        ip.ip
    else
        "$(ip.ip):$(ip.port)"
    end
end

"""
**Core**
### get(url::String) -> ::String
------------------
Quick binding for an HTTP GET request.
#### example
```
body = get("/")
    "hi"
```
"""
function get(url::String)
    r = HTTP.request("GET", url)
    string(r.body)::String
end

"""
**Core**
### post(url::String, body::String) -> ::String
------------------
Quick binding for an HTTP POST request.
#### example
```
response = post("/")
    "my response"
```
"""
function post(url::String, body::String)
    r = HTTP.request("POST", url, body = body)
    string(r.body)::String
end

# connections
"""

"""
abstract type AbstractConnection end


"""
#### abstract type AbstractRoute
Abstract Routes are what connect incoming connections to functions. A route must be 
dispatched to `route!(::AbstractConnection, ::AbstractRoute)`.
###### Consistencies
- path**::String**
- route!(c::AbstractConnection, **route::AbstractRoute**)
"""
abstract type AbstractRoute end

function in(t::String, v::Vector{<:AbstractRoute})
    found = findfirst(x -> x.path == t, v)
    if ~(isnothing(found))
        return(true)::Bool
    end
    false::Bool
end

string(c::Vector{<:AbstractRoute}) = join([begin
    r.path * "\n" 
end for r in c])

"""
```julia
Routes{T} (Type Alias for Vector{T} where T <:AbstractRoute)
```
---
`Routes` are simple one-dimensional vectors of routes. Using multiple dispatch, these 
vectors effectively become routers and can be extended using multiple dispatch. 
To change individual `Route` functionality, view `Route` and `MultiRoute`, dispatching `Routes{T <: Any}` 
to `route!(c::AbstractConnection, r::Routes{T <: Any})` will create a new router, which is intended to call 
`route!` on routes.
```example

```
"""
const Routes{T} = Vector{T} where T <: AbstractRoute

"""

"""
mutable struct Connection <: AbstractConnection
    stream::Any
    data::Dict{Symbol, Any}
    routes::Vector{AbstractRoute}
end

"""

"""
mutable struct SpoofConnection <: AbstractConnection
    stream::String
    SpoofConnection() = new("")::SpoofConnection
end
write!(c::SpoofConnection, args::Any ...) = c.stream = c.stream * write(c.stream, join([string(args) for args in args]))

write!(c::AbstractConnection, args::Any ...) = write(c.stream, join([string(args) for args in args]))

# args
function get_args(c::AbstractConnection)
    fullpath = split(c.stream.message.target, '?')
    if length(fullpath) > 1
        fullpath = split(fullpath[2], "&")
        return(Dict(begin 
            p = split(p, "=")
            Symbol(p[1]) => string(p[2]) 
        end for p in fullpath))::Dict{Symbol, String}
    end
    Dict{Symbol, String}()::Dict{Symbol, String}
end

function get_L(c::AbstractConnection)

end

function get_heading(c::AbstractConnection)

end

function get_ip(c::AbstractConnection)
    str = c.stream.message["User-Agent"]
    spl = split(str, "/")
    ipstr = ""
    [begin
        if contains(sub, ".")
            if length(findall(".", sub)) > 1
                ipstr = split(sub, " ")[1]
            end
        end
    end for sub in spl]
    return(ipstr)
end


get_post(c::AbstractConnection) = string(read(c.stream))

function download!(c::AbstractConnection, uri::String)
    write(c.stream, HTTP.Response(200, body = read(uri, String)))
end

function proxy_pass!(c::AbstractConnection, url::String)
    HTTP.get(url, response_stream = c.stream, status_exception = false)
end

startread!(c::AbstractConnection) = startread(c.stream)

function get_route(c::AbstractConnection)
    fullpath::String = c.stream.message.target
    fullpath = string(split(fullpath, '?')[1])
    fullpath
end

function get_method(c::AbstractConnection)
    string(c.stream.message["Method"])::String
end

function get_host(c::AbstractConnection)
    string(c.stream.message["Host"])::String
end

function get_parent(c::AbstractConnection)
    string(c.stream.message.parent)
end

function get_client_system(c::AbstractConnection)
    uri = c.stream.message["User-Agent"]
    mobile = false
    system = "Linux"
    if contains(uri, "Windows")
        system = "Windows"
    elseif contains(uri, "OSX")
        system = "OSX"
    elseif contains(uri, "Android")
        system = "Android"
        mobile = true
    elseif contains(uri, "IOS")
        system = "IOS"
        mobile = true
    end
    system, mobile
end

function respond!(c::AbstractConnection, code::Int64, body::String = "")
    write(c.stream, HTTP.Response(code, body = body))
end

"""
```julia
Route{T <: AbstractConnection} <: AbstractRoute
```
- path**::String**
- page**::Function**
---
The `Route` is the most basic form of `AbstractRoute`. This constructor should **not** be called directly, 
instead use `route("/") do c::Connection` (or) `route(::Function, ::String)` to create routes.
```julia
using Toolips

route("/") do c::AbstractConnection
    write!(c, "Hello world!")
end
````
"""
mutable struct Route{T <: AbstractConnection} <: AbstractRoute
    path::String
    page::Function
    function Route(path::String, f::Function)
        params = methods(f)[1].sig.parameters
        rtype::Type{<:AbstractConnection} = Connection
        if length(params) > 1
            if params[2] <: AbstractConnection
                rtype = params[2]
            end
        end
        new{rtype}(path, f)
    end
end

function show(io::IO, r::AbstractRoute)
    println(r.path)
end

abstract type AbstractMultiRoute <: AbstractRoute end

mutable struct MultiRoute{T <: AbstractRoute} <: AbstractMultiRoute
    path::String
    routes::Vector{T}
    function MultiRoute{T}(path::String, routes::Vector{<:Any}) where {T <: AbstractRoute}
        new{T}()

    end
    function MultiRoute(r::Route ...)
        new{Route}(r[1].path, [rout for rout in r])
    end
end

"""
"""
function route end


function convert(c::AbstractConnection, vec::Vector{<:AbstractRoute}, 
    c2::Type{<:AbstractConnection})
=======
function convert(c::AbstractConnection, c2::Type{<:AbstractConnection})
    false
end

route(f::Function, r::String) = begin
    Route(r, f)::Route{<:Any}
end

route(r::Route{<:AbstractConnection}...) = MultiRoute(r ...)
=======
route(r::Route ...) = begin
    
end


"""
"""
route!(c::AbstractConnection, r::AbstractRoute) = r.page(c)


function route!(c::Connection, tr::Routes{<:AbstractRoute})
    target::String = get_route(c)
    if target in tr
        selected::AbstractRoute = tr[target]
        if typeof(selected) <: AbstractMultiRoute
            multiroute!(c, tr, selected)
        else
            route!(c, selected)
        end
    elseif "404" in tr
        selected = tr["404"]
        if typeof(selected) <: AbstractMultiRoute
            multiroute!(c, tr, selected)
        else
            route!(c, selected)
        end
    else
        route!(c, default_404)
    end
end

function multiroute!(c::AbstractConnection, vec::Routes, r::AbstractMultiRoute)
    met = findfirst(r -> convert(c, vec, typeof(r).parameters[1]), r.routes)
function route!(c::Connection, tr::Vector{AbstractRoute})
    target::String = get_target(c)
    if target in tr
        route!(c, vec[target])
    else
        throw("Route not found!")
    end
end

function route!(c::AbstractConnection, r::AbstractMultiRoute)
    met = findfirst(r -> convert(c, typeof(r).parameters[1]), r.routes)
    if isnothing(met)
        default = findfirst(r -> typeof(r).parameters[1] == Connection, r.routes)
        if ~(isnothing(default))
            r.routes[default].page(c)
        else
            r.routes[1].page(c)
        end
        return
    end
    selected = r.routes[met]
    c = convert!(c, vec, typeof(selected).parameters[1])
    r.routes[met].page(c)
    end
    c.routes[met].page(c)
end


function getindex(vec::Vector{<:AbstractRoute}, path::String)
    rt = findfirst(r::AbstractRoute -> r.path == path, vec)
    if ~(isnothing(rt))
        selected::AbstractRoute = vec[rt]
        vec[rt]::AbstractRoute
    end
end

# extensions
abstract type AbstractExtension end
abstract type Extension{T <: Any} <: AbstractExtension end

function route!(c::AbstractConnection, e::AbstractExtension)
end

function on_start(ext::AbstractExtension, data::Dict{Symbol, Any}, routes::Vector{<:AbstractRoute})
end


"""
### abstract type ServerTemplate
ServerTemplates are returned whenever the ServerTemplate.start() field is
called. If you are running your server as a module, it should be noted that
commonly a global start() method is used and returns this server, and dev is
where this module is loaded, served, and revised.
##### Consistencies
- routes::Vector{AbstractRoute} - The server's routes.
- extensions::Vector{Route} - The server's currently loaded extensions.
- server::Any - The server, whatever type it may be...
"""
abstract type ServerTemplate end

mutable struct Server
    name::String
    host::IP4
    m::Module
end

abstract type WebServer <: ServerTemplate end

const Servers = Vector{Pair{<:ServerTemplate, Module}}

function kill!(ws::ServerTemplate)
    close(ws.server)
end

mutable struct StartError <: Exception

end

mutable struct RouteError <: Exception
    function showerror(io::IO, e::RouteError)
        print(io, "ERROR ON ROUTE: $(e.route) $(e.error)")
    end
end

showerror(io::IO, e::StartError) = print(io, "Toolips Core Error: $(e.message)")

function ip4_cli(ARGS)
    IP = "127.0.0.1"
    PORT = 8000
    if length(ARGS) > 0
        IP = ARGS[1]
    end
    if length(ARGS) > 1
        PORT = parse(Int64, ARGS[2])
    end
    IP:PORT
end

function server_cli(ARGS)
    SERVER = Main
    ip4::IP4 = ip4_cli(ARGS)
    if length(ARGS) == 3
        SERVER = SERVER.eval(ARGS[3])
    end
end

function start! end

function start!(mod::Module = server_cli(Main.ARGS), from::Type{<:ServerTemplate} = WebServer; ip::IP4 = ip4_cli(Main.ARGS), 
    router_threads::Int64 = 1, threads::Int64 = 1)
    IP = Sockets.InetAddr(parse(IPAddr, ip.ip), ip.port)
    server::Sockets.TCPServer = Sockets.listen(IP)
    mod.server = server
    routefunc::Function, pm::ProcessManager = generate_router(mod, router_threads)
    if router_threads == 1
        w = pm["$mod router"]
        serve_router = @async HTTP.listen(routefunc, ip.ip, ip.port, server = server)
        w.task = serve_router
        w.active = true
        return(pm)::ProcessManager
    end
end

function generate_router(mod::Module, n_threads::Int64)
    # Load Extensions, routes, and data.
    server_ns::Vector{Symbol} = names(mod)
    fieldgen = [begin
        f = getfield(mod, x) 
        typeof(f) => f 
    end for x in server_ns]
    onlydata = filter(t -> ~(t[1] <: AbstractExtension || t[1] == Function || t[1] <: AbstractRoute), values(fieldgen))
    loaded = [t[2] for t in filter(t -> t[1] <: AbstractExtension, values(fieldgen))]
    logger_check = findfirst(t -> typeof(t) == Logger, loaded)
    if isnothing(logger_check)
        push!(loaded, Logger())
    end
    routes = mod[AbstractRoute]
    if typeof(routes) <: Vector{Route{<:Any}}
        routes = Vector{AbstractRoute}(routes)
    end
    data = Dict{Symbol, Any}(Symbol(n) => getfield(mod, n) for n in server_ns)
    [on_start(ext, data, routes) for ext in loaded]
    allparams = (m.sig.parameters[3] for m in methods(route!, Any[AbstractConnection, AbstractExtension]))
    filter!(ext -> typeof(ext) in allparams, loaded)
    # process manager Routing func (async)
    if n_threads == 1
        w = Worker{Async}("$mod router", rand(1000:3000))
        pman = ProcessManager(w)
        push!(data, :procs => pman)
        mod.procman = pman
        c::AbstractConnection = Connection(nothing, data, routes)
        routeserver(http::HTTP.Stream) = begin
            c.stream = http
            [route!(c, ext) for ext in loaded]
            route!(c, c.routes)::Any
            c.stream = nothing
        end
        return(routeserver, pman)
    end
    # process manager Routing func (multi-thread)
    pman = processes(n_threads)
    mod.processes = pman
    routeserver = function serve_multi(http::HTTP.Stream)
        c = Connection(http, data, routes)
        jobs = vcat([new_job(route!, c, ext) for ext in loaded])
        distribute!(pman, workerids, jobs ...)
        assign_open!(pman, workerids, route!, c, routes)
    end
    return(routeserver, pman)
end

display(ts::ServerTemplate) = show(ts)

