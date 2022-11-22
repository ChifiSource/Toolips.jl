"""
### abstract type AbstractRoute
Abstract Routes are what connect incoming connections to functions. Each route
must have two fields, `path`, and `page`. Path needs to be a String, but that is
about it.
##### Consistencies
- type::T where T == Vector{Symbol}  || T == Symbol
"""
abstract type AbstractRoute end

"""
### abstract type Servable
Servables can be written to a Connection via their f() function and the
interface. They can also be indexed with strings or symbols to change properties
##### Consistencies
- f::Function - Function whose output to be written to http. Must take a single
positonal argument of type ::Connection or ::AbstractConnection
"""
abstract type Servable <: Any end

"""
### abstract type AbstractConnection
Connections are passed through function routes and can have Servables written
    to it.
##### Consistencies
- routes::Dict - A {String, Function} dictionary that the server references to
direct incoming connections.
- http::Any - Usually an HTTP.Stream, however can be anything that is binded to
the Base.write method, or the Toolips.write! method.
- extensions::Dict - A {Symbol, ServerExtension} dictionary that can be used to
access ServerExtensions.
"""
abstract type AbstractConnection end

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

"""
### abstract type ServerExtension
Server extensions are loaded into the server on startup, and
can have a few different abilities according to their type
field's value. This value can be either a Symbol or a Vector of Symbols.
##### Consistencies
- type::T where T == Vector{Symbol}  || T == Symbol. The type can be :routing,
:func, :connection, or any combination inside of a Vector{Symbol}.
- :routing extensions are called once at server creation, and must have
the field `f(r::Vector{AbstractRoute}, e::Vector{ServerExtension})`.
- :func extensions are called each time the server is routed, and must have
the field `f(c::AbstractConnection)`.
- :connection extensions are passed inside of the Connection.
"""
abstract type ServerExtension end

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

#==
Exceptions
==#
"""
### abstract type CoreException
Core Exceptions are thrown whenever a random Core error happens.
##### Consistencies
- type::T where T == Vector{Symbol}  || T == Symbol
"""
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
    print(io, "ERROR ON ROUTE: $(e.route) $(e.error)")
end

mutable struct CoreError <: Exception
    message::String
    CoreError(message::String) = new(message)
end

showerror(io::IO, e::CoreError) = print(io, "Toolips Core Error: $(e.message)")
#==
Connections
==#
"""
### Connection <: AbstractConnection
- routes::Dict
- http::HTTP.Stream
- extensions::Dict
The connection type is passed into route functions and pages as an argument.
This is both for functions, as well as Servable.f() methods. This constructor
    should not be called directly. Instead, it is called by the server and
    passed through the function pipeline. Indexing a Connection will return
        the extension named with that symbol.
##### example
```
                  #  v The Connection
home = route("/") do c::Connection
    c[Logger].log(1, "We can index extensions by type or symbol")
    c[:logger].log(1, "see?")
    c.routes["/"] = c::Connection -> write!(c, "rerouting!")
    httpstream = c.http
    write!(c, "Hello world!")
    myheading::Component = h("myheading", 1, text = "Whoa!")
    write!(c, myheading)
end
```
------------------
##### field info
- **routes::Dict** - A dictionary of routes where the keys
are the routed URL and the values are the functions to
those keys.
- **http::HTTP.Stream** - The stream for this current peer's connection.
- **extensions::Dict** - A dictionary of extensions to load with the
name to reference as keys and the extension as the pair.
------------------
##### constructors
- Connection(routes::Dict, http::HTTP.Stream, extensions::Dict)
"""
mutable struct Connection <: AbstractConnection
    hostname::String
    routes::Vector{AbstractRoute}
    http::HTTP.Stream
    extensions::Vector{ServerExtension}
    function Connection(routes::Vector{AbstractRoute}, http::HTTP.Stream,
        extensions::Vector{ServerExtension}; hostname::String = "")
        new(hostname, routes, http, extensions)::Connection
    end
