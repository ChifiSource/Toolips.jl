#==
Exceptions
==#
abstract type CoreException <: Exception end
abstract type ExtensionException <: CoreException end
abstract type ConnectionException <: CoreException end
"""
"""
mutable struct MissingExtensionError <: ExtensionException
    extension::Type
    f::Function
    function MissingExtensionError(extension::Symbol, f::Function)
        if ~(extension <: ServerExtension)
            throw(ArgumentError("The type provided to exception is not a ServerExtension!"))
        end
        new(extension, f)
    end
end

function showerror(io::IO, e::MissingExtensionError)
    print(io, """Missing Extension Error!
    You are missing the extension $(string(e.extension)), which is required
    by the function $(string(e.f))""")
end

mutable struct ExtensionError <: ExtensionException
    extension::Type
    error::Exception
    function ExtensionError(extension::Type, error::Exception)
        if ~(extension <: ServerExtension)
            throw(ArgumentError("The type provided to exception is not a ServerExtension!"))
        end
        new(extension, error)::ExtensionError
    end
end

function showerror(io::IO, e::ExtensionError)
    print(io, """Extension Error: Loading the extension $(e.extension) raised
                $(e.error)""")
end

mutable struct ConnectionError <: ConnectionException
    connection::AbstractConnection
    route::AbstractRoute
    function ConnectionError(connection::AbstractConnection, route::AbstractRoute)
        new(connection, route)::ConnectionError
    end
end

function warn(c::Connection, e::Exception)
    buff = IOBuffer()
    showerror(buff, e)
    if has_extension(c, :Logger)
        c.logger.log(2, "! Server warning: Error in server \n" * String(buff.data))
    else
        @warn String(buff.data)
    end
end

function warn(e::Exception)
    buff = IOBuffer()
    showerror(buff, e)
    @warn String(buff.data)
end

mutable struct RouteError <: ConnectionException
    route::String
    error::Exception
    RouteError(route::String, error::Exception) = new(route, error)::RouteError
end

function showerror(io::IO, e::RouteError)
    print(io, "Route $(e.route) on server")
end

mutable struct CoreError <: Exception
    message::String
    CoreError(message::String) = new(message)
end

showerror(io::IO, e::CoreError) = print(io, "Toolips Core Error: $(e.message)")

#==
Hash
==#
"""
### Hash
- f::Function - The f function is used to return the Hash's value. \
Creates an anonymous hashing function for a string of length(n). Can be
    indexed with nothing to retrieve Hash.
##### example
```
# 64-character hash
h = Hash(64)          #    vv getindex(::Hash)
buffer = Base.SecretBuffer(hash[])
if String(buffer.data) == "Password"
```
------------------
##### constructors
- Hash(n::Integer = 32)
- Hash(s::String)
"""
struct Hash
    f::Function
    function Hash(n::Integer = 32)
        seed = rand(1:100000000)
        f() = begin
            Random.seed!(seed); randstring(n)
        end
        new(f)
    end
    function Hash(s::String)
        seed = rand(1:100000000)
        f() = begin

        end
        f(inp::String) = begin
            if inp == s

            else

            end
        end
    end
end
#==
Servables
==#
"""
### abstract type Servable
Servables can be written to a Connection via thier f() function and the
interface. They can also be indexed with strings or symbols to change properties
##### Consistencies
- f::Function - Function whose output to be written to http. Must take a single
positonal argument of type ::Connection or ::AbstractConnection
"""
abstract type Servable <: Any end
#==
Connections
==#
"""
### abstract type AbstractConnection
Connections are passed through function routes and can have Servables written
    to it.
##### Consistencies
- routes::Dict - A {String, Function} dictionary that the server references to
direct incoming connections.
- http::Any - Usually an HTTP.Stream, however can be anything that is binded to
the Base.write method.
- extensions::Dict - A {Symbol, ServerExtension} dictionary that can be used to
access ServerExtensions.
"""
abstract type AbstractConnection end

"""
**Core**
### getindex(c::AbstractConnection, s::String) -> ::Function
------------------
Returns the function that corresponds to the route dir s.
#### example
```
c["/"]

    home
```
"""
getindex(c::AbstractConnection, s::String) = c.routes[s]


"""
**Core**
### getindex(c::AbstractConnection, s::Symbol) -> ::ServerExtension
------------------
Indexes the extensions in c.
#### example
```
route("/") do c::Connection
    c[:Logger].log("hi")
end
```
"""
function getindex(c::AbstractConnection, s::Symbol)
    if ~(s in c.extensions)
        getindex(c, eval(s))
    end
    return(c.extensions[s])
end

