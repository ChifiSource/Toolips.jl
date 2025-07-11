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
```example
response = Toolips.get("https://github.com/ChifiSource")
```
"""
function get(url::String)
    r = HTTP.request("GET", url)
    string(r.body)::String
end

get(url::IP4) = get("http://$(url.ip):$(url.port)")::String

"""
```julia
post(url::String, body::String) -> ::String
post(url::IP4, body::String) -> ::String
```
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
- See also: `route`, `route!`, `Connection`, `AbstractConnection`
"""
abstract type AbstractRoute end

"""
```julia
abstract type AbstractHTTPRoute
```
An `AbstractHTTPRoute` is a route that is designed for the `Toolips` HTTP target router.
---
- See also: `route`, `route!`, `Connection`, `AbstractConnection`
"""
abstract type AbstractHTTPRoute <: AbstractRoute end

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
`Servables` are also binded to `write!`, so a `Connection` can easily serve `Components`, the `File` `Servable`, 
as well as text and more.
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
Returns the `GET` arguments of the current `Connection` in a `Dict{Symbol, String}`.
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
get_headers(c::Connection) -> ::Vector{Pair{String, String}}
```
Returns the *headers* of a given `Connection` in the form of a `Vector{Pair{String, String}}`. 
These headers can be changed in a larger variety of ways using `respond!`.
```julia
route("/forwardheader") do c::AbstractConnection
    headers = get_headers(c)
    f = findfirst(h -> contains(h[1], "X-Forwarded-For"), headers)
    if ~(isnothing(f))
        deleteat!(headers, f)
    end
    push!(headers, "X-Forwarded-For" => client_ip)
end
```
- See also: `get_ip`, `get_ip4`, `route!`, `Connection`, `AbstractConnection`
"""
function get_headers(c::Connection)
    headers = c.stream.message.headers::Vector
end

"""
```julia
get_heading(c::AbstractConnection) -> ::String
```
Gets the markdown heading of `c`. 
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
Returns the `POST` body of the current `Connection`.
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

read(c::AbstractConnection) = read(c.stream)

readavailable(c::AbstractConnection) = readavailable(c.stream)


eof(con::AbstractConnection) = eof(c.stream)::Bool

"""
```julia
download!(c::AbstractConnection, uri::String) -> ::Nothing
```
Downloads the file stored at `uri` on the server machine to the client machine.
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
    file_body = read(uri, String)
    resp = HTTP.Response(200, body = file_body)
    push!(resp.headers, "Content-Length" => SubString(string(length(file_body))), "Transfer-Encoding" => "chunked")
    startwrite(c.stream)
    write(c.stream, resp)
    stopwrite(c.stream)
    return(resp)
end

"""
```julia
proxy_pass!(c::AbstractConnection, url::String) -> ::Nothing
```
Performs a *proxy pass* -- redirecting the client to another server without 
performing a request, using the current server as a *proxy* to serve the other server.
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
Gets the current target of an incoming `Connection`. (This `Function` is used 
by the router to direct  incoming connections to your routes.)
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
Gets the `METHOD` of the incoming `HTTP` request. The *METHOD* is what type of 
HTTP request the client is trying to send; `POST` or `GET`. 
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
Gets the host (domain name and TLD) the client is currently requesting.
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
get_cookies(c::AbstractConnection) -> ::Vector{Cookie}
```
Gets the cookies from a given `Connection`. These cookies can be stored using 
`respond!`, see `Toolips.respond!` && `Toolips.Cookie` alongside this function.
```example
module CookieServer
using Dates
using Toolips

main = route("c") do c::AbstractConnection
    cookies = get_cookies(c)
    if length(cookies) == 0
        cookie = Toolips.Cookie(
            name = "session_id",
            value = "abc123",
            path = "/",
            httponly = true,
            expires = now() + Day(1)  # Cookie expires in 1 day)
                                    # (must be a `Vector{Cookie}`)
        respond!(c, "you now have a cookie.", [cookie])
    else
        the_cookie = cookies[1]
        write!(c, "you were successfully verified")
    end
end

export main
end
```
"""
get_cookies(c::Connection) = HTTP.cookies(c.stream.message)::Vector{Cookie}

function add_cookies!(con::AbstractConnection, namevals::Pair{String, String} ...; attrs...)
    for nameval in namevals
	    cookie = "$(nameval[1])=$(nameval[2])"
	    for (attr_name, attr_val) in attrs
		    if attr_val === true
			    cookie *= "; $attr_name"
		    else
			    cookie *= "; $attr_name=$attr_val"
		    end
	    end
        HTTP.setheader(con.stream, "Set-Cookie" => cookie)
    end
