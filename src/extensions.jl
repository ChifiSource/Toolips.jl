#==
map
- file interpolation
- additional connections
- logger
- mount
- TCP servers
==#
"""
```julia
MobileConnection <: AbstractConnection
```
- stream**::HTTP.Stream**
- data**::Dict{Symbol, Any}**
- ret**::Any**

A `MobileConnection` is used with multi-route and will be created when an incoming `Connection` is mobile. 
This is done by simply annotating your `Function`'s `Connection` argument when calling `route`. To create one 
page for both of these routes, we then use `route` to combine them.
```julia
module ExampleServer
using Toolips
main = route("/") do c::Connection
    write!(c, "this is a desktop.")
end

mobile = route("/") do c::Toolips.MobileConnection
    write!(c, "this is mobile")
end

# multiroute (will call `mobile` if it is a `MobileConnection`, meaning the client is on mobile)
home = route(main, mobile)

# then we simply export the multi-route
export home
end
using Toolips; Toolips.start!(ExampleServer)
```
- See also: `route`, `Connection`, `route!`, `Components`, `convert`, `convert!`

It is unlikely you will use this constructor unless you are calling 
`convert!`/`convert` in your own `route!` design. This `Connection` type is 
primarily meant to be dispatched as it is in the example.
```julia
MobileConnection(stream::HTTP.Stream, data::Dict{Symbol, Any}, routes::Vector{AbstractRoute})
```
"""
mutable struct MobileConnection{T} <: AbstractConnection
    stream::Any
    data::Dict{Symbol, Any}
    routes::Vector{AbstractRoute}
    MobileConnection(stream::Any, data::Dict{Symbol, <:Any}, routes::Vector{<:AbstractRoute}) = begin
        new{typeof(stream)}(stream, data, routes)
    end
end

function convert(c::AbstractConnection, routes::Routes, into::Type{MobileConnection})
    get_client_system(c)[2]::Bool
end

function convert!(c::AbstractConnection, routes::Routes, into::Type{MobileConnection})
    MobileConnection(c.stream, c.data, routes)::MobileConnection{typeof(c.stream)}
end

# for IO Connection specifically...
function convert!(c::IOConnection, routes::Routes, into::Type{MobileConnection})
    stream = Dict{Symbol, String}(:stream => c.stream, :args => get_args(c), :post => get_post(c), 
    :ip => get_ip(c), :method => get_method(c), :target => get_route(c), :host => get_host(c))
    MobileConnection(stream, c.data, routes)::MobileConnection{Dict{Symbol, String}}
end

get_ip(c::MobileConnection{Dict{Symbol, String}}) = c.stream[:ip]
get_method(c::MobileConnection{Dict{Symbol, String}}) = c.stream[:method]
get_args(c::MobileConnection{Dict{Symbol, String}}) = c.stream[:args]
get_route(c::MobileConnection{Dict{Symbol, String}}) = c.stream[:target]
get_host(c::MobileConnection{Dict{Symbol, String}}) = c.stream[:host]
get_post(c::MobileConnection{Dict{Symbol, String}}) = c.stream[:post]
write!(c::MobileConnection{Dict{Symbol, String}}, a::Any ...) = c.stream[:stream] = c.stream[:stream] * join(string(obj) for obj in a)

"""
```julia
Logger <: Toolips.AbstractExtension
```
- `crayons`**::Vector{Crayon}**
- `prefix`**::String**
- `write`**::Bool**
- `writeat`**::Int64**
- `prefix_crayon`**::Crayon**
```julia
Logger(prefix::String = "🌷 toolips> ", crayons::Crayon ...; dir::String = "logs.txt", write::Bool = false, 
writeat::Int64, prefix_crayon::Crayon = Crayon(foreground  = :blue, bold = true))
```
```example
module ExampleServer
using Toolips
crays = (Toolips.Crayon(foreground = :red), Toolips.Crayon(foreground = :black, background = :white, bold = true))
log = Toolips.Logger("yourserver>", crays ...)

# use logger
route("/") do c::Connection
    log(c, "hello world!", 1)
end
# load to server
export log
end
using Toolips; Toolips.start!(ExampleServer)
```
- See also: `route`, `Connection`, `Extension`
"""
mutable struct Logger <: AbstractExtension
    crayons::Vector{Crayon}
    prefix::String
    write::Bool
    writeat::UInt8
    prefix_crayon::Crayon
    function Logger(prefix::String = "🌷 toolips> ", crayons::Crayon ...; dir::String = "logs.txt",
        write::Bool = false, writeat::Int64 = 3, prefix_crayon = Crayon(foreground  = :blue, bold = true))
        if write && ~(isfile(dir))
            try
                touch(dir)
            catch
                throw("Logger tried to make log file \"$dir\", but could not.")
            end
        end
        if length(crayons) < 1
            crayons = [Crayon(foreground  = :light_blue, bold = true), Crayon(foreground = :yellow, bold = true), 
            Crayon(foreground = :red, bold = true)]
        end
        new([crayon for crayon in crayons], prefix, write, UInt8(writeat), prefix_crayon)
    end