"""
**Core**
### getindex(c::AbstractConnection, t::Type) -> ::ServerExtension
------------------
Indexes the extensions in c by type.
#### example
```
route("/") do c::Connection
    c[Logger].log("hi")
end
```
"""
function getindex(c::AbstractConnection, t::Type)
    for e in c.extensions
        if e isa t
            return(e)
        end
    end
end

"""
**Core**
### setindex!(c::AbstractConnection, f::Function, s::String) -> _
------------------
Sets the route path s to serve at the function f.
#### example
```
c["/"] = c -> write!(c, "hello")
```
"""
setindex!(c::AbstractConnection, f::Function, s::String) = c.routes[s] = Route(c, f)

"""
**Internals**
### argsplit(args::Vector{AbstractString}) -> ::Dict{Symbol, Any}
------------------
Used by the getargs method to parse GET arguments into a Dict.
#### example
```
argsplit(["c=5", "b=8"])
    Dict(:c => 5, :b => 8)
```
"""
function argsplit(args::Vector{AbstractString})
    arg_dict::Dict = Dict()
    for arg in args
        keyarg = split(arg, '=')
        x = ParseNotEval.parse(keyarg[2])
        push!(arg_dict, Symbol(keyarg[1]) => x)
    end
    return(arg_dict)
end

"""
**Core**
### getargs(c::AbstractConnection) -> ::Dict{Symbol, Any}
------------------
The getargs method returns arguments from the HTTP target (GET requests.)
Returns a Dict with the argument keys as Symbols.
#### example
```
route("/") do c
    args = getargs(c)
    args[:message]
        "welcome to toolips ! :)"
end
```
"""
function getargs(c::AbstractConnection)
    target::String = split(c.http.message.target, '?')[2]
    target = replace(target, "+" => " ")
    args = split(target, '&')
    argsplit(args)
end


"""
**Core**
### getarg(c::AbstractConnection, s::Symbol) -> ::Any
------------------
Returns the requested argument from the target.
#### example
```
getarg(c, :x)
    50
```
"""
function getarg(c::AbstractConnection, s::Symbol)
    getargs(c)[s]
end

"""
**Core**
### getarg(c::AbstractConnection, s::Symbol, t::Type) -> ::Vector
------------------
This method is the same as getargs(::HTTP.Stream, ::Symbol), however types are
parsed as type T(). Note that "Cannot convert..." errors are possible with this
method.
#### example
```
getarg(c, :x, Int64)
    50
```
"""
function getarg(c::AbstractConnection, s::Symbol, T::Type)
    parse(T, getargs(http)[s])
end

"""
**Core**
### getip(c::AbstractConnection) -> ::String
------------------
Returns the IP that is connected via the connection c.
#### example
```
getip(c)
"127.0.0.2"
```
"""
function getip(c::AbstractConnection)
    str = c.http.message["User-Agent"]
    spl = split(str, "/")
    ipstr = ""
    for sub in spl
        if contains(sub, ".")
            if length(findall(".", sub)) > 1
                ipstr = split(sub, " ")[1]
            end
        end
    end
    return(ipstr)
end

"""
**Core**
### getpost(c::AbstractConnection) -> ::String
------------------
Returns the POST body of c.
#### example
```
getpost(c)
"hello, this is a post request"
```
"""
getpost(c::AbstractConnection) = string(read(c.http))

"""
**Internals**
### string(r::Vector{UInt8}) -> ::String
------------------
Turns a vector of UInt8s into a string.
"""
string(r::Vector{UInt8}) = String(UInt8.(r))

"""
**Core**
### download!(c::AbstractConnection, uri::String) -> _
------------------
Downloads a file to a given Connection's computer.
#### example
```
download!(c, "files/mytext.txt")
```
"""
function download!(c::AbstractConnection, uri::String)
    write(c.http, HTTP.Response( 200, body = read(uri, String)))
end

"""
**Core**
### navigate!(::AbstractConnection, ::String) -> _
------------------
Routes a connected stream to a given URL.
#### example
```
navigate!(c, "https://github.com/ChifiSource/Toolips.jl")
```
"""
function navigate!(c::AbstractConnection, url::String)
    HTTP.get(url, response_stream = c.http, status_exception = false)
end
#==
Routes
==#
"""
"""
abstract type AbstractRoute end

"""
### Route
- path::String
- page::Function -
A route is added to a ServerTemplate using either its constructor, or the
ServerTemplate.add(::Route) method. Each route calls a function.
The Route type is commonly constructed using the do syntax with the
route(::Function, ::String) method.
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
##### field info
- path::String - The path to route to the function, e.g. "/".
- page::Function - The function to route the path to.
------------------
##### constructors
- Route(path::String, f::Function)
"""
mutable struct Route <: AbstractRoute
    path::String
    page::Function
    function Route(path::String, f::Function)
        new(path, f)
    end
