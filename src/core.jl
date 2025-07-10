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
- `port`**::UInt16**

An `IPv4` is the " fourth" iteration of the internet protocol, which assigns 
IP addresses to computers via an Internet Service Provider (ISP) and DHCP (a router server.) 
`Toolips` IPs are written just how they are seen other than the address being a `String`.

```example
host = "127.0.0.1":8000
```
```julia
IP4(ip::Abstractstring, port::Integer)
```
- See also: `start!`, `Toolips`, `route`, `route!`
"""
struct IP4 <: Identifier
    ip::String
    port::UInt16
    IP4(ip::AbstractString, port::Integer = 80) = begin
        if port < 0 || port > 0xFFFF
            throw(ArgumentError("Port number must be in the range 0–65535."))
        end
        new(string(ip), UInt16(port))::IP4
    end
end

(:)(ip::AbstractString, port::Integer) = IP4(ip, port)

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
---
Performs a `POST` request from Julia.
```example
module Server
using Toolips
logger = Toolips.Logger()

home = route("/") do c::Connection
    name = get_post(c)
    log(logger, "\$name just posted")
    write!(c, "hello, \$name")
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

in(c::AbstractConnection, symb::Symbol) = return(symb in keys(c.data))::Bool

string(c::Vector{<:AbstractRoute}) = join((begin
    r.path * "\n" 
end for r in c))

getindex(c::AbstractConnection, symb::Symbol) = begin
    if ~(symb in keys(c.data))
        throw(KeyError(symb))
    end
    c.data[symb]
end

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
- See also: `AbstractConnection`, `Route`, `route`, `route!`
"""
const Routes{T} = Vector{T} where T <: AbstractRoute

distribute!(c::AbstractConnection, args ...; keyargs ...) = distribute!(c[:procs], args ...; keyargs ...)

assign!(c::AbstractConnection, args ...; keyargs ...) = assign!(c[:procs], args ...; keyargs ...)

assign_open!(c::AbstractConnection, args ...; keyargs ...) = assign!(c[:procs], args ...; keyargs ...)

distribute_open!(c::AbstractConnection, args ...; keyargs ...) = distribute_open!(c[:procs], args ...; keyargs ...)

waitfor(c::AbstractConnection, args ...; keyargs ...) = waitfor(c[:procs], args ...; keyargs ...)

put!(c::AbstractConnection, args ...; keyargs ...) = distribute!(c[:procs], args ...; keyargs ...)

"""
```julia
Connection <: AbstractConnection
```
- `stream`**::HTTP.Stream**
- `data`**::Dict{Symbol, Any}**
- `routes`**::Vector{<:AbstractRoute}**

The `Connection` is the main type a `Toolips` server uses to serve an incoming 
HTTP request. Indexing the `Connection` yields routes or server data when a `String` or 
`Symbol` is used. A `Connection` can also be written to with `write!`. Arguments, and 
other client information can be retrieved with the various *get* functions for an `AbstractConnection`.
```julia
get_args(c::AbstractConnection)
get_ip(c::AbstractConnection)
get_post(c::AbstractConnection)
get_route(c::AbstractConnection)
get_method(c::AbstractConnection)
get_parent(c::AbstractConnection)
get_client_system(c::AbstractConnection)
```
```julia
proxy_pass!(c::Connection, url::String)
```
###### example
A `Connection` is provided directly to your route's handler `Function` as its only argument. 
When we create a `Route` with `route`, we will be passed a `Connection` which we can 
then use with `write!` to respond.
```example
module SampleServer
using Toolips
        # annotating gives multiple dispatch to routes (recommended)
home = route("/") do c::Connection
    write!(c, "hello world!")
end

export home, start!
end
```
`Servables` are also binded to `write!`, so a `Connection` can easily serve `Components`.
- See also: `route`, `AbstractConnection`, `route!`, `write!`, `Components`, `IOConnection`, `MobileConnection`
"""
mutable struct Connection <: AbstractConnection
    stream::HTTP.Stream
    data::Dict{Symbol, Any}
    routes::Vector{<:AbstractRoute}
    ip::String
end

write!(c::AbstractConnection, args::Any ...) = write(c.stream, join([string(args) for args in args]))

in(t::Symbol, v::AbstractConnection) = t in keys(v.data)

in(t::String, v::AbstractConnection) = t in v.routes

abstract type AbstractIOConnection <: AbstractConnection end