end

function log(l::Logger, message::String, at::Int64 = 1)
    cray = l.crayons[at]
    println(l.prefix_crayon, l.prefix, cray, message)
end

"""
```julia
log(c::Connection, message::String, at::Int64 = 1) -> ::Nothing
```
`log` will print the message with your `Logger` using the crayon `at`. `Logger` 
will give a lot more information on this.
```example
module MyServer
using Toolips

logger = Toolips.Logger()

home = route("/") do c::Connection
    log(c, "hello server!")
    write!(c, "hello client!")
end

export home, logger
end
```
"""
log(c::AbstractConnection, args ...) = log(c[:Logger], args ...)

"""
```julia
mount(fpair::Pair{String, String}) -> ::Route{Connection}/::Vector{Route{Connection}}
```
`mount` will create a route that serves a file or a all files in a directory. 
The first part of `fpair` is the target route path, e.g. `/` would be home. If 
the provided path is as directory, the Function will return a `Vector{AbstractRoute}`. For 
a single file, this will be a route.
```example
module MyServer
using Toolips

logger = Toolips.Logger()

filemount::Route{Connection} = mount("/" => "templates/home.html")

dirmount::Vector{<:AbstractRoute} = mount("/files" => "public")

export filemount, dirmount, logger
end
```
"""
function mount(fpair::Pair{String, String})
    fpath::String = fpair[2]
    target::String = fpair[1]
    if fpath == "."
        fpath = pwd()
    end
    if ~(isdir(fpath))
        if ~(isfile(fpath))
            throw(RouteError{String}(fpair[1], "Unable to mount $(fpair[2]) (not a valid file or directory, or access denied)"))
        end
        return(route(c::AbstractConnection -> begin
            write!(c, File(fpath))
        end, target))::AbstractRoute
    end
    if length(target) == 1
        target = ""
    elseif target[length(target)] == "/"
        target = target[1:length(target)]
    end
    [begin
        route(c::AbstractConnection -> write!(c, File(path)), target * replace(path, fpath => "")) 
    end for path in route_from_dir(fpath)]::Vector{<:AbstractRoute}
end

"""
```julia
route_from_dir(path::String) -> ::Vector{String}
```
This is a (mostly) internal (but also handy) function that reads a directory, and 
    then recursively appends all of the paths in its underlying tree structure. This 
    is used for file mounting in `Toolips`.
```example
module MyServer
using Toolips

logger = Toolips.Logger()

filemount::Route{Connection} = mount("/" => "templates/home.html")

dirmount::Vector{<:AbstractRoute} = mount("/files" => "public")

export filemount, dirmount, logger
end
```
"""
function route_from_dir(path::String)
    dirs::Vector{String} = readdir(path)
    routes::Vector{String} = []
    [begin
        fpath = "$path/" * directory
        if isfile(fpath)
            push!(routes, fpath)
        else
            if ~(directory in routes)
                newrs::Vector{String} = route_from_dir(fpath)
                [push!(routes, r) for r in newrs]
            end
        end
    end for directory in dirs]
    routes::Vector{String}
end

"""
```julia
abstract AbstractHandler <: Any
```
A `handler` is conceptually the same as a `Route` from regular `Toolips`, only 
it does not contain a path, as there is no HTTP, target, or router. A handler is 
exported by a server and loaded just as it is with a regular `WebServer`.
```julia
# consistencies
f::Function
```
- See also: `Handler`, `handler`, `SocketConnection`
"""
abstract type AbstractHandler end

"""
```julia
struct Handler <: AbstractHandler
```
- `f`**::Function**

The most basic form of `AbstractHandler`, the `Handler` is exported from a `Toolips` 
TCP server just as a route is in the context of a web-server and is used to store the 
logical responses of our server. The server works pretty similarly to regular `Toolips`. 
Handlers are normally created via the `handler` function.
```julia
Handler(::Function)
```
example
```julia
module MyServer
using Toolips

main_handler = handler() do c::SocketConnection
    ip_and_port = get_ip4(c)
    write!(c, "connected from" * string(ip_and_port))
end

export main_handler
end

using Toolips; start!(:TCP, MyServer)
```
- See also: `handler`, `write!`, `SocketConnection`, `start!`
"""
struct Handler <: AbstractHandler
    f::Function