end

vect(r::AbstractRoute ...) = Vector{AbstractRoute}([x for x in r])
vect(r::Route ...) = Vector{AbstractRoute}([x for x in r])
#==
Server Extensions
==#
"""
### abstract type ServerExtension
Server extensions are loaded into the server on startup, and
can have a few different abilities according to their type
field's value. This value can be either a Symbol or a Vector of Symbols.
##### Consistencies
- type::T where T == Vector{Symbol}  || T == Symbol. The type can be :routing,
:func, :connection, or any combination inside of a Vector{Symbol}. :routing
ServerExtensions must have an f() function that takes two dictionaries; e.g.
f(r::Dict{String, Function}, e::Dict{Symbol, ServerExtension}) The first Dict is
the dictionary of routes, the second is the dictionary of server extensions.
:func server extensions will be ran everytime the server is routed. They will
need to have the same f function, but taking a single argument as a connection.
    Lastly, :connection extensions are simply pushed to the connection.
"""
abstract type ServerExtension end
#==
Servers
==#
"""
### abstract type ToolipsServer
ToolipsServers are returned whenever the ServerTemplate.start() field is
called. If you are running your server as a module, it should be noted that
commonly a global start() method is used and returns this server, and dev is
where this module is loaded, served, and revised.
##### Consistencies
- routes::Dict - The server's route => function dictionary.
- extensions::Dict - The server's currently loaded extensions.
- server::Any - The server, whatever type it may be...
"""
abstract type ToolipsServer end

"""
### WebServer <: ToolipsServer
- host::String
- routes::Dict
- extensions::Dict
- server::Any -
A web-server is given as a return from a ServerTemplate whenever
ServerTemplate.start() is ran. It can be rerouted with route! and indexed
similarly to the Connection, with Symbols representing extensions and Strings
representing routes.
##### example
```
st = ServerTemplate()
ws = st.start()
routes(ws)
...
extensions(ws)
...
route!(ws, "/") do c::Connection
    write!(c, "hello")
end
```
"""
mutable struct WebServer <: ToolipsServer
    host::String
    port::Integer
    routes::Vector{AbstractRoute}
    extensions::Vector{ServerExtension}
    server::Any
    add::Function
    remove::Function
    start::Function
    function WebServer(host::String = "127.0.0.1", port::Integer = 8000;
        routes::Vector{AbstractRoute} = routes(route("/",
        (c::Connection) -> write!(c, p(text = "Hello world!")))),
        extensions::Vector{ServerExtension} = [Logger()])
        server = :inactive
        add::Function, remove::Function = serverfuncdefs(routes, extensions)
        start() = _start(host, port, routes, extensions, server)
        new(host, port, routes, extensions, server, add, remove, start)::WebServer
    end
end

"""
### ServerTemplate
- ip**::String**
- port**::Integer**
- routes**::Vector{AbstractRoute}**
- extensions**::Dict**
- remove**::Function**
- add**::Function**
- start**::Function** -
The ServerTemplate is used to configure a server before
running. These are usually made and started inside of a main server file.
##### example
```
st = ServerTemplate()

webserver = ServerTemplate.start()
```
------------------
##### field info
- ip**::String** - IP the server should serve to.
- port**::Integer** - Port to listen on.
- routes**::Vector{AbstractRoute}** - A vector of routes to provide to the server
- extensions**::Vector{ServerExtension}** - A vector of extensions to load into
the server.
- remove(::Int64)**::Function** - Removes routes by index.
- remove(::String)**::Function** - Removes routes by name.
- remove(::Symbol)**::Function** - Removes extension by Symbol representing
type, e.g. :Logger
- add(::Route ...)**::Function** - Adds the routes to the server.
- add(::ServerExtension ...)**::Function** - Adds the extensions to the server.
- start()**::Function** - Starts the server.
------------------
##### constructors
- ServerTemplate(ip::String = "127.0.0.1", port::Int64 = 8001,
            routes::Vector{AbstractRoute} = Vector{AbstractRoute}());
            extensions::Vector{ServerExtension} = [Logger()]
            connection::Type)
"""
mutable struct ServerTemplate{T <: ToolipsServer} <: ToolipsServer
    ip::String
    port::Integer
    routes::Vector{AbstractRoute}
    extensions::Vector{ServerExtension}
    server::Any
    remove::Function
    add::Function
    start::Function
    function ServerTemplate(host::String = "127.0.0.1", port::Integer = 8000,
        rs::Vector{AbstractRoute} = Vector{AbstractRoute}();
        routes::Vector{AbstractRoute} = routes(route("/",
        (c::Connection) -> write!(c, p(text = "Hello world!")))),
        extensions::Vector{ServerExtension} = Vector{ServerExtension}([Logger()]),
        server::Type = WebServer)
        if length(rs) != 0
            @warn """positional routes for Server templates will be deprecated,
            use ServerTemplate(routes = routes(homeroute)) with routes key-word
            argument instead. This argument is currently vestigal"""
            routes = vcat(routes, rs)
        end
        if ~(server <: ToolipsServer)
            throw(CoreError("Server provided as ServerType is not a ToolipsServer!"))
        end
        servertype = server
        add::Function, remove::Function = serverfuncdefs(routes, extensions)
        server::Any = :none
        start() = _st_start(host, port, routes, extensions, servertype, server)
        new{servertype}(host, port, routes, extensions, server, remove, add, start)::ServerTemplate
    end