"""
```julia
IOConnection <: AbstractIOConnection
```
- `stream`**::String**
- `args`**::Dict{Symbol, String}**
- `ip`**::String**
- `post`**::String**
- `route`**::String**
- `method`**::String**
- `data`**::Dict{Symbol, Any}**
- `routes`**::Vector{<:AbstractRoute}**
- `system`**::String**


###### example
A `Connection` is provided directly to your route's handler `Function` as its only argument. 
When we create a `Route` with `route`, we will be passed a `Connection` which we can 
then use with `write!` to respond.
```example
module SampleServer
using Toolips
        # annotating gives multiple dispatch to routes (recommended)
home = route("/") do c::Connection
    write!(c, "hello world!")
end

export home, start!
end
```
`Servables` are also binded to `write!`, so a `Connection` can easily serve `Components`.
- See also: `Connection`, `route`, `AbstractConnection`, `route!`, `write!`, `start!`, `Components`
"""
mutable struct IOConnection <: AbstractIOConnection
    stream::String
    args::Dict{Symbol, String}
    ip::String
    post::String
    route::String
    method::String
    data::Dict{Symbol, Any}
    routes::Vector{<:AbstractRoute}
    system::String
    host::String
    IOConnection(http::HTTP.Stream, data::Dict{Symbol, <:Any}, routes::Vector{<:AbstractRoute}) = begin
        host::String = string(Sockets.getpeername(http)[1])
        uri::String = http.message["User-Agent"]
        system::String = "Linux"
        if contains(uri, "Windows")
            system = "Windows"
        elseif contains(uri, "OSX")
            system = "OSX"
        elseif contains(uri, "Android")
            system = "Android"
        elseif contains(uri, "IOS")
            system = "IOS"
        end
        args = Dict{Symbol, String}()::Dict{Symbol, String}
        fullpath::Vector{SubString} = split(http.message.target, '?')
        if length(fullpath) > 1
            fullpath = split(fullpath[2], "&")
            args = Dict(begin 
                p = split(p, "=")
                Symbol(p[1]) => string(p[2]) 
            end for p in fullpath)::Dict{Symbol, String}
        end
        new("", args, host, string(read(http)), string(split(http.message.target, '?')[1]), 
        string(http.message.method), data, routes, system, string(http.message["Host"]))::IOConnection
    end
end

get_args(c::AbstractIOConnection) = c.args
get_post(c::AbstractIOConnection) = c.post
"""
```julia
get_ip(c::AbstractConnection) -> ::String
```
---
Retrieves the IP address of the current client in `String` form.
"""
get_ip(c::AbstractConnection) = c.ip

get_method(c::AbstractIOConnection) = c.method
get_route(c::AbstractIOConnection) = c.route
get_host(c::AbstractIOConnection) = c.host
get_client_system(c::AbstractIOConnection) = begin
    mobile::Bool = false
    if c.system in ("Android", "IOS")
        mobile = true
    end
    return(c.system, mobile)
end

write!(c::AbstractIOConnection, any::Any ...) = c.stream = c.stream * join(string(a) for a in any)

# args
"""
```julia
get_args(c::AbstractConnection) -> ::Dict{Symbol, String}
```
---
Returns the `GET` arguments of the current `Connection` in a `Dict{Symbol, String}`.
#### example
```example
module MyServer
using Toolips

logger = Toolips.Logger()

home = route("/") do c::Connection
    args = getargs(c)
    if :page in args
        write!(c, "requested page: " * args[:page])
    end
end

export home, logger
end
```
"""
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

"""
```julia
get_heading(c::AbstractConnection) -> ::String
```
---
Gets the markdown heading of `c`. 
#### example
```example
module MyServer
using Toolips

logger = Toolips.Logger()

home = route("/") do c::Connection
    heading = get_heading(c)
    if heading == "hello-world"
        log(logger, "someone requested hello-world")
    end
end

export home, logger
end
```
(Note that markdown headings are handled automatically by your browser, this 
is purposed primarily for a custom implementation of heading navigation.)
"""
function get_heading(c::AbstractConnection)
    target::String = c.stream.message.target
    f = findlast("#", target)
    if isnothing(f)
        ""::String
    end
    target[f + 1:length(target)]::String
end

"""
```julia
get_post(c::AbstractConnection) -> ::String
```
---
Returns the `POST` body of the current `Connection`.
#### example
```example
module Server
using Toolips
logger = Toolips.Logger()

home = route("/") do c::Connection
    name = get_post(c)
    log(logger, "\$name just posted")
    write!(c, "hello, \$name")
end
export home, logger
end

using Toolips
start!(Server); println(Toolips.post("127.0.0.1":8000, "emmy"))
```
"""
get_post(c::AbstractConnection) = string(read(c.stream))::String