end
"""
### SpoofStream
- text::String
The SpoofStream allows us to fake a connection by building a SpoofConnection
which will write to the SpoofStream.text field whenever write! is called. This
is useful for testing, or just writing servables into a string.
##### example
```
stream = SpoofStream()
write(stream, "hello!")
println(stream.text)

    hello!
conn = SpoofConnection()
servab = Component()
write!(conn, servab)
```
------------------
##### field info
- text::String - The text written to the stream.
------------------
##### constructors
- SpoofStream()
"""
mutable struct SpoofStream
    text::String
    SpoofStream() = new("")
end

"""
### SpoofConnection <: AbstractConnection
- routes::Dict
- http::SpoofStream
- extensions::Dict -
Builds a fake connection with a SpoofStream. Useful if you want to write
a Servable without a server.
##### example
```
fakec = SpoofConnection()
servable = Component()
# write!(::AbstractConnection, ::Servable):
write!(fakec, servable)
```
------------------
##### field info
- routes::Dict - A dictionary of routes, usually left empty.
- http::SpoofStream - A fake http stream that instead writes output to a string.
- extensions::Dict - A dictionary of extensions, usually empty.
------------------
##### constructors
- SpoofStream(r::Dict, http::SpoofStream, extensions::Dict)
- SpoofStream()
"""
mutable struct SpoofConnection <: AbstractConnection
    routes::Vector{ServerExtension}
    http::SpoofStream
    extensions::Vector{ServerExtension}
    function SpoofConnection(r::Vector{AbstractRoute}, http::Any,
        extensions::Vector{ServerExtension})
        new(r, SpoofStream(), extensions)
    end
    SpoofConnection() = new(Vector{AbstractRoute}(), SpoofStream(),
                                    Vector{ServerExtension}())
end

"""
**Internals**
### write(s::SpoofStream, e::Servable) -> _
------------------
A binding to Base.write that allows one to write a Servable to SpoofStream.text.
#### example
```
s = SpoofStream()
write(s, p("hello"))
println(s.text)
    <p id = "hello"></p>
```
"""
write(c::SpoofStream, s::Servable) = s.f(c)

"""
**Internals**
### write(s::SpoofStream, e::Any) -> _
------------------
A binding to Base.write that allows one to write to SpoofStream.text.
#### example
```
s = SpoofStream()
write(s, "hi")
println(s.text)
    hi
```
"""
write(s::SpoofStream, e::Any) = s.text = s.text * string(e)

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
    for e in c.extensions
        if Symbol(typeof(e)) == s
            return(e)
        end
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
setindex!(c::AbstractConnection, f::Function, s::String) = c.routes[s] = f

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
setindex!(c::AbstractConnection, f::AbstractRoute, s::String) = c.routes[s] = f

function show(io::Base.TTY, c::AbstractConnection)
    display("text/markdown", """### $(typeof(c))
    $(c.routes)
    ---
    $(c.extensions)
    """)
end

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
function argsplit(args::AbstractVector)
    arg_dict::Dict = Dict()
    [begin
        keyarg = split(arg, '=')
        x = ParseNotEval.parse(keyarg[2])
        push!(arg_dict, Symbol(keyarg[1]) => x)
    end for arg in args]
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
    target = split(c.http.message.target, '?')
    if length(target) < 2
        return(Dict{Symbol, Any}())
    end
    target = replace(target[2], "+" => " ")
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
    [begin
        if contains(sub, ".")
            if length(findall(".", sub)) > 1
                ipstr = split(sub, " ")[1]
            end
        end
    end for sub in spl]
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
push!(c::AbstractConnection, data::Any) = write!(c.http, HTTP.Response(200, body = string(data)))
#==
Serving/Routing
==#
"""
**Interface**
### write!(c::AbstractConnection, s::Servable) -> _
------------------
Writes a Servable's return to a Connection's stream. This is usually used in
a routing function or a route where ::Connection is provided as an argument.
#### example
```
serv = p("mycomp", text = "hello")

rt = route("/") do c::Connection
    write!(c, serv)
end
```
"""
write!(c::AbstractConnection, s::Servable) = s.f(c)

