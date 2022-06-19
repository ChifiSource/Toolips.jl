"""
Created in February, 2022 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
by team
[toolips](https://github.com/orgs/ChifiSource/teams/toolips)
This software is MIT-licensed.
### Toolips
**Toolips.jl** is a **fast**, **asynchronous**, **low-memory**, **full-stack**,
and **reactive** web-development framework **always** written in **pure** Julia.
##### Module Composition
- [**Toolips**](https://github.com/ChifiSource/Toolips.jl)
"""
module Toolips
using Crayons
using Sockets, HTTP, Pkg, ParseNotEval, Dates
import Base: getindex, setindex!, push!, get, string, write, show, display
#==
SuperTypes
==#
"""
### abstract type Servable
Servables can be written to a Connection via thier f() function and the
interface. They can also be indexed with strings or symbols to change properties
##### Consistencies
- f::Function - Function whose output to be written to http().
"""
abstract type Servable <: Any end

"""
### abstract type StyleComponent <: Servable
No different from a normal Servable, simply an abstract type step for the
interface to separate working with Animations and Styles.
### Servable Consistencies
```
Servables can be written to a Connection via thier f() function and the
interface. They can also be indexed with strings or symbols to change properties
##### Consistencies
- f::Function - Function whose output to be written to http().
```
"""
abstract type StyleComponent <: Servable end

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
### abstract type ServerExtension
Server extensions are loaded into the server on startup, and
can have a few different abilities according to their type
field's value. This value can be either a Symbol or a Vector of Symbols.
##### Consistencies
- type::T where T == Vector{Symbol}  || T == Symbol
"""
abstract type ServerExtension end

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
### SpoofStream
- text::String \
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
**Core**
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
### SpoofConnection <: AbstractConnection
- routes::Dict
- http::SpoofStream
- extensions::Dict \
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
    routes::Dict
    http::SpoofStream
    extensions::Dict
    function SpoofConnection(r::Dict, http::SpoofStream, extensions::Dict)
        new(r, SpoofStream(), extensions)
    end
    SpoofConnection() = new(Dict(), SpoofStream(), Dict())
end
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
    routes::Dict
    http::HTTP.Stream
    extensions::Dict
    function Connection(routes::Dict, http::HTTP.Stream, extensions::Dict)
        new(routes, http, extensions)::Connection
    end
end

#==
Includes/Exports
==#
include("interface/Servables.jl")
include("server/Core.jl")
include("interface/Interface.jl")

# Core Server
export ServerTemplate, Route, Connection, WebServer, Servable
# Server Extensions
export Logger, Files
# Servables
export File, Component
export Animation, Style

export img, link, meta, input, a, p, h, button, ul, li, divider, form, br, i
export title, span, iframe, svg, element, label, script, nav, button, form
export element, label, script, nav, button, form
# High-level api
export push!, getindex, setindex!, properties!, components, has_children
export animate!, style!, delete_keyframe!
export route, routes, route!, write!, kill!, unroute!, navigate!
export has_extension
export getargs, getarg, postargs, postarg, get, post, getip, getpost
#==
Project API
==#
"""
**Core**
### create_serverdeps(name::String, inc::String) -> _
------------------
Creates the essential portions of the webapp file structure, where name is the
project's name and inc is any extensions or strings to incorporate at the top
of the file.
#### example
```
create_serverdeps("ToolipsApp")
```
"""
function create_serverdeps(name::String, inc::String = "")
    Pkg.generate(name)
    Pkg.activate(name)
    Pkg.add(url = "https://github.com/ChifiSource/Toolips.jl.git")
    Pkg.add("Revise")
    dir = pwd() * "/"
    src = dir * name * "/src"
    logs = dir * name * "/logs"
    mkdir(logs)
    touch(name * "/dev.jl")
    touch(name * "/prod.jl")
    touch(logs * "/log.txt")
    rm(src * "/$name.jl")
    touch(src * "/$name.jl")
    open(src * "/$name.jl", "w") do io
        write(io, """
module $name
using Toolips
$inc

\"\"\"
home(c::Connection) -> _
--------------------
The home function is served as a route inside of your server by default. To
    change this, view the start method below.
\"\"\"
function home(c::Connection)
    write!(c, p("helloworld", text = "hello world!"))
end

fourofour = route("404") do c
    write!(c, p("404message", text = "404, not found!"))
end

\"\"\"
start(IP::String, PORT::Integer, extensions::Vector{Any}) -> ::Toolips.WebServer
--------------------
The start function comprises routes into a Vector{Route} and then constructs
    a ServerTemplate before starting and returning the WebServer.
\"\"\"
function start(IP::String = "127.0.0.1", PORT::Integer = 8000,
    extensions::Vector = [Logger()])
    rs = routes(route("/", home), fourofour)
    server = ServerTemplate(IP, PORT, rs, extensions = extensions)
    server.start()
end

end # - module
        """)
    end

end

"""
**Core**
### new_app(::String) -> _
------------------
Creates a minimalistic app, usually used for creating APIs and endpoints.
#### example
```
using Toolips
Toolips.new_app("ToolipsApp")
```
"""
function new_app(name::String = "ToolipsApp")
    create_serverdeps(name)
    servername = name * "Server"
    open(name * "/dev.jl", "w") do io
        write(io, """
        #==
        dev.jl is an environment file. This file loads and starts servers, and
        defines environmental variables, setting the scope a lexical step higher
        with modularity.
        ==#
        using Pkg; Pkg.activate(".")
        using Toolips
        using Revise
        using $name

        IP = "127.0.0.1"
        PORT = 8000
        extensions = [Logger()]
        $servername = $name.start(IP, PORT, extensions)
        """)
    end
    open(name * "/prod.jl", "w") do io
        write(io, """
        using Pkg; Pkg.activate(".")
        using Toolips
        using $name

        IP = "127.0.0.1"
        PORT = 8000
        extensions = [Logger()]
        $servername = $name.start(IP, PORT, extensions)
        """)
    end
end

"""
**Core**
### new_webapp(::String) -> _
------------------
Creates a fully-featured Toolips web-app. Adds ToolipsSession, ideal for
full-stack web-sites.
#### example
```
using Toolips
Toolips.new_webapp("ToolipsApp")
```
"""
function new_webapp(name::String = "ToolipsApp")
    servername = name * "Server"
    create_serverdeps(name, "using ToolipsSession")
    Pkg.add(url = "https://github.com/ChifiSource/ToolipsSession.jl.git")
    open(name * "/dev.jl", "w") do io
        write(io, """
        #==
        dev.jl is an environment file. This file loads and starts servers, and
        defines environmental variables.
        ==#
        using Pkg; Pkg.activate(".")
        using Toolips
        using ToolipsSession
        using Revise
        using $name

        IP = "127.0.0.1"
        PORT = 8000
        #==
        Extension description
        Logger -> Logs messages into both a file folder and the terminal.
        Files -> Routes the files from the public directory.
        Session -> ToolipsSession; allows us to make Servables reactive. See ?(on)
        ==#
        extensions = [Logger(), Files("public"), Session()]
        $servername = $name.start(IP, PORT, extensions)
        """)
    end
    open(name * "/prod.jl", "w") do io
        write(io, """
        using Pkg; Pkg.activate(".")
        using Toolips
        using ToolipsSession
        using $name

        IP = "127.0.0.1"
        PORT = 8000
        extensions = [Logger(), Files("public"), Session()]
        $servername = $name.start(IP, PORT, extensions)
        """)
    end
    public = pwd() * "/$name/public"
    mkdir(public)
end
# --

end
