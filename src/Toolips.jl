"""

"""
module Toolips
#==
~ TODO LIST ~ If you want to help out, you can try implementing the following:
=========================
- TODO Finish docs
- TODO Testing
==#
using Crayons
using Sockets, HTTP, Pkg, ParseNotEval
import Base: getindex, setindex!, push!, get, string

#==
SuperTypes
==#
"""
### abstract type Servable
Servables are components that can be rendered into HTML via thier f()
function with the properties provided in their properties dict.
##### Consistencies
- f::Function - Function whose output to be written to http().
- properties::Dict - The properties of a given Servable. These are written
into the servable on the calling of f().
"""
abstract type Servable <: Any end

"""
"""
abstract type StyleComponent <: Servable end

"""
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
home = route("/") do c
    c[:logger].log("We can index extensions.")
    c.routes["/"] = c::Connection -> write!(c, "rerouting!")
    httpstream = c.http
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
include("../server/Core.jl")
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