end

add_cookies!(con::AbstractConnection, cookies::Cookie ...; at ...) = add_cookies!(con, [cookie.name => cookie.value for cookie in cookies] ...; att ...)


function clear_cookies!(con::AbstractConnection)
    HTTP.removeheader(con.stream.message, "Cookie")
    HTTP.removeheader(con.stream.message, "Cookies")
    HTTP.removeheader(con.stream.message, "Set-Cookie")
end

function remove_cookie!(con::AbstractConnection, name::String)
	old = HTTP.header(con.stream, "Set-Cookie")
	cookies = isa(old, String) ? [old] : (old === nothing ? String[] : copy(old))

	name_eq = name * "="
	filtered = [c for c in cookies if !startswith(c, name_eq)]

	if isempty(filtered)
		HTTP.setheader(con.stream, "Set-Cookie" => nothing)
	else
        for cook in filtered
		    HTTP.setheader(con.stream, "Set-Cookie" => filtered)
        end
	end
end

function in(key::String, cooks::Vector{Cookie})
    f = findfirst(cook::Cookie -> cook.name == key, cooks)
    ~(isnothing(f))
end

function getindex(cooks::Vector{Cookie}, key::String)
    f = findfirst(cook::Cookie -> cook.name == key, cooks)
    if isnothing(f)
        throw(BoundsError())
    end
    cooks[f]
end

"""
```julia
get_parent(c::AbstractConnection) -> ::String
```
Returns the `parent`, which might reference where a browser is navigating from.
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
`get_client_system` will return the operating system of the client. 
If it is unknown, (OpenBSD or similar,) `Toolips` will count this as `Linux`. 
The `Function` will return a `String`, the systems name, and a `Bool` -- whether or not 
this is a mobile operating system.
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

"""
```julia
respond!(c::AbstractConnection, args ...) -> ::Nothing
```
A more articulated response from a `Toolips` server, `respond!` allows us to add custom 
headers to our HTTP response, respond with different codes, and set cookies.
```julia
# base method (mostly internal)
respond!(c::AbstractConnection, resp::HTTP.Response, headers::Pair{String, String} ...)
# regular headers/code dispatch
respond!(c::AbstractConnection, body::String = "", headers::Pair{String, String} ...; code::Int64 = 200)
```
The `Vector{Cookie}` dispatch, for setting cookies on response (see `Cookie` and `get_cookies`):
```julia
respond!(c::AbstractConnection, body::String, cookies::Vector{Cookie}, headers::Pair{String, String} ...; 
    code::Int64 = 20)
```
description of method list
- See also: `write!`, `get_target`, `Connection`, `route`, `start!`
"""
function respond!(c::AbstractConnection, resp::HTTP.Response, headers::Pair{String, String} ...)
    for header in headers
        HTTP.setheader(resp, header)
    end
    for header in resp.headers
        HTTP.setheader(c.stream, header)
    end
    HTTP.setstatus(c.stream, resp.status)
    write!(c, String(resp.body))
end

function respond!(c::AbstractConnection, body::String = "", headers::Pair{String, String} ...; code::Int64 = 200)
    respond!(c, HTTP.Response(code, body = body), headers ...)
end

function respond!(c::AbstractConnection, body::String, cookies::Vector{Cookie}, headers::Pair{String, String} ...; 
    code::Int64 = 200)
    response::HTTP.Response = HTTP.Response(code, body = body)
    for cookie in cookies
        HTTP.addcookie!(response, cookie)
    end
    respond!(c, response, headers ...)
end

"""
```julia
Route{T <: AbstractConnection} <: AbstractHTTPRoute
```
- path**::String**
- page**::Function**