"""
**Interface**
### write!(c::AbstractConnection, s::Vector{Servable}) -> _
------------------
Writes all servables in s to c.
#### example
```
c = AbstractComponent()
c2 = AbstractComponent()
comps = components(c, c2)
    Vector{Servable}(AbstractComponent(), AbstractComponent())

write!(c, comps)
```
"""
function write!(c::AbstractConnection, s::Vector{Servable})
    for s::Servable in s
        write!(c, s)
    end
end


"""
**Interface**
### write!(c::AbstractConnection, s::Servable ...) -> _
------------------
Writes Servables as Vector{Servable}
#### example
```
write!(c, p("mycomp", text = "hello!"), p("othercomp", text = "hi!"))
```
"""
write!(c::AbstractConnection, s::Servable ...) = write!(c, Vector{Servable}(s))

"""
**Interface**
### write!(c::AbstractConnection, s::Vector{AbstractComponent}) -> _
------------------
A catch-all for when Vectors are accidentally stored as Vector{Any}.
#### example
```
write!(c, ["hello", p("mycomp", text = "hello!")])
```
"""
function write!(c::AbstractConnection, s::Vector{Any})
    for servable in s
        write!(c, s)
    end
end

"""
**Interface**
### write!(::AbstractConnection, ::Any) -> _
------------------
Attempts to write any type to the Connection's stream.
#### example
```
d = 50
write!(c, d)
```
"""
write!(c::AbstractConnection, s::Any) = write(c.http, s)

"""
**Interface**
### startread!(::AbstractConnection) -> _
------------------
Resets the seek on the Connection. This function is only meant to be used on
post bodies.
#### example
```
post = getpost(c)
    "hello"
post = getpost(c)
    ""
startread!(c)
post = getpost(c)
    "hello"
```
"""
startread!(c::AbstractConnection) = startread(c.http)

"""
**Interface**
### route!(c::AbstractConnection, route::Route) -> _
------------------
Modifies the route on the Connection.
#### example
```
route("/") do c::Connection
    r = route("/") do c::Connection
        write!(c, "hello")
    end
    route!(c, r)
end
```
"""
route!(c::AbstractConnection, route::AbstractRoute) = push!(c.routes, route.path => route.page)

"""
**Interface**
### unroute!(::AbstractConnection, ::String) -> _
------------------
Removes the route with the key equivalent to the String.
#### example
```
# One request will kill this route:
route("/") do c::Connection
    unroute!(c, "/")
end
```
"""
unroute!(c::AbstractConnection, r::String) = delete!(c.routes, r)

"""
**Interface**
### route!(::Function, ::AbstractConnection, ::String) -> _
------------------
Routes a given String to the Function.
#### example
```
route("/") do c
    route!(c, "/") do c
        println("tacos")
    end
end
```
"""
route!(f::Function, c::AbstractConnection, route::String) = push!(c.routes, route => f)

"""
**Interface**
### routes(c::Connection) -> ::Dict{String, Function}
------------------
Returns the server's routes.
#### example
```
route("/") do c::Connection
    routes(c)
end
```
"""
routes(c::AbstractConnection) = c.routes

"""
**Interface**
### extensions(c::Connection) -> ::Dict{Symbol, ServerExtension}
------------------
Returns the server's extensions.
#### example
```
route("/") do c::Connection
    extensions(c)
end
```
"""
extensions(c::AbstractConnection) = c.extensions
#==
Routes
==#
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

"""
**Interface**
### route(f::Function, r::String) -> ::Route
------------------
Creates a route from the Function. The function should take a Connection or
AbstractConnection as a single positional argument.
#### example
```
route("/") do c::Connection

end
```
"""
route(f::Function, r::String) = Route(r, f)::Route

