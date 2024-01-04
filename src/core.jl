"""
### abstract type AbstractRoute
Abstract Routes are what connect incoming connections to functions. Each route
must have two fields, `path`, and `page`. Path needs to be a String, but that is
about it.
##### Consistencies
- type::T where T == Vector{Symbol}  || T == Symbol
"""
abstract type AbstractRoute end

function show(io::IO, r::AbstractRoute)
    print(io, "route: $(r.path) -> $(r.page)\n")
end

"""
### Route
- path**::String**  - The path to route to the function, e.g. "/".
- page**::Function** - The function to route the path to.\n
A route is added to a ToolipsServer using either its constructor, or the
ToolipsServer.add(**::Route**) method. Each route calls a function.
The Route type is commonly constructed using the do syntax with the
route(**::Function**, **::String**) method.
##### example
```
# Constructors
route = Route("/", p(text = "hello"))

function example(c::Connection)
    write!(c, "hello")
end

route = Route("/", example)

# method
route = route("/") do c
    write!(c, "Hello world!")
    write!(c, p(text = "hello"))
    # we can also use extensions!
    c[:logger].log("hello world!")
end
```
------------------
##### constructors
- Route(path**::String**, f**::Function**)
"""
mutable struct Route <: AbstractRoute
    path::String
    page::Function
    function Route(path::String, f::Function)
        new(path, f)
    end
end

route(f::Function, r::String) = Route(r, f)::Route

function getindex(vec::Vector{<:AbstractRoute}, path::String)
    rt = findfirst(r::AbstractRoute -> r.path == path, vec)
    if ~(isnothing(rt))
        vec[rt]::AbstractRoute
    end
end
# extensions
abstract type Extension{T <: Any} end

"""
### abstract type Modifier <: Servable
Modifiers are used to interpret and respond to incoming data. The prime example
for this is the **ComponentModifier**. This is used to bring Components into a
    readable form and then change different Component properties.
##### Consistencies
- **Servable** Is bound to `Toolips.write!` in one form or another, and works
in `Vector{Servable}`s.
"""
abstract type Modifier <: Servable end

# connections
"""
### abstract type AbstractConnection
Connections are passed through function routes and can have Servables written
    to it.
##### Consistencies
- stream
"""
abstract type AbstractConnection end

"""

"""
mutable struct Connection <: AbstractConnection
    hostname::String
    stream::HTTP.Stream
    data::Dict{Symbol, Dict{String, Any}}
    routes::Vector{AbstractRoute}
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

# args
function getargs(c::AbstractConnection)
    target = split(c.stream.message.target, '?')
    if length(target) < 2
        return(Dict{Symbol, Any}())
    end
    target = replace(target[2], "+" => " ")
    args = split(target, '&')
    argsplit(args)
end

function getip(c::AbstractConnection)
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

function proxy!(f::Function, c::AbstractConnection, url::String)
    try
        HTTP.get(url, response_stream = c.stream, status_exception = false)
    catch
        f(c)
    end
end

"""
**Interface**
### push!(c::AbstractConnection, data::Any) -> _
------------------
A "catch-all" for pushing data to a stream. Produces a full response with
**data** as the body.
#### example
```

```
"""
push!(c::AbstractConnection, data::Any) = write!(c.stream, HTTP.Response(200, body = string(data)))

startread!(c::AbstractConnection) = startread(c.stream)

string(r::Vector{UInt8}) = String(UInt8.(r))

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

function start!(mod::Module = Main, ip::String = "127.0.0.1", port::Int64 = 8000, ws::Type{<:ToolipsServer} = WebServer; hostname::String = ip, 
    mode::StartMode{<:Any} = StartMode{:async}())
    server::Sockets.TCPServer = Sockets.listen(Sockets.InetAddr(
    parse(IPAddr, ip), port))
    mod.server = 
    routefunc::Function = generate_router(mod, hostname)
    if mode == StartMode{:async}()
        try
            @async HTTP.listen(routefunc, ip, port, server = server)
        catch e
            throw(CoreError("Could not start Server $ip:$port\n $(string(e))"))
        end
        return
    end
    try
        @async HTTP.listen(routefunc, ip, port, server = server)
    catch e
        throw(CoreError("Could not start Server $ip:$port\n $(string(e))"))
    end
end

function respond!(c::AbstractConnection, code::Int64, body::String = "")
    write(c.stream, HTTP.Response(code, body = "hello world"))
end

function generate_router(mod::Module, hostname::String)
    # Load Extensions
    data::Dict{Symbol, Dict{Symbol, Any}} = Dict{Symbol, Any}()
    routes::Vector{<:AbstractRoute} = mod[AbstractRoute]
    loaded::Vector{Type} = Vector{Type}()
    if :load! in names(mod)
        [begin
            extname = ext_m.sig.parameters[2]
            if ~(extname == Extension{<:Any})
                on_start(extname(), routes, data)
                push!(loaded, extname)
            end
        end for ext_m in methods(getfield(mod, :load!))]
    end
    mod.data, mod.routes = data, routes
    # Routing func
    routeserver::Function = function serve(http::HTTP.Stream)
        fullpath::String = http.message.target
        c::Any = Connection(hostname, http, data, routes)
        if contains(fullpath, "?")
            fullpath = string(split(fullpath, '?')[1])
        end
        if fullpath in routes
            [route!(c, ext) for ext in loaded]
            routes[fullpath].page(c)
        else
            if "404" in routes
                routes["404"].page(c)
            end
            respond!(c, 404)
        end
        c = nothing
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