The `Route` is the most basic form of `AbstractRoute` -- the `AbstractHTTPRoute` that comes with `Toolips` and 
fills the role of basic routing for the framework. This constructor will likely *not* be called directly, 
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
mutable struct Route{T <: AbstractConnection} <: AbstractHTTPRoute
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
abstract type AbstractMultiRoute <: AbstractHTTPRoute
```
An `AbstractMultiRoute` is a router beneath the router. 
the default multi-route type is `MultiRoute`. This allows us to route an incoming 
client according to `Connection` conditions with multiple dispatch. Creating your 
own multi-route allows for the creation of a new routing step without writing in 
an entirely new custom router.

- has the field `path`, like other routes.
- Has a binding to `multiroute!`
- See also: `route`, `route!`, `Connection`, `multiroute!`, `MultiRoute`
"""
abstract type AbstractMultiRoute <: AbstractHTTPRoute end

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
`convert` is a `Function` designed to be extended by import. This `Function` 
simply asks if `c` should be turned into the type `into`. The return should be a 
    boolean.

- The following example is the **entire** `MobileConnection` implementation:
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
- See also: `MultiRoute`, `convert!`, `Route`, `convert`, `Connection`, `AbstractConnection`
"""
convert(c::AbstractConnection, r::Vector{<:AbstractRoute}, into::Type{<:AbstractConnection}) = false::Bool

"""
```julia
convert!(c::Connection, routes::Routes, into::Type{<:AbstractConnection})
```
`convert` is a `Function` designed to be extended by import. This `Function` 
is called after `convert` confirms that the `Connection` should be converted. 
This `Function` converts `c` into the type `into`.
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
- See also: `multiroute!`, `route!`, `Route`, `convert`, `Connection`, `AbstractConnection`, `start!`
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
The `route!` `Function` is used by the router twice; once when the entire 
`Vector` of routes is routed (the second method listed above,) and again 
on the `Route` that is routed to. Considering this, it is possible to create a new 
router by extending `route!(c::Connection, tr::Routes{<:AbstractRoute})`
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
    ret::Any = nothing
    if target in tr
        selected::AbstractRoute = tr[target]
        ret = route!(c, selected)
    elseif "404" in tr
        selected = tr["404"]
        ret = route!(c, selected)
    else
        route!(c, default_404)
    end
    ret::Any
end

"""
```julia
route!(c::AbstractConnection, vec::Routes, r::AbstractMultiRoute) -> ::Nothing
```
This `route!` dispatch allows for another router to exist underneath the `route!`-based router. This `Function` 
    is called whenever a multi-route is routed. This is designed to be **imported** and 
    extended. For this, simply create your own `<:AbstractMultiRoute` based on `MultiRoute`, 
    and then write this `Method` for that type. The default `Toolips.MultiRoute`, for example, routes the 
        `Route{<:AbstractConnection}` according to the type of incoming `Connection`.
- See also: `Route`, `Routes`, `Connection`, `AbstractConnection`, `MultiRoute`
"""
function route!(c::AbstractConnection, mr::AbstractMultiRoute)
    met = findfirst(r -> convert(c, mr.routes, typeof(r).parameters[1]), mr.routes)
    if met === nothing
        default = findfirst(r -> typeof(r).parameters[1] == Connection, mr.routes)
        (default !== nothing ? mr.routes[default] : mr.routes[1]).page(c)
        return
    end
    selected = mr.routes[met]
    newc = convert!(c, mr.routes, typeof(selected).parameters[1])
    selected.page(newc)
    
    if newc isa AbstractIOConnection   
        write!(c, newc.stream)
    end
end

function getindex(vec::Vector{<:AbstractRoute}, path::String)
    rt = findfirst(r -> r.path == path, vec)
    rt !== nothing ? vec[rt] : throw(KeyError(path))
end

function setindex!(vec::Vector{<:AbstractRoute}, r::AbstractRoute, path::String)
    rt = findfirst(newr -> newr.path == path, vec)
    if rt !== nothing
        vec[rt] = r
    else
        throw(KeyError(path))
    end
end

function setindex!(vec::Vector{<:AbstractRoute}, f::Function, path::String)
    rt = findfirst(newr -> newr.path == path, vec)
    if rt !== nothing
        vec[rt].page = f
    else
        throw(KeyError(path))
    end
end

function delete!(vec::Vector{<:AbstractRoute}, path::String)
    rt = findfirst(newr -> newr.path == path, vec)
    if rt !== nothing
        deleteat!(vec, rt)
    else
        throw(KeyError(path))
    end
end

# extensions
"""
```julia
abstract type AbstractExtension
```
An `AbstractExtension` is the top-level abstraction for a `Toolips` server extension. 
`Toolips` provides one `AbstractExtension`, the `Logger`. If the functions exist, an 
extension will call its `on_start` `Method` when the server starts and its `route!` 
`Method` everytime a client is served.

- See also: `Connection`, `route!`, `on_start`, `Toolips`, `Extension`
"""
abstract type AbstractExtension end

"""
```julia
struct QuickExtension{T <: Any} <: Toolips.AbstractExtension
```
- (this type contains no fields)

The `QuickExtension` is a convenient way to *quickly* load new functionality into a 
`Toolips` server. These can be used identically to other sub-types of `AbstractExtension` 
and are symbolic in nature. This avoids us having to create a new extension for something simple.
```julia
QuickExtension{T}
```
```julia
function on_start(ext::Toolips.QuickExtension{:clients}, data::Dict{Symbol, Any}, 
    routes::Vector{<:AbstractRoute})
    push!(data, :clients => Vector{ClientComputer}())