"""
```julia
download!(c::AbstractConnection, uri::String) -> ::Nothing
```
---
Downloads the file stored at `uri` on the server machine to the client machine.
#### example
```example
module MyServer
using Toolips

logger = Toolips.Logger()

home = route("/") do c::Connection
    dir = @__DIR__
    download!(c, dir * "/MyServer.jl")
end

export home, logger
end
```
"""
function download!(c::AbstractConnection, uri::String)
    write(c.stream, HTTP.Response(200, body = read(uri, String)))
    nothing
end

"""
```julia
proxy_pass!(c::AbstractConnection, url::String) -> ::Nothing
```
---
Performs a *proxy pass* -- redirecting the client to another server without 
performing a request, using the current server as a *proxy* to serve the other server.
#### example
```example
module MyServer
using Toolips

logger = Toolips.Logger()

home = route("/") do c::Connection
    proxy_pass!(c, "https://github.com/ChifiSource")
end

export home, logger
end
```
"""
function proxy_pass!(c::AbstractConnection, url::String)
    HTTP.get(url, response_stream = c.stream, status_exception = false)
end

function proxy_pass!(c::AbstractConnection, ip4::IP4)
    HTTP.get("http://$(string(ip4))", response_stream = c.stream, status_exception = false)
end

startread!(c::AbstractConnection) = startread(c.stream)

"""
```julia
get_route(c::AbstractConnection) -> ::String
```
---
Gets the current target of an incoming `Connection`. (This `Function` is used 
by the router to direct  incoming connections to your routes.)
#### example
```example
module MyServer
using Toolips
using Test

logger = Toolips.Logger()

home = route("/") do c::Connection
    @test get_route(c) == "/"
end

export home, logger
end
```
"""
get_route(c::AbstractConnection) = string(split(c.stream.message.target, '?')[1])::String

"""
```julia
get_method(c::AbstractConnection) -> ::String
```
---
Gets the `METHOD` of the incoming `HTTP` request. The *METHOD* is what type of 
HTTP request the client is trying to send; `POST` or `GET`. 
#### example
```example
module MyServer
using Toolips

logger = Toolips.Logger()

home = route("/") do c::Connection
    @info "a get request?: " * string(get_method(c) == "GET")
end

export home, logger
end
```
"""
get_method(c::AbstractConnection) = string(c.stream.message.method)::String

"""
```julia
get_host(c::AbstractConnection) -> ::String
```
---
Gets the host (domain name and TLD) the client is currently requesting.
#### example
The example below is pulled directly from 
[`ChiProxy`](https://github.com/ChifiSource/ChiProxy.jl). This is a `Toolips`-based 
proxy server, which uses a router based on the hostname, rather than the target. 
By extending `route!` to alter behavior with proxy routes, this example uses `get_host` 
to determine the active path, rather than `get_route`.
```example
using Toolips
import Toolips: route!
route!(c::Connection, vec::Vector{<:AbstractProxyRoute}) = begin
    if Toolips.get_route(c) == "/favicon.ico"
        write!(c, "no icon here, fool")
        return
    end
    selected_route::String = get_host(c)
    if selected_route in vec
        route!(c, vec[selected_route])
    else
        write!(c, "this route is not here")
    end
end
```
"""
get_host(c::AbstractConnection) = string(c.stream.message["Host"])::String

"""
```julia
get_parent(c::AbstractConnection) -> ::String
```
---
Returns the `parent`, which might reference where a browser is navigating from.
#### example
```example
module MyServer
using Toolips

logger = Toolips.Logger()

home = route("/") do c::Connection
    log(logger, get_parent(c))
    write!(c, "c:")
end
export home
end
```
"""
function get_parent(c::AbstractConnection)
    string(c.stream.message.parent)
end