"""
**Interface**
### route(r::String, f::Function) -> ::Route
------------------
Creates a route from the Function. The function should take a Connection or
AbstractConnection as a single positional argument.
#### example
```
function example(c::Connection)
    write!(c, h("myh", 1, text = "hello!"))
end
r = route("/", example)
```
"""
route(r::String, f::Function) = Route(r, f)::Route

"""
**Interface**
### routes(::Route ...) -> ::Vector{Route}
------------------
Turns routes provided as arguments into a Vector{Route} with indexable routes.
This is useful because this is the type that the ServerTemplate constructor
likes. This function is also used as a "getter" for ToolipsServers and Connections,
see ?(routes(::ToolipsServer)) & ?(routes(::AbstractConnection))
#### example
```
r1 = route("/") do c::Connection
    write!(c, "pickles")
end
r2 = route("/pickles") do c::Connection
    write!(c, "also pickles")
end
rts = routes(r1, r2)
```
"""
routes(rs::AbstractRoute ...) = Vector{AbstractRoute}([r for r in rs])

function show(io::IO, r::AbstractRoute)
    print(io, "route: $(r.path)\n")
end

vect(r::AbstractRoute ...) = Vector{AbstractRoute}([x for x in r])
vect(r::Route ...) = Vector{AbstractRoute}([x for x in r])

"""
**Interface**
### setindex!(rs::Vector{AbstractRoute}, f::Function, s::String)
------------------
Sets a given route in a Vector to a function.
#### example
```
function example(c::Connection)
    write!(c, h("myh", 1, text = "hello!"))
end
r = route("/", example)
rts = [r]
rts["/"] = (c::Connection) -> write!(c, p(text = "no longer a heading"))
```
"""
function setindex!(rs::Vector{AbstractRoute}, f::Function, s::String)
    if s in rs
        rs[findall(r -> r.path == s, rs)[1]].page = f
    else
        push!(rs, Route(s, f))
    end
end
#==
Servers
==#
"""
### WebServer <: ToolipsServer
- host**::String**
- routes**::Dict**
- extensions**::Dict**
- server**::Any**
- add**::Function**
- remove**::Function**
- start**::Function**\n
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
    hostname::String
    host::String
    port::Int64
    routes::Vector{AbstractRoute}
    extensions::Vector{ServerExtension}
    server::Sockets.TCPServer
    add::Function
    remove::Function
    start::Function
    function WebServer(host::String = "127.0.0.1", port::Integer = 8000;
        hostname::String = "",
        routes::Vector{AbstractRoute} = routes(route("/",
        (c::Connection) -> write!(c, p(text = "Hello world!")))),
        extensions::Vector{ServerExtension} = [Logger()])
        if hostname == ""
            hostname = host
        end
        server::Sockets.TCPServer = Sockets.listen(Sockets.InetAddr(
        parse(IPAddr, host), port))
        add::Function, remove::Function = serverfuncdefs(routes, extensions)
        start() = _start(host, port, routes, extensions, server, hostname)
        new(hostname, host, port, routes, extensions, server,
        add, remove, start)::WebServer
    end
end

"""
### ServerTemplate
- host**::String**
- port**::Integer**
- routes**::Vector{AbstractRoute}**
- extensions**::Vector{ServerExtension}**
- remove**::Function**
- add**::Function**
- start**::Function**\n
The ServerTemplate is used to configure a server before
running. These are commonly used for reproducibility, especially when it comes
to making servers from extensions
- **DEPRECATION WARNING** The `ServerTemplate` will eventually be deprecated and
replaced solely with the `WebServer` type from toolips.
##### example
```
home(c::Connection) = begin
    write!(c, p(text = "hello world!"))
end

st = ServerTemplate("127.0.0.1", 8000, routes = [Route("/", home)])

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
    hostname::String
    host::String
    port::Int64
    routes::Vector{AbstractRoute}
    extensions::Vector{ServerExtension}
    server::Vector{Any}
    remove::Function
    add::Function
    start::Function
    function ServerTemplate(host::String = "127.0.0.1", port::Integer = 8000,
        rs::Vector{AbstractRoute} = Vector{AbstractRoute}();
        hostname::String = "",
        routes::Vector{AbstractRoute} = Vector{AbstractRoute}(),
        extensions::Vector{ServerExtension} = Vector{ServerExtension}([Logger()]),
        servertype::Type = WebServer)
        routes = vcat(routes, rs)
        if ~(servertype <: ToolipsServer)
            throw(CoreError("Server provided as ServerType is not a ToolipsServer!"))
        end
        if hostname == ""
            hostname = host
        end
        add::Function, remove::Function = serverfuncdefs(routes, extensions)
        server::Vector{Any} = Vector{Any}([])
        start() = begin
            push!(server, _st_start(host, port, routes, extensions, servertype,
            server, hostname))
        end
        new{servertype}(hostname, host, port, routes, extensions, server,
        remove, add, start)::ServerTemplate
    end
end
"""
**Interface**
### routes(ws::ToolipsServer) -> ::Dict{String, Function}
------------------
Returns the server's routes.
#### example
```
ws = MyProject.start()
routes(ws)
    "/" => home
    "404" => fourohfour