end
function consolidate(v::ServerTemplate ...)

end
#==
Connection
==#
"""
**Core**
### has_extension(c::AbstractConnection, t::Type) -> ::Bool
------------------
Checks if c.extensions has an extension of type t.
#### example
```
if has_extension(c, Logger)
    c[:Logger].log("it has a logger, I think.")
end
```
"""
has_extension(c::AbstractConnection, t::Type) = has_extension(c.extensions,
 Symbol(t))

has_extension(c::AbstractConnection, e::Symbol) = has_extension(c.extensions, e)

has_extension(e::Vector{ServerExtension}, s::Type) = has_extension(e, Symbol(s))

"""
**Internals**
### has_extension(d::Dict, t::Type) -> ::Bool
------------------
Checks if d has an extension of type t.
#### example
```
if has_extension(d, Logger)
    d[:Logger].log("it has a logger, I think.")
end
```
"""
function has_extension(es::Vector{ServerExtension}, t::Symbol)
    if t in es
        return(true)
    else
        return(false)
    end
end

#==
Servables
==#
*(s::Servable, d::Servable ...) = servables(s, d ...)

"""
**Core**
### getindex(c::VectorServable, str::String) -> ::Servable
------------------
Returns the Servable (likely a AbstractComponent) with the name **str**
#### example
```
comp1 = p("hello")
comp2 = p("anotherp")
cs = components(comp1, comp2)
cs["hello"]
    AbstractComponent("hello" ...)
```
"""
function getindex(vs::Vector{Servable}, str::String)
    vs[findall(s.name == str, vs)[1]]
end


function getindex(v::Vector{ServerExtension}, t::Type)
    # my god, it's beautiful.
    if ~(t <: ServerExtension)
        throw(ExtensionError(t, ArgumentError("$t is not a ServerExtension!")))
    end
    v[findall((x::ServerExtension) -> typeof(x) == t, v)[1]]::ServerExtension
end

function getindex(v::Vector{ServerExtension}, s::Symbol)
    getindex(v, eval(s))
end

function getindex(v::Vector{AbstractRoute}, s::String)
    v[findall((x::AbstractRoute) -> x.path == s, v)[1]]
end

function in(t::Type, v::Vector{ServerExtension})
    if length(findall(x -> typeof(x) == t, v)) > 0
        return true
    end
    false::Bool
end

function in(t::Symbol, v::Vector{ServerExtension})
    if length(findall(x -> typeof(x) == eval(t), v)) > 0
        return true
    end
    false::Bool
end

function in(t::String, v::Vector{AbstractRoute})
    if length(findall(x -> x.path == t, v)) > 0
        return true
    end
    false::Bool
end

function setindex!(v::Vector{AbstractRoute}, r::AbstractRoute)
    if s in v
        index = findall(x -> x.path == s, v)
        v[index] = Route(s, f)
    else
        push!(v, Route(s, f))
    end
end

keys(v::Vector{AbstractRoute}) = [r.path for r in v]
values(v::Vector{AbstractRoute}) = [r.page for r in v]

#==
Core Server
==#
"""
**Core**
### serverfuncdefs(routes**::AbstractVector**, extensions::Dict) -> add::Function, remove::Function
------------------
This method is a binding to create server functions from your routes and extensions
dictionary.
#### example

"""
function serverfuncdefs(routes::Vector{AbstractRoute}, extensions::Vector{ServerExtension})
    # oo baby what a beautiful function.
    add(r::AbstractRoute ...) = [push!(routes, route) for route in r]
    add(e::ServerExtension ...) = [push!(extensions, ext) for ext in e]
    remove(i::Int64)::Function = deleteat!(routes, i)
    remove(s::String) = deleteat!(findall(routes, r -> r.path == s)[1])
    remove(s::Symbol) = deleteat!(findall(extensions,
                                e -> Symbol(typeof(e)) == s))
    return(add::Function, remove::Function)
