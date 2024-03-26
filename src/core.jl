#==
map
- identifiers
- get/post requests
- abstract routes
- connections
- parallel computing
- routes
- route! (router / route to)
- extensions
- server templates
- exceptions
- CLI
- `start!`
- router
==#
string(r::Vector{UInt8}) = String(UInt8.(r))

"""
```julia
abstract type Identifier
```
An `Identifier` is a structure that represents a client, a client's data, 
or the server itself.
- All servables have a `name`.
- All servables are dispatched to `string`.
- `Servables` (?Servables) can be indexed using a `String` corresponding to `name`.
---
- See also: `IP4`, `start!`, `Toolips`
"""
abstract type Identifier end

"""
```julia
struct IP4 <: Identifier
```
- `ip`**::String**
- `port`**::Int64**

An `IPv4` is the " fourth" iteration of the internet protocol, which assigns 
IP addresses to computers via an Internet Service Provider (ISP) and DHCP (a router server.) 
`Toolips` IPs are written just how they are seen other than the address being a `String`.

```example
host = "127.0.0.1":8000
```
```julia
IP4(ip::String, port::Int64)
```
- See also: `templating`, `StyleComponent`, `AbstractComponent`, `elements`, `arguments`
"""
struct IP4 <: Identifier
    ip::String
    port::Int64
end

function gen_ref(n::Int64 = 16)
    sampler::String = "iokrtshgjiosjbisjgiretwshgjbrthrthjtyjtykjkbnvjasdpxijvjr"
    samps = (rand(1:length(sampler)) for i in 1:n)
    join(sampler[samp] for samp in samps)
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
```julia
get(url::String) -> ::String
get(url::IP4) -> ::String
```
Performs a `GET` request from Julia.
---
```example
response = Toolips.get("https://github.com/ChifiSource")
```
"""
function get(url::String)
    r = HTTP.request("GET", url)
    string(r.body)::String
end

get(url::IP4) = get("http://$(url.ip):$(url.port)")

"""
```julia
post(url::String, body::String) -> ::String
post(url::IP4, body::String) -> ::String
```
Performs a `POST` request from Julia.
---
```example
module Server
using Toolips
logger = Toolips.Logger()

home = route("/") do c::Connection
    name = get_post(c)
    log(logger, "$name just posted")
    write!(c, "hello, $name")
end
export home, logger
end

using Toolips
start!(Server); println(Toolips.post("127.0.0.1":8000, "emmy"))
```
"""
function post(url::String, body::String)
    r = HTTP.request("POST", url, body = body)
    string(r.body)::String
end

post(url::IP4, body::String) = post("http://$(url.ip):$(url.port)", body)

# connections
"""
```julia
abstract type AbstractConnection
```
An `AbstractConnection` is how a server interacts with each client on an individual basis. 
Variations of the `Connection` are passed to routes as their only argument. The `Connection`
- Can be written to with `write!`
- Contains client data accessible with *getter* functions, such as `get_ip`.
---
- See also: `start!`, `route`, `route!`, `Connection`, `get_ip`, `get_args`
"""
abstract type AbstractConnection end

"""
```julia
abstract type AbstractRoute
```
An `AbstractRoute` holds a `path`, a target which navigates the user throughout the webpage, 
as well as some way to generate that page. Typically, these are created using `route`, though this 
might not always be the case. The canonical route provided by `Toolips` is `Route{<:Any}`.
---
- See also: `route`, `route!`, `Connection`, `AbstractConnection`
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

getindex(c::AbstractConnection, symb::Symbol) = c.data[symb]

getindex(c::AbstractConnection, symb::String) = c.routes[symb]


setindex!(c::AbstractConnection, a::Any, symb::Symbol) = c.data[symb] = a

setindex!(c::AbstractConnection, f::Function, symb::String) = begin
    push!(c.routes, route(f, symb))
end

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

distribute!(c::AbstractConnection, args ...; keyargs ...) = distribute!(c[:procs], args ...; keyargs ...)

assign!(c::AbstractConnection, args ...; keyargs ...) = assign!(c[:procs], args ...; keyargs ...)

assign_open!(c::AbstractConnection, args ...; keyargs ...) = assign!(c[:procs], args ...; keyargs ...)

distribute_open!(c::AbstractConnection, args ...; keyargs ...) = distribute_open!(c[:procs], args ...; keyargs ...)

waitfor(c::AbstractConnection, args ...; keyargs ...) = waitfor(c[:procs], args ...; keyargs ...)

put!(c::AbstractConnection, args ...; keyargs ...) = distribute!(c[:procs], args ...; keyargs ...)

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
    false
end

route(f::Function, r::String) = begin
    Route(r, f)::Route{<:Any}
end

route(r::Route{<:AbstractConnection}...) = MultiRoute(r ...)

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

"""
abstract type ServerTemplate end

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
    threads::Int64 = 1)
    IP = Sockets.InetAddr(parse(IPAddr, ip.ip), ip.port)
    server::Sockets.TCPServer = Sockets.listen(IP)
    mod.server = server
    routefunc::Function, pm::ProcessManager = generate_router(mod, ip)
    w = pm["$mod router"]
    serve_router = @async HTTP.listen(routefunc, ip.ip, ip.port, server = server)
    w.task = serve_router
    w.active = true
    if threads > 1
        add_workers!(pm, threads)
    end
    pm::ProcessManager
end

function generate_router(mod::Module, ip::IP4)
    # Load Extensions, routes, and data.
    server_ns::Vector{Symbol} = names(mod)
    mod.routes = []
    loaded = []
    for name in server_ns
        f = getfield(mod, name)
        T = typeof(f)
        if T <: AbstractExtension
            push!(loaded, f)
        elseif T <: AbstractRoute
            push!(mod.routes, f)
        elseif T <: AbstractVector{<:AbstractRoute}
            mod.routes = vcat(mod.routes, f)
        end
    end
    mod.routes = Vector{AbstractRoute}([mod.routes ...])
    logger_check = findfirst(t -> typeof(t) == Logger, loaded)
    if isnothing(logger_check)
        push!(loaded, Logger())
        logger_check = length(loaded)
    end
    log(loaded[logger_check], "server listening at http://$(string(ip))")
    data = Dict{Symbol, Any}()
    [on_start(ext, data, mod.routes) for ext in loaded]
    allparams = (m.sig.parameters[3] for m in methods(route!, Any[AbstractConnection, AbstractExtension]))
    filter!(ext -> typeof(ext) in allparams, loaded)
    # process manager Routing func (async)
    w::Worker{Async} = Worker{Async}("$mod router", rand(1000:3000))
    pman::ProcessManager = ProcessManager(w)
    push!(data, :procs => pman)
    garbage::Int64 = 0
    GC.gc(true)
    routeserver(http::HTTP.Stream) = begin
        c::AbstractConnection = Connection(http, data, mod.routes)
        [route!(c, ext) for ext in loaded]
        route!(c, c.routes)::Any
        mod.routes = c.routes
        garbage += 1
        if garbage == 7
            GC.gc()
        elseif garbage == 15
            GC.gc()
        elseif garbage == 15
            GC.gc()
            garbage = 0
        elseif garbage == 30
            GC.gc(true)
            garbage = 0
        end
    end
    return(routeserver, pman)
end

display(ts::ServerTemplate) = show(ts)