```
"""
routes(ws::ToolipsServer) = ws.routes



"""
**Interface**
### extensions(ws::ToolipsServer) -> ::Dict{Symbol, ServerExtension}
------------------
Returns the server's extensions.
#### example
```
ws = MyProject.start()
extensions(ws)
    Logger(blah blah blah)
```
"""
extensions(ws::ToolipsServer) = ws.extensions
#==
    Server
==#
"""
**Interface**
### kill!(ws::ToolipsServer) -> _
------------------
Closes the web-server.
#### example
```
ws = MyProject.start()
kill!(ws)
```
"""
function kill!(ws::ToolipsServer)
    close(ws.server[1])
    ws.server = :inactive
    deleteat!(ws.server, 1)
end

function kill!(ws::ServerTemplate{<:ToolipsServer})
    kill!(ws.server[1])
    ws.server = :inactive
    deleteat!(ws.server, 1)
end

"""
**Interface**
### route!(f::Function, ws::ToolipsServer, r::String) -> _
------------------
Reroutes a server's route r to function f.
#### example
```
ws = MyProject.start()
route!(ws, "/") do c
    c[:Logger].log("rerouted!")
end
```
"""
function route!(f::Function, ws::ToolipsServer, r::String)
    ws.routes[r] = f
end

"""
**Interface**
### route!(ws::ToolipsServer, r::String, f::Function) -> _
------------------
Reroutes a server's route r to function f.
#### example
```
ws = MyProject.start()

function myf(c::Connection)
    write!(c, "pasta")
end
route!(ws, "/", myf)
```
"""
route!(ws::ToolipsServer, r::String, f::Function) = route!(f, ws, r)

"""
**Interface**
### route!(ws::ToolipsServer, r::Route) -> _
------------------
Reroutes a server's route r.
#### example
```
ws = MyProject.start()
r = route("/") do c