"""
```julia
get_client_system(c::AbstractConnection) -> (::String, ::Bool)
```
---
`get_client_system` will return the operating system of the client. 
If it is unknown, (OpenBSD or similar,) `Toolips` will count this as `Linux`. 
The `Function` will return a `String`, the systems name, and a `Bool` -- whether or not 
this is a mobile operating system.
#### example
```julia
module ClientSystem
using Toolips

logger = Toolips.Logger()

home = route("/") do c::Connection
    system, mobile = get_client_system(c)
    mobmsg = " not"
    if mobile
        mobmsg = ""
    end
    log(logger, system)
    write!(c, "you are\$mobmsg on mobile, and your system is \$system")
end
export home
end
```
"""
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
The `Route` is the most basic form of `AbstractRoute`. This constructor will likely *not* be called directly, 
instead use `route("/") do c::Connection` (or) `route(::Function, ::String)` to create routes.
```julia
using Toolips

route("/") do c::AbstractConnection
    write!(c, "Hello world!")
end
```
Routes are parametric `Toolips` types. `route!` is called once on the `Vector{<:AbstractRoute}`, 
your `Connection.routes` -- the routes for your server, and then again on the `route` directly. 
The base `Route` type, provided by `route`, is **parametric**. This allows for multiple dispatch routing 
based on the annotated `Connection` type. For this, simply route two annotated `Routes` with `route`. 
Consider the following example:
```julia
module SampleServer
using Toolips

desktop = route("/") do c::Connection
    write!(c, "this client is on desktop")
end

mobile = route("/") do c::MobileConnection
    write!(c, "this client is on mobile")
end

home = route(desktop, mobile)

export home
end
```
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

"""
```julia
abstract type AbstractMultiRoute <: AbstractRoute
```
An `AbstractMultiRoute` is essentially a router beneath the router. 
the default multi-route type is `MultiRoute`. This allows us to route multiple 
paths from the same path.
- has the field `path`, like other routes.
- Has a binding to `multiroute!`
---
- See also: `route`, `route!`, `Connection`, `multiroute!`, `MultiRoute`
"""
abstract type AbstractMultiRoute <: AbstractRoute end

"""
```julia
MultiRoute{T <: AbstractRoute} <: AbstractMultiRoute
```
- path**::String**
- routes**::Vector{T}**
---
A multi-route creates a router beneath the `target` router that normally 
routes `Toolips`. This allows for the creation of quite dynamic and flexible 
routing. `MultiRoute` is the default implementation for this interface, 
and this implementation uses `convert` and `convert!` on the `Connection` 
to determine which `Route` to be used with multiple dispatch. This effectively 
creates multiple dispatch routing, such as the case with the `MobileConnection`.
```julia
module SampleServer
using Toolips

desktop = route("/") do c::Connection
    write!(c, "this client is on desktop")
end

mobile = route("/") do c::MobileConnection
    write!(c, "this client is on mobile")
end

home = route(desktop, mobile)

export home
end
```
Here is a look at how `convert` and `convert!` are used, as well as the 
`MobileConnection` example itself:
```julia
mutable struct MobileConnection <: AbstractConnection
    stream::HTTP.Stream
    data::Dict{Symbol, Any}
    routes::Vector{AbstractRoute}
end

function convert(c::Connection, routes::Routes, into::Type{MobileConnection})
    get_client_system(c)[2]
end

function convert!(c::Connection, routes::Routes, into::Type{MobileConnection})
    MobileConnection(c.stream, c.data, routes)::MobileConnection
end
```
`convert` will return a `Bool`, determining whether or not the `Connection` should 
be converted to this `Connection` type. In this case we use the *mobile* return from 
`get_client_system`. `convert!` will turn our `Connection` into that `Connection`.
In order to add a new `Connection`, simply `import` and extend using this same template. 
For creating your multi-route, ensure a binding to `multiroute!`.
"""
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
```julia
convert(c::Connection, routes::Routes, into::Type{<:AbstractConnection}) -> ::Bool
```
---
`convert` is a `Function` designed to be extended by import. This `Function` 
simply asks if `c` should be turned into the type `into`. The return should be a 
    boolean.