end

function _st_start(ip::String, port::Integer, routes::Vector{AbstractRoute},
    extensions::Vector{ServerExtension}, servertype::Type, s::Any)
    server::ToolipsServer = servertype(ip, port, routes = routes,
    extensions = extensions)
    server.start()
    s = server
    return(server)::ToolipsServer
end

"""
**Core - Internals**
### _start(routes::AbstractVector, ip::String, port::Integer,
extensions::Dict, c::Type) -> ::WebServer
------------------
This is an internal function for the ServerTemplate. This function is binded to
    the ServerTemplate.start field.
#### example
```
st = ServerTemplate()
st.start()
```
"""
function _start(ip::String, port::Integer, routes::Vector{AbstractRoute},
     extensions::Vector{ServerExtension}, server::Any)
    server = Sockets.listen(Sockets.InetAddr(parse(IPAddr, ip), port))
     if has_extension(extensions, Logger)
         extensions[:Logger].log(1,
          "Toolips Server starting on port $port")
      else
          @warn "Toolips Server starting on port $port"
     end
     routefunc, rdct, extensions = generate_router(routes, server, extensions)
     try
         @async HTTP.listen(routefunc, ip, port, server = server)
     catch e
         throw(CoreError("Could not start Server $ip:$port; $(string(e))"))
     end
     if has_extension(extensions, Logger)
         extensions[:Logger].log(2,
          "Successfully started server on port $port")
          extensions[:Logger].log(1,
          "You may visit it now at http://$ip:$port")
      else
          @warn "Successfuly started server on port $port"
          @warn "You may visit it now at http://$ip:$port"
     end
end

"""
**Core - Internals**
### generate_router(routes::AbstractVector, server::Any, extensions::Dict,
            conn::Type)
------------------
This method is used internally by the **_start** method. It returns a closure
function that both routes and calls functions.
#### example
```
server = Sockets.listen(Sockets.InetAddr(parse(IPAddr, ip), port))
if has_extension(extensions, Logger)
    extensions[Logger].log(1,
     "Toolips Server starting on port " * string(port))
end
routefunc, rdct, extensions = generate_router(routes, server, extensions,
                                                Connection)
@async HTTP.listen(routefunc, ip, port, server = server)
```
"""
function generate_router(routes::Vector{AbstractRoute}, server::Any,
    extensions::Vector{ServerExtension})
    # Load Extensions
    ces::Vector{ServerExtension} = Vector{ServerExtension}()
    fes::Vector{ServerExtension} = Vector{ServerExtension}()
    for extension in extensions
        if typeof(extension.type) == Symbol
            if extension.type == :connection
                push!(ces, extension)
        elseif extension.type == :routing
            try
                extension.f(routes, extensions)
            catch e
                throw(ExtensionError(typeof(extension), e))
            end
        elseif extension.type == :func
                push!(fes, extension)
        end
        else
            if :connection in extension.type
                push!(ces, extension)
            end
            if :routing in extension.type
                try
                    extension.f(routes, extensions)
                catch e
                    throw(ExtensionError(typeof(extension), e))
                end
            end
            if :func in extension.type
                push!(fes, extension)
            end
        end
    end
    # Routing func
    routeserver::Function = function serve(http::HTTP.Stream)
        fullpath::String = http.message.target
        if contains(http.message.target, "?")
            fullpath = split(http.message.target, '?')[1]
        end
        if fullpath in routes
            try
                [extension.f(c) for extension in fes]
            catch e
                throw(ExtensionError(typeof(extension[2]), e))
            end
            c::AbstractConnection = Connection(routes, http, ces)
            try
                T = methods(routes[fullpath].page)[1].sig
                if length(T.parameters) == 2 && T.parameters[2] != AbstractConnection
                    cT::Type = methods(routes[fullpath])[1].sig.parameters[2]
                    c = cT(routes, http, ces)
                end
            catch

            end
            routes[fullpath].page(c)
            return
        else
            [extension.f(c) for extension in fes]
            try
                routes["404"](c)
                return
            catch
                warn(
                RouteError("404",
                CoreError("Tried to return 404, but there is no \"404\" route.")
                ))
                return
            end
        end
    end # serve()
    return(routeserver, routes, extensions)
end
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
#==
includes
==#
include("../interface/Extensions.jl")
