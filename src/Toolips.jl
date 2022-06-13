"""
Created in June, 2022 by
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
import Base: getindex, setindex!, push!, get, string
#==
SuperTypes
==#
"""
### abstract type Servable
Servables can be written to a Connection via thier f() function and the
interface. They can also be indexed with strings or symbols to change properties
##### Consistencies
- f::Function - Function whose output to be written to http().
- properties::Dict - The properties of a given Servable. These are written
into the servable on the calling of f().
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
- properties::Dict - The properties of a given Servable. These are written
into the servable on the calling of f().
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
field's value. There are three types to be aware of.
-
##### Consistencies

"""
abstract type ServerExtension end


"""
### Connection
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
    c[Logger].log("We can index extensions.")
    c.routes["/"] = c::Connection -> write!(c, "rerouting!")
    httpstream = c.http
    write!(c, "Hello world!")
    myheading::Component = h("myheading", 1, text = "Whoa!")
    write!(c, myheading)
end
```
------------------
##### Field Info
- **routes::Dict** - A dictionary of routes where the keys
are the routed URL and the values are the functions to
those keys.
- **http::HTTP.Stream** - The stream for this current peer's connection.
- **extensions::Dict** - A dictionary of extensions to load with the
name to reference as keys and the extension as the pair.
------------------
##### Constructors
- Connection
"""
mutable struct Connection
    routes::Dict
    http::HTTP.Stream
    extensions::Dict
    function Connection(routes::Dict, http::HTTP.Stream,extensions::Dict)
        new(routes, http, extensions)::Connection
    end
end

include("interface/Servables.jl")
include("server/Core.jl")
include("interface/Interface.jl")

# Core Server
export ServerTemplate, Route, Connection, WebServer
# Server Extensions
export Logger, Files, Document
# Servables
export File, Component
export Animation, Style

export img, link, meta, input, a, p, h, button, ul, li, divider, form, br, i
export title, span, iframe, svg, element, label, script, nav, button, form
export element, label, script, nav, button, form
# High-level api
export push!, getindex, setindex!, properties!, components
export animate!, style!, keyframe!, delete_keyframe!, @keyframe!
export route, routes, route!, write!, stop!, unroute!, navigate!, stop!
export has_extension
export getargs, getarg, postargs, postarg, get, post, getip

"""
### create_serverdeps(::String) -> _
------------------
Creates the essential portions of the webapp file structure.
#### example

"""
function create_serverdeps(name::String)
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

hello_world = route("/") do c
    write!(c, p("helloworld", text = "hello world!"))
end

fourofour = route("404") do c
    write!(c, p("404message", text = "404, not found!"))
end


function start(IP::String, PORT::Integer, extensions::Dict)
    rs = routes(hello_world, fourofour)
    server = ServerTemplate(IP, PORT, rs, extensions = extensions)
    server.start()
end

end # - module
        """)
    end

end

"""
### new_app(::String) -> _
------------------
Creates a minimalistic app, usually used for creating endpoints -- but can
be used for anything. For an app with a real front-end, it might make sense to
add some extensions.
#### example

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

        IP = "127.0.0.1"
        PORT = 8000
        extensions = Dict(:logger => Logger())
        using $name
        $servername = $name.start(IP, PORT, extensions)
        """)
    end
    open(name * "/prod.jl", "w") do io
        write(io, """
        using Pkg; Pkg.activate(".")
        using Toolips

        IP = "127.0.0.1"
        PORT = 8000
        extensions = Dict(:logger => Logger())
        using $name
        $servername = $name.start(IP, PORT, extensions)
        """)
    end
end

"""
### new_webapp(::String) -> _
------------------
Creates a fully-featured web-app. Adds CanonicalToolips.jl to provide more
high-level interface origrannubg from Julia.
#### example

"""
function new_webapp(name::String = "ToolipsApp")
    servername = name * "Server"
    create_serverdeps(name)
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

        IP = "127.0.0.1"
        PORT = 8000
        #==
        Extension description
        :logger -> Logs messages into both a file folder and the terminal.
        :public -> Routes the files from the public directory.
        :document -> Registers and performs do calls, allows to modify servable.
        ==#
        extensions = Dict(:logger => Logger(), :public => Files("public"),
        :document => Document())
        using $name
        $servername = $name.start(IP, PORT, extensions)
        """)
    end
    open(name * "/prod.jl", "w") do io
        write(io, """
        using Pkg; Pkg.activate(".")
        using Toolips

        IP = "127.0.0.1"
        PORT = 8000
        extensions = Dict(:logger => Logger(), :public => Files("public"))
        using $name
        $servername = $name.start(IP, PORT, extensions)
        """)
    end
    public = pwd() * "/$name/public"
    mkdir(public)
end
# --

end