#### example
The following example is the **entire** `MobileConnection` implementation.
```example
using Toolips
import Toolips: convert!, convert, AbstractConnection
mutable struct MobileConnection <: AbstractConnection
    stream::HTTP.Stream
    data::Dict{Symbol, Any}
    routes::Vector{AbstractRoute}
end

function convert(c::Connection, routes::Routes, into::Type{MobileConnection})
    get_client_system(c)[2]
end

function convert!(c::Connection, routes::Routes, into::Type{MobileConnection})
    MobileConnection(c.stream, c.data, routes)::MobileConnection
end
```
"""
convert(c::AbstractConnection, r::Vector{<:AbstractRoute}, into::Type{<:AbstractConnection}) = false::Bool

"""
```julia
convert!(c::Connection, routes::Routes, into::Type{<:AbstractConnection})
```
---
`convert` is a `Function` designed to be extended by import. This `Function` 
is called after `convert` confirms that the `Connection` should be converted. 
This `Function` converts `c` into the type `into`.
#### example
The following example is the **entire** `MobileConnection` implementation.
```example
using Toolips
import Toolips: convert!, convert, AbstractConnection
mutable struct MobileConnection <: AbstractConnection
    stream::HTTP.Stream
    data::Dict{Symbol, Any}
    routes::Vector{AbstractRoute}
end

function convert(c::Connection, routes::Routes, into::Type{MobileConnection})
    get_client_system(c)[2]
end

function convert!(c::Connection, routes::Routes, into::Type{MobileConnection})
    MobileConnection(c.stream, c.data, routes)::MobileConnection
end
```
"""
function convert! end

"""
```julia
route(::Function{T}, path::String) -> ::Route{T}
route(r::Route{<:AbstractConnection} ...) -> ::MultiRoute{Route{<:AbstractConnection}}
```
The `route` `Function` is the routing interface for `Toolips` default routes. 
`route` in most circumstances will take a *target path* and a `Function`, which 
will be the handler for the `HTTP` response. This `Route`'s handler `Function` 
will take some type of `AbstractConnection`, which we can also annotate to use with `MultiRoute`.