end
```
- See also: `AbstractExtension`, `route!`, `on_start!`, `AbstractConnection`
"""

struct QuickExtension{T} <: AbstractExtension end

"""
```julia
route!(c::AbstractConnection, e::AbstractExtension) -> ::Nothing
```
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
`kill!` will stop an active `Toolips` server.
```julia
pm::Toolips.ProcessManager = start!(Toolips, "127.0.0.1":8000)
kill!(Toolips)
```
- See also: `route`, `start!`, `Toolips`, `new_app`
"""
function kill!(mod::Module)
    server_names::Vector{Symbol} = names(mod, all = true)
    if :server in server_names
        close(mod.server)
        if :procs in server_names
            if typeof(mod.procs) == ProcessManager
                close(mod.procs)
                mod.procs = nothing
            end
        end
        mod.server = nothing
        if :routes in server_names
            mod.routes = nothing
        end
        
        GC.gc(true)
        Pkg.gc()
        @info "server $mod successfully closed"
    else
        @warn "could not stop server $mod. (Inactive server?)"
    end
end

kill!(sock::Sockets.TCPSocket) = close(sock)

mutable struct StartError <: Exception
    message::String
end

mutable struct RouteError{E <: Any} <: Exception
    path::String
    message::E
end

function showerror(io::IO, e::RouteError)
    print(io, Crayon(foreground = :yellow), "ERROR ON ROUTE: $(e.path)    $(e.message)")
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
start!(mod::Module = Main, ip::IP4 = ip4_cli(Main.ARGS);
    threads::Int64 = 1, router_threads::UnitRange{Int64} = -2:threads, router_type::Type{<:AbstractRoute} = AbstractRoute, 
    async::Bool = true)
```
- for extended servers:
```julia
start!(st::Type{ServerTemplate{<:Any}}, mod::Module = Toolips.server_cli(Main.ARGS); keyargs ...)
start!(st::Symbol, mod::Module, args ...; keyargs ...)
# TCP start:
start!(st::ServerTemplate{:TCP}, mod::Module = Main, ip::IP4 = ip4_cli(Main.ARGS);
    threads::Int64 = 1, async::Bool = false)
```
- (extension) for a `TCP` server (no HTTP):
```julia
start!(st::ServerTemplate{:TCP}, mod::Module = Main, ip::IP4 = ip4_cli(Main.ARGS), 
    threads::Int64 = 1, async::Bool = false)
```
`start!` is used on a `Toolips` server `Module` to start a new server. Providing `threads` sets 
the total amount of threads to spawn for the accompanying `ProcessManager`. `router_threads` will 
    determine how the router handles threads.  Every thread in this range until `0` will be the base
     thread, so `-2:threads` -- for example -- will serve 3 clients with the base threads, -2, -1, 0, 
     and then move onto the first thread with 1, moving onto 2, and so-forth.
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
- See also: `route!`, `AbstractExtension`, `route`, `kill!`, `start!`
"""
function start! end

abstract type AbstractServerTemplate end

struct ServerTemplate{T} <: AbstractServerTemplate end

WebServer = ServerTemplate{:webserver}
start!(st::Symbol, mod::Module, args ...; keyargs ...) = start!(ServerTemplate{st}(), mod, args ...; keyargs ...)

function start!(st::ServerTemplate{<:Any}, mod::Module = Toolips.server_cli(Main.ARGS); keyargs ...)
    start!(mod; keyargs ...)
end

function start!(mod::Module = Main, ip::IP4 = ip4_cli(Main.ARGS);
    threads::Int64 = 1, router_threads::UnitRange{Int64} = -2:threads, router_type::Type{<:AbstractRoute} = AbstractHTTPRoute, 
    async::Bool = true)
    IP = Sockets.InetAddr(parse(IPAddr, ip.ip), ip.port)
    server::Sockets.TCPServer = Sockets.listen(IP)
    mod.eval(Meta.parse("server = nothing; procs = nothing; routes = nothing; data = Dict{Symbol, Any}()"))
    mod.server = server
    routeserver::Function, pm::ProcessManager = generate_router(mod, ip, router_type, threads)
    w::Worker{Async} = pm["$mod router"]
    if threads > 1 && maximum(router_threads) > 1
        if async == false
            @warn "cannot run synchronous server with router threads"
            @warn "starting asynchronously... (remove `async = false` to stop this warning)"
        end
        if Threads.nthreads() < threads
            throw(StartError("Julia was not started with enough threads for this server."))
        end
        has_logger = haskey(mod.data, :Logger)
        if has_logger
            log(mod.data[:Logger], "adding $threads threaded workers ...", 2)
        end
        pids::Vector{Int64} = worker_pids(pm, Threaded)
        if has_logger
            log(mod.data[:Logger], "spawned threaded workers: $(join(("$pid" for pid in pids), "|"))", 2)
        end
        for pid in router_threads
            if pid > 1
                put!(pid, pm, routeserver)
            end
        end
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
    if async
        serve_router = @async HTTP.listen(routeserver, ip.ip, ip.port, server = server)
        w.task = serve_router
        w.active = true
        pm::ProcessManager
    else
        w.active = true
        serve_router = HTTP.listen(routeserver, ip.ip, ip.port, server = server)
        w.task = serve_router
        pm::ProcessManager
    end
end


"""
```julia
router_name(t::Any) -> ::String
```
`router_name` is used to name your router by the `Type` of the router's routes. 
For example, the dispatch that names the `HTTP` router is for `Type{<:AbstractHTTPRoute}`.
```julia
import Toolips: router_name

router_name(t::Type{<:AbstractHTTPRoute}) = "toolips http target router"
```
- See also: `route!`, `start!`, `Route`, `Connection`, `Toolips`
"""
router_name(t::Any) = "unnamed custom router ($(t))"

router_name(t::Type{<:AbstractHTTPRoute}) = "toolips http target router"

function generate_router(mod::Module, ip::IP4, RT::Type{<:AbstractRoute}, threads::Integer = 1)
    mod.routes = Vector{RT}()
    data = Dict{Symbol, Any}()
    workers = Worker{Async}("$mod router", rand(1000:3000))
    pman = ProcessManager(workers)
    if threads > 1
        add_workers!(pman, threads - 1)
                Main.eval(Meta.parse("""using Toolips: @everywhere; @everywhere begin
            using Toolips
            using $mod
        end"""))
    end
    data[:procs] = pman
    loaded = AbstractExtension[]
    for name in names(mod)
        f = getfield(mod, name)
        if ~(isdefined(mod, name))
            continue
        end
        if f isa AbstractExtension
            push!(loaded, f)
            on_start(f, data, mod.routes)
        elseif f isa AbstractRoute
            push!(mod.routes, f)
        elseif f isa AbstractVector{<:AbstractRoute}
            append!(mod.routes, f)
        end
    end
    if RT == AbstractHTTPRoute
        mod.routes = [r for r in mod.routes]
    end
    if any(ext -> ext isa Logger, loaded)
        logger = filter(ext -> ext isa Logger, loaded)[1]
        log(logger, "Router type: $(router_name(typeof(mod.routes).parameters[1]))", 2)
        log(logger, "Server listening at http://$(ip.ip):$(ip.port)")
    end
    mod.data = data
    return make_routers(mod.routes, loaded, data), pman
end

function internal_http_route(http::HTTP.Stream, routes::Vector{<:AbstractRoute}, loaded::Vector, data::Dict)
    host, _ = Sockets.getpeername(http)
    headers = http.message.headers
    f = findfirst(h -> h[1] == "X-Forwarded-For", headers)
	if ~(isnothing(f))
		host = split(headers[f][2], ",")[1] |> strip
    end
    c = Connection(http, data, routes, string(host))
    for ext in loaded
        if route!(c, ext) === false
            return
        end
    end
    route!(c, c.routes)
end

function internal_ioc_route(c::AbstractConnection, garbage::Int64)
    for ext in loaded
        if route!(c, ext) === false
            return
        end
    end
    route!(c, c.routes)
    garbage += 1
    if garbage % 5000 == 0
        if garbage == 15000
            GC.gc(true)
            garbage = 0
        else
            GC.gc()
        end
    end
    c.stream::String
end

function make_routers(routes, loaded, data)
    function routeserver(http::HTTP.Stream)
        internal_http_route(http, routes, loaded, data)
    end
    function routeserver(c::IOConnection, garbage::Int64)
        internal_ioc_route(c, garbage)
    end
    return(routeserver)::Function
end


display(ts::ServerTemplate) = show(ts)