end
route!(ws, r)
```
"""
route!(ws::ToolipsServer, r::AbstractRoute) = ws[r.path] = r.page

"""
**Interface**
### getindex(ws::ToolipsServer, s::Symbol) -> ::ServerExtension
------------------
Indexes the extensions in ws.
#### example
```
ws = MyProject.start()
ws[:Logger].log("hi")
```
"""
function getindex(ws::ToolipsServer, s::Symbol)
    ws.extensions[s]
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
    vs[findall((s::Servable) -> s.name == str, vs)[1]]
end


function getindex(v::Vector{ServerExtension}, t::Type)
    # my god, it's beautiful.
    if ~(t <: ServerExtension)
        throw(ExtensionError(t, ArgumentError("$t is not a ServerExtension!")))
    end
    v[findall((x::ServerExtension) -> typeof(x) == t, v)[1]]::ServerExtension
end

function getindex(v::Vector{ServerExtension}, s::Symbol)
    findse(x::ServerExtension) = begin
    t = string(typeof(x))
    name = t
    if contains(t, ".")
        splt = split(t, ".")
        name = splt[length(splt)]
    end
    Symbol(name) == s
    end
    v[findfirst(findse, v)]
end

vect(r::ServerExtension ...) = Vector{ServerExtension}([x for x in r])

function getindex(v::Vector{AbstractRoute}, s::String)
    v[findall((x::AbstractRoute) -> x.path == s, v)[1]]
end

function getindex(v::Vector{<:AbstractRoute}, s::String)
    v[findfirst((x::AbstractRoute) -> x.path == s, v)]
end

function in(t::Type, v::Vector{ServerExtension})
    if length(findall(x -> typeof(x) == t, v)) > 0
        return true
    end
    false::Bool
end

function in(t::Symbol, v::Vector{ServerExtension})
    if length(findall(x -> Symbol(typeof(x)) == Symbol(t), v)) > 0
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

function setindex!(v::Vector{AbstractRoute}, r::AbstractRoute, s::String)
    if s in v
        index = findall(x -> x.path == s, v)[1]
        v[index] = r
    else
        push!(v, r)
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
    extensions::Vector{ServerExtension}, servertype::Type, s::Any, hostname::String)
    server::ToolipsServer = servertype(ip, port, routes = routes,
    extensions = extensions, hostname = hostname)
    server.start()
    return(server)::ToolipsServer
end

function show(io::IO, ts::ToolipsServer)
    status::String = "inactive"
    if length(ts.server) > 0
        status = "active"
    end
    print("""$(typeof(ts))
        hosted at: http://$(ts.host):$(ts.port)
        status: $status
            routes
            $(string(ts.routes))
            extensions
            $(string(ts.extensions))
        """)
end

function show(io::IO, ts::ServerTemplate)
    status::String = "inactive"
    if length(ts.server) > 0
        status = "active"
    end
    print("""$(typeof(ts))
        hosted at: http://$(ts.host):$(ts.port)
        status: $status
            routes
            $(string(ts.routes))
            extensions
            $(string(ts.extensions))
        """)
end

function show(io::IO, c::AbstractConnection)
    print("""#### $(typeof(c))
        routes
        $(c.routes)
        extensions
        $(c.extensions)
        """)
end
string(c::Vector{AbstractRoute}) = join([r.path * "\n" for r in c])
function show(IO::IO, c::Vector{AbstractRoute})
    print(string(c))
end
string(c::Vector{ServerExtension}) = join([string(typeof(e)) * "\n" for e in c])
function show(IO::IO, c::Vector{ServerExtension})
    print(string(c))
end

display(ts::ToolipsServer) = show(ts)
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
     extensions::Vector{ServerExtension}, server::Any, hostname::String)
     routefunc, rdct, extensions = generate_router(routes, server, extensions,
     hostname)
     try
         @async HTTP.listen(routefunc, ip, port, server = server)
     catch e
         throw(CoreError("Could not start Server $ip:$port\n $(string(e))"))
     end
     server
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
    extensions::Vector{ServerExtension}, hostname::String)
    # Load Extensions
    ces::Vector{ServerExtension} = Vector{ServerExtension}()
    fes::Vector{ServerExtension} = Vector{ServerExtension}()
    [begin
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
    end for extension in extensions]
    # Routing func
    routeserver::Function = function serve(http::HTTP.Stream)
        fullpath::String = http.message.target
        if contains(http.message.target, "?")
            fullpath = split(http.message.target, '?')[1]
        end
        c = Connection(routes, http, ces, hostname = hostname)
        if fullpath in routes
            [extension.f(c) for extension in fes]
            routes[fullpath].page(c)
        else
            routes["404"].page(c)
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