Inside of the handler, a `Connection` has data written to it with `write!`. This comes in the form 
of data-types and `Servables`. `Servables` are essential structures for 
building the web with HTML and files, this includes the `Component`, `File`, 
`Style`, and `KeyFrames` types provided by `Toolips`.
```julia
module RoutingExample
using Toolips

desktop = route("/") do c::Connection
    write!(c, "this client is on desktop")
end

mobile = route("/") do c::MobileConnection
    write!(c, "this client is on mobile")
end

home = route(desktop, mobile)

export home
end
```
- See also: `multiroute!`, `route!`, `Route`, `Routes`, `Connection`, `AbstractConnection`, `start!`
"""
function route end

route(f::Function, r::String) = begin
    Route(r, f)::Route{<:Any}
end

route(r::Route{<:AbstractConnection}...) = MultiRoute(r ...)

"""
```julia
route!(c::AbstractConnection, r::AbstractRoute) -> ::Nothing
route!(c::Connection, tr::Routes{<:AbstractRoute}) -> ::Nothing
```
---
The `route!` `Function` is used by the router twice; once when the entire 
`Vector` of routes is routed (the second method listed above,) and again 
on the `Route` that is routed to. Considering this, it is possible to create a new 
router by extending `route!(c::Connection, tr::Routes{<:AbstractRoute})`
#### example
The following example is pulled from [`ChiProxy`](https://github.com/ChifiSource/ChiProxy.jl), 
this example creates a router based on hostname, and also changes route functionality 
to perform a proxy pass.
```julia
using Toolips
import Toolips: route!

function route!(c::Toolips.AbstractConnection, pr::AbstractProxyRoute)
    Toolips.proxy_pass!(c, "http://\$(string(pr.ip4))")
end

route!(c::Connection, vec::Vector{<:AbstractProxyRoute}) = begin
    if Toolips.get_route(c) == "/favicon.ico"
        write!(c, "no icon here, fool")
        return
    end
    selected_route::String = get_host(c)
    if selected_route in vec
        route!(c, vec[selected_route])
    else
        write!(c, "this route is not here")
    end
end
```
- See also: `multiroute!`, `route!`, `Route`, `Routes`, `Connection`, `AbstractConnection`, `start!`
"""
function route! end

route!(c::AbstractConnection, r::AbstractRoute) = r.page(c)

function route!(c::AbstractConnection, tr::Routes{<:AbstractRoute})
    target::String = get_route(c)
    if target in tr
        selected::AbstractRoute = tr[target]
        route!(c, selected)
    elseif "404" in tr
        selected = tr["404"]
        route!(c, selected)
    else
        route!(c, default_404)
    end
end

"""
```julia
route!(c::AbstractConnection, vec::Routes, r::AbstractMultiRoute) -> ::Nothing
```
---
This `route!` dispatch allows for another router to exist underneath the `route!`-based router. This `Function` 
    is called whenever a multi-route is routed. This is designed to be **imported** and 
    extended. For this, simply create your own `<:AbstractMultiRoute` based on `MultiRoute`, 
    and then write this `Method` for that type.
- See also: `Route`, `Routes`, `Connection`, `AbstractConnection`, `MultiRoute`
"""
function route!(c::AbstractConnection, mr::AbstractMultiRoute)
    met = findfirst(r -> convert(c, mr.routes, typeof(r).parameters[1]), mr.routes)
    if isnothing(met)
        default = findfirst(r -> typeof(r).parameters[1] == Connection, mr.routes)
        if ~(isnothing(default))
            mr.routes[default].page(c)
        else
            mr.routes[1].page(c)
        end
        return
    end
    selected::AbstractRoute = mr.routes[met]
    newc::AbstractConnection = convert!(c, mr.routes, typeof(selected).parameters[1])
    mr.routes[met].page(newc)
    if typeof(newc) <: AbstractIOConnection   
        write!(c, newc.stream)
    end
end

function getindex(vec::Vector{<:AbstractRoute}, path::String)
    rt = findfirst(r::AbstractRoute -> r.path == path, vec)
    if ~(isnothing(rt))
        selected::AbstractRoute = vec[rt]
        return(vec[rt])::AbstractRoute
    end
    throw(KeyError(path))
end

function setindex!(vec::Vector{<:AbstractRoute}, r::AbstractRoute, path::String)
    rt = findfirst(newr::AbstractRoute -> newr.path == path, vec)
    if ~(isnothing(rt))
        deleteat!(vec, rt)
        push!(vec, r)
        return
    end
    throw(KeyError(path))
end

function setindex!(vec::Vector{<:AbstractRoute}, f::Function, path::String)
    rt = findfirst(newrr::AbstractRoute -> newr.path == path, vec)
    println(vec)
    if ~(isnothing(rt))
        vec[rt].page = f
        return
    end
    throw(KeyError(path))
end


# extensions
"""
```julia
abstract type AbstractExtension
```
---
An `AbstractExtension` is the top-level abstraction for a `Toolips` server extension. 
`Toolips` provides one `AbstractExtension`, the `Logger`. If the functions exist, an 
extension will call its `on_start` `Method` when the server starts and its `route!` 
`Method` everytime a client is served.

- See also: `Connection`, `route!`, `on_start`, `Toolips`, `Extension`
"""
abstract type AbstractExtension end

"""
```julia
route!(c::AbstractConnection, e::AbstractExtension) -> ::Nothing
```
---
This `route!` binding is called each time the `Connection` is created for each exported `AbstractExtension` 
with a `route!` `Method`. This `Function` is designed to be imported and extended.
```julia
module ClientCount
using Toolips
import Toolips: route!, on_start

mutable struct ClientCounter <: Toolips.AbstractExtension

end

function on_start(ext::ClientCounter, data::Dict{Symbol, Any}, routes::Vector{<:AbstractRoute})
    push!(data, :clients => 0)
end

function route!(c::AbstractConnection, e::ClientCounter)
    c[:clients] += 1
end

home = route("/") do c::Connection
    write!(c, "you are client #" * string(c[:clients]))
end

counter = ClientCounter()
export counter, home
end
```
- See also: `Connection`, `route!`, `on_start`, `Toolips`, `Extension`
"""
function route!(c::AbstractConnection, e::AbstractExtension)
end

"""
```julia
on_start(ext::AbstractExtension, data::Dict{Symbol, Any}, routes::Vector{<:AbstractRoute}) -> ::Nothing
```
---
The `on_start` binding is called for each exported extension with this `Method` when the server starts.
```julia
module ClientCount
using Toolips
import Toolips: on_start

mutable struct SayHello

end

function on_start(ext::SayHello, data::Dict{Symbol, Any}, routes::Vector{<:AbstractRoute})
    println("hello world!")
end

greeter = SayHello()

home = route("/") do c::Connection
    write!(c, ":)")
end

export greeter, home
end
```
- See also: `route!`, `AbstractExtension`, `route`, `kill!`, `start!`
"""
function on_start(ext::AbstractExtension, data::Dict{Symbol, Any}, routes::Vector{<:AbstractRoute})
end

"""
```julia
kill!(mod::Module) -> ::Nothing
```
---
`kill!` will stop an active `Toolips` server.
```julia
pm::Toolips.ProcessManager = start!(Toolips, "127.0.0.1":8000)
kill!(Toolips)
```
- See also: `route`, `start!`, `Toolips`, `new_app`
"""
function kill!(mod::Module)
    try
        getfield(mod, :server)
    catch e
        throw("trying to `kill!` inactive server: $mod")
    end
    close(mod.data[:procs])
    close(mod.server)
    mod.server = nothing
    mod.routes = nothing
    mod.data = nothing
    GC.gc(true)
    Pkg.gc()
end

mutable struct StartError <: Exception
    message::String
end

mutable struct RouteError{E <: Any} <: Exception
    path::String
    message::E
end

function showerror(io::IO, e::RouteError)
    print(io, Crayon(foreground = :yellow), "ERROR ON ROUTE: $(e.path) $(e.message)")
end

showerror(io::IO, e::StartError) = print(io, Crayon(foreground = :blue, bold = true), "Error starting server: $(e.message)")

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

"""
- start a standard WebServer:
```julia
start!(mod::Module = server_cli(Main.ARGS), ip::IP4 = ip4_cli(Main.ARGS), from::Type{<:ServerTemplate}; threads::Int64 = 1, router_threads::UnitRange{Int64} = -2:threads) -> ::ParametricProcesses.ProcessManager
```
- for extended servers:
```julia
# pass-through for extension server start:
start!(symb::Symbol, args ...; keyargs ...) = start!(ServerTemplate{symb}, args ...; keyargs ...)
# second pass-through, default function starts regular HTTP router through main `start!` (parametric type):
start!(st::ServerTemplate{<:Any}, mod::Module = Toolips.server_cli(Main.ARGS); keyargs ...)
# main (HTTP server) `start!`:
function start!(mod::Module = Main, ip::IP4 = ip4_cli(Main.ARGS);
    threads::Int64 = 1, router_threads::UnitRange{Int64} = -2:threads, router::Type{<:AbstractRoute} = AbstractRoute)
```
---
`start!` is used on a `Toolips` server `Module` to start a new server. Providing `threads` sets the total amount of threads to spawn for the accompanying `ProcessManager`. `router_threads` will determine how the router handles threads. 
Every thread in this range until `0` will be the base thread, so `-2:threads` -- for example -- will serve 3 clients with the base threads, -2, -1, 0, and then move onto the first thread with 1, moving onto 2, and so-forth.
```julia
module MyExampleServer
using Toolips

home = route("/") do c::AbstractConnection
   write!(c, "hello world!")
end

export home, start!
end

using Main.MyExampleServer; start!(Main.MyExampleServer)
```
Note that a router type can also be provided to `start!`. This allows us to change the functionality of the function very easily. We can also provide a certain 
`ServerTemplate` start if we don't want a normal HTTP server.
- See also: `route!`, `AbstractExtension`, `route`, `kill!`, `start!`
"""
function start! end

abstract type AbstractServerTemplate end

struct ServerTemplate{T} <: AbstractServerTemplate end

WebServer = ServerTemplate{:webserver}

start!(symb::Symbol, args ...; keyargs ...) = start!(ServerTemplate{symb}, args ...; keyargs ...)

function start!(st::ServerTemplate{<:Any}, mod::Module = Toolips.server_cli(Main.ARGS); keyargs ...)
    start!(mod; keyargs ...)
end

function start!(mod::Module = Main, ip::IP4 = ip4_cli(Main.ARGS);
    threads::Int64 = 1, router_threads::UnitRange{Int64} = -2:threads, router::Type{<:AbstractRoute} = AbstractRoute)
    IP = Sockets.InetAddr(parse(IPAddr, ip.ip), ip.port)
    server::Sockets.TCPServer = Sockets.listen(IP)
    mod.server = server
    routeserver::Function, pm::ProcessManager = generate_router(mod, ip, router)
    w::Worker{Async} = pm["$mod router"]
    if threads > 1 && length(0:maximum(router_threads)) > 0
        if Threads.nthreads() < threads
            throw(StartError("Julia was not started with enough threads for this server."))
        end
        log(mod.data[:Logger], "adding $threads threaded workers ...", 2)
        add_workers!(pm, threads)
        pids::Vector{Int64} = [work.pid for work in filter(w -> typeof(w) != Worker{ParametricProcesses.Async}, pm.workers)]
        log(mod.data[:Logger], "spawned threaded workers: $(join(("$pid" for pid in pids), "|"))", 2)
        Main.eval(Meta.parse("""using Toolips: @everywhere; @everywhere begin
            using Toolips
            using $mod
        end"""))
        put!(pm, pids, routeserver)
        garbage::Int64 = 0
        put!(pm, pids, garbage)
        selected::Int8 = Int8(minimum(router_threads))
        finish::UInt8 = UInt8(maximum(router_threads))
        routes = mod.routes
        data = mod.data
        put!(pm, pids, routes)
        put!(pm, pids, data)
        @async HTTP.listen(ip.ip, ip.port, server = server) do http::HTTP.Stream
            ioc::IOConnection = IOConnection(http, data, routes)
            @sync selected += 1
            if selected > finish
                @sync selected = minimum(router_threads[1])
            end
            if selected < 1
                routeserver(ioc, garbage)
                write(http, ioc.stream)
                mod.data, mod.routes = ioc.data, ioc.routes
                return
            end
            id::Int64 = pids[selected]
            put!(pm, [id], ioc)
            jb::ParametricProcesses.ProcessJob = new_job() do
                routeserver(ioc, garbage)
                ioc
            end
            assign!(pm, id, jb)
            ioc = waitfor(pm, id)[1]
            @sync begin
                mod.routes = [r for r in ioc.routes]
                [mod.data[key] = ioc.data[key] for key in keys(mod.data)]
            end
            write(http, ioc.stream)
        end
        w.active = true
        return(pm::ProcessManager)
    end
    serve_router = @async HTTP.listen(routeserver, ip.ip, ip.port, server = server)
    w.task = serve_router
    w.active = true
    pm::ProcessManager
end

router_name(t::Type{<:AbstractRoute}) = "toolips.jl http target router"

function generate_router(mod::Module, ip::IP4, T::Type{<:AbstractRoute} = AbstractRoute)
    # Load Extensions, routes, and data.
    server_ns = names(mod)
    mod.routes = Vector{T}()
    loaded = []
    for name in server_ns
        f = getfield(mod, name)
        ST = typeof(f)
        if ST <: AbstractExtension
            push!(loaded, f)
        elseif ST <: AbstractRoute
            push!(mod.routes, f)
        elseif ST <: AbstractVector{<:AbstractRoute}
            mod.routes = vcat(mod.routes, f)
        end
        ST
    end
    server_ns = nothing
    logger_check = findfirst(t -> typeof(t) == Logger, loaded)
    if isnothing(logger_check)
        push!(loaded, Logger())
        logger_check = length(loaded)
    end
    logger = loaded[logger_check]
    log(logger, "loaded router type: $(router_name(T))", 2)
    log(logger, "server listening at http://$(string(ip))")
    logger_check = nothing
    data = Dict{Symbol, Any}()
    push!(data, :Logger => logger)
    for ext in loaded
        on_start(ext, data, mod.routes) 
    end
    allparams = (m.sig.parameters[3] for m in methods(route!, Any[AbstractConnection, AbstractExtension]))
    filter!(ext -> typeof(ext) in allparams, loaded)
    # process manager Routing func (async)
    w::Worker{Async} = Worker{Async}("$mod router", rand(1000:3000))
    pman::ProcessManager = ProcessManager(w)
    push!(data, :procs => pman)
    garbage::Int8 = UInt8(0)
    T = nothing
    GC.gc(true)
    Pkg.gc()
    routeserver = make_routers(garbage, mod.routes, loaded, data)
    return(routeserver, pman)
end

function make_routers(garbage::Integer, routes::Vector{<:AbstractRoute}, loaded::Vector{<:Any}, data)
    routeserver(http::HTTP.Stream) = begin
        host, port = Sockets.getpeername(http)
        c::AbstractConnection = Connection(http, data, routes, string(host))
        for ext in loaded
            stop = route!(c, ext)
            if stop == false
                return
            end
        end
        route!(c, c.routes)::Any
        routes = c.routes
        garbage += 1
        if garbage == 25
            GC.gc()
        elseif garbage == 50
            GC.gc()
        elseif garbage == 75
            GC.gc()
        elseif garbage == 100
            GC.gc(true)
            garbage = 0
        end
    end
    routeserver(c::IOConnection, garbage::Int64) = begin
        for ext in loaded
            stop = route!(c, ext)
            if stop == false
                return(c.stream)::String
            end
        end
        route!(c, c.routes)::Any
        garbage += 1
        if garbage == 25
            GC.gc()
        elseif garbage == 50
            GC.gc()
        elseif garbage == 75
            GC.gc()
        elseif garbage == 100
            GC.gc(true)
            garbage = 0
        end
        c.stream::String
    end
    return(routeserver)
end

display(ts::ServerTemplate) = show(ts)