end

"""
```julia
handler(f::Function, args ...) -> ::AbstractHandler
```
The `handler` function is a basic API for constructing varieties of `AbstractHandler` 
types. Base `Toolips` (as of `0.3.9`) only includes the regular `Handler`. Handlers 
replace *routes* (`AbstractRoute`) for low-level servers without an HTTP header and 
a regular `Connection`. A handler's provided function will take the `Connection` type 
for that server. For a `TCP` server, this is the `SocketConnection`.
```julia
module TCPServer
using Toolips

main_handler = handler() do c::SocketConnection
    ip_and_port = get_ip4(c)
    write!(c, "connected from" * string(ip_and_port))
end

export main_handler
end
```
Keep in mind that these servers also need to be started with their appropriate `start!` 
binding, by providing their starting `Symbol`. `Toolips` only includes `:TCP` 
(in addition to the default `WebServer` binding) in its base but extensions are 
able to provide more.
```julia
start!(st::ServerTemplate{:TCP}, mod::Module = Main, ip::IP4 = ip4_cli(Main.ARGS), 
    threads::Int64 = 1, async::Bool = false)
```
"""
function handler end

handler(f::Function) = Handler(f)

write!(str::Sockets.TCPSocket, a::Any ...) = write(str, a ...)

"""
```julia
mutable struct SocketConnection <: AbstractConnection
```
- `stream`**::Sockets.TCPSocket**

The `SocketConnection` is the equivalent of the `Connection` for `TCP` servers. To 
create a `TCP` server with `Toolips`, we export a `Handler` in place of a `Route` 
and start the server by providing `:TCP` to `start!`
```julia
SocketConnection(::Sockets.TCPSocket)
```
example
```julia
module MyServer
using Toolips

main_handler = handler() do c::SocketConnection
    message = String(readavailable(c))
    write!(c, "you sent the following message: " * message)
end

export main_handler
end

using Toolips; start!(:TCP, MyServer)
```
- See also: `handler`, `AbstractHandler`, `write!`, `get_ip4`, `start!`
"""
mutable struct SocketConnection <: AbstractConnection
    stream::Sockets.TCPSocket
end

read(s::SocketConnection) = readavailable(s.stream)

"""
```julia
get_ip4(c::AbstractConnection) -> ::IP4
```
Gets the IP *and* port of an active `Connection` in the form of an `IP4`. Note 
that this function is not used for web-servers (which always run on port 80,) for 
    a web-server (or for only the IP,) see `get_ip`. 

(This will not work with normal HTTP Connection types)
```julia
get_ip4(c::SocketConnection)
```
- See also: `get_ip`, `SocketConnection`, `get_headers`, `get_target`, `Connection`, `handler`
"""
function get_ip4 end

function get_ip4(c::AbstractConnection)
    throw("`get_ip4` is not used for HTTP Connections! Use `get_ip` -> ::String")
end

function get_ip4(c::SocketConnection)
    ip_p = Sockets.getpeername(c.stream)
    IP4(string(ip_p[1]), ip_p[2])
end

function get_ip(c::SocketConnection)
    string(Sockets.getpeername(c.stream)[1])
end

function start!(st::ServerTemplate{:TCP}, mod::Module = Main, ip::IP4 = ip4_cli(Main.ARGS), 
    threads::Int64 = 1, async::Bool = false)
    if threads > 1
        @warn "threading for TCP servers not yet implemented, this will be a 0.4+ feature."
    end
    IP = Sockets.InetAddr(parse(IPAddr, ip.ip), ip.port)
    server::Sockets.TCPServer = Sockets.listen(IP)
    handler = nothing
    for name in names(mod)
        f = getfield(mod, name)
        if typeof(f) <: AbstractHandler
            handler = f
            break
        end
    end
    if ~(async)
        while true
		    client = accept(server)
		    conn = SocketConnection(client)
            handler.f(conn)
	    end
        return
    end
    t = @async while true
		client = accept(server)
		conn = SocketConnection(client)
        handler.f(conn)
	end
    main_worker = Worker{Async}("$mod router", rand(1000:3000))
    ProcessManager(main_worker)::ProcessManager
end

function read_all(c::SocketConnection)
    sock = c.stream
    buffer = IOBuffer()
	try
		while isopen(sock)
			n = bytesavailable(sock)
			if n > 0
				data = read(sock, n)
				write(buffer, data)
			else
				yield()
			end
		end
	catch e
		@warn "Error handling connection: $e"
	finally
		close(sock)
	end
    String(take!(buffer))::String
end