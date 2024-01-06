string(r::Vector{UInt8}) = String(UInt8.(r))

mutable struct IP4
    ip::String
    port::Int64
end

(:)(ip::String, port::Int64) = IP4(ip, port)

"""

"""
abstract type Modifier <: Servable end

# connections
"""

"""
abstract type AbstractConnection end

abstract type AbstractClient end

"""
#### abstract type AbstractRoute
Abstract Routes are what connect incoming connections to functions. A route must be 
dispatched to `route!(::AbstractConnection, ::AbstractRoute)`.
###### Consistencies
- path**::String**
- route!(c::AbstractConnection, **route::AbstractRoute**)
"""
abstract type AbstractRoute end
"""

"""
mutable struct Connection <: AbstractConnection
    stream::HTTP.Stream
    data::Dict{Symbol, Any}
    routes::Vector{AbstractRoute}
end

mutable struct MobileConnection <: AbstractConnection

end

function convert!(c::Connection, into::MobileConnection)

end

"""

"""
mutable struct SpoofConnection <: AbstractConnection
    stream::String
    SpoofConnection() = new("")::SpoofConnection
end

function write! end

write!(c::AbstractConnection, args::Any ...) = write(c.stream, join([string(args) for args in args]))

write!(c::SpoofConnection, args::Any ...) = c.stream = c.stream * write(c.stream, join([string(args) for args in args]))

function show(io::IO, r::AbstractRoute)
    println(r.path)
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

"""
"""
route!(c::AbstractConnection, r::AbstractRoute) = r.page(c)

"""
"""
function route end

route(f::Function, r::String) = begin
    Route(r, f)::Route{<:Any}
end

function getindex(vec::Vector{<:AbstractRoute}, path::String)
    rt = findfirst(r::AbstractRoute -> r.path == path, vec)
    if ~(isnothing(rt))
        vec[rt]::AbstractRoute
    end
end

function route!(c::Connection, r::Vector{<:AbstractRoute})
    path::String = get_route(c)
    if path in r
        route!(c, r[path])
    else
        if "404" in r
            routes["404"].page(c)
        else
            respond!(c, 404)
        end
    end
end

# args
function get_args(c::AbstractConnection)
    HTTP.URIs.query_params(c.http)
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

# extensions
abstract type AbstractExtension end
abstract type Extension{T <: Any} <: AbstractExtension end

function route!(c::AbstractConnection, e::AbstractExtension)
end

function on_start(mod::Module, e::AbstractExtension)
end

function get_args(mod::Module; keyargs ...)

end

"""
### abstract type ToolipsServer
ToolipsServers are returned whenever the ServerTemplate.start() field is
called. If you are running your server as a module, it should be noted that
commonly a global start() method is used and returns this server, and dev is
where this module is loaded, served, and revised.
##### Consistencies
- routes::Vector{AbstractRoute} - The server's routes.
- extensions::Vector{Route} - The server's currently loaded extensions.
- server::Any - The server, whatever type it may be...
"""
abstract type ToolipsServer end

abstract type WebServer <: ToolipsServer end

function kill!(ws::ToolipsServer)
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

mutable struct StartMode{T <: Any} end

function get_route(c::AbstractConnection)
    fullpath::String = c.stream.message.target
    fullpath = string(split(fullpath, '?')[1])
    fullpath
end

function get_method(c::AbstractConnection)
    
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

function start!(mod::Module = server_cli(Main.ARGS), ip4::IP4 = ip4_cli(Main.ARGS), ws::Type{<:ToolipsServer} = WebServer; mode::StartMode{<:Any} = StartMode{:async}())
    IP = Sockets.InetAddr(parse(IPAddr, ip4.ip), ip4.port)
    server::Sockets.TCPServer = Sockets.listen(IP)
    mod.server = server
    routefunc::Function = generate_router(mod)
    if mode == StartMode{:async}()
        try
            @async HTTP.listen(routefunc, ip4.ip, ip4.port, server = server)
        catch e
            throw(CoreError("Could not start Server $ip:$port\n $(string(e))"))
        end
        return
    end
    try
        @async HTTP.listen(routefunc, ip4.ip, ip4.port, server = server)
    catch e
        throw(CoreError("Could not start Server $ip:$port\n $(string(e))"))
    end
end

function respond!(c::AbstractConnection, code::Int64, body::String = "")
    write(c.stream, HTTP.Response(code, body = body))
end

function generate_router(mod::Module)
    # Load Extensions
    server_ns::Vector{Symbol} = names(mod)
    fieldgen = [begin
        f = getfield(mod, x) 
        typeof(f) => f 
    end for x in server_ns]
    onlydata = filter(t -> ~(t[1] <: AbstractExtension || t[1] == Function || t[1] <: AbstractRoute), values(fieldgen))
    loaded = [t[2] for t in filter(t -> t[1] <: AbstractExtension, values(fieldgen))]
    [on_start(mod, ext) for ext in loaded]
    routes = mod[AbstractRoute]
    mod.data, mod.routes = Dict{Symbol, Any}(Symbol(n) => getfield(mod, n) for n in server_ns), routes
    # Routing func
    routeserver::Function = function serve(http::HTTP.Stream)
        c::AbstractConnection = Connection(http, mod.data, mod.routes)
        [route!(c, ext) for ext in loaded]
        route!(c, routes)::Any
    end
    routeserver::Function
end

function in(t::String, v::Vector{<:AbstractRoute})
    found = findfirst(x -> x.path == t, v)
    if ~(isnothing(found))
        return(true)::Bool
    end
    false::Bool
end

function show(io::IO, ts::ToolipsServer)
    status::String = string(ts.server.status)
    print("""$(typeof(ts))
        hosted at: http://$(ts.host):$(ts.port)
        status: $status
        routes
        $(string(ts.routes))
        """)
end

string(c::Vector{<:AbstractRoute}) = join([begin
    r.path * "\n" 
end for r in c])

display(ts::ToolipsServer) = show(ts)
#==
Requests
==#
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
    string(r.body)
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
    string(r.body)
end
