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
---
- [`interface`]()
- ["Extensions.jl"]()
- ["Components.jl"]()
---
- [`server`]()
- ["Core.jl"]()

"""
module Toolips
using Crayons
using Sockets
using HTTP
using Pkg
using ParseNotEval
using Dates
import Base: getindex, setindex!, push!, get, string, write, show, display, (:)
import Base: showerror, in, Pairs, Exception, div, keys, *, vect
#==
WebMeasures / Colors
==#
abstract type WebMeasure end

mutable struct Px <: WebMeasure end
const px = Px()
*(i::Int64, p::Px) = "$(i)px"

mutable struct Percentage <: WebMeasure end
const percent = Percentage()
*(i::Int64, p::Percentage) = "$(i)%"

rgb(r::Int64, g::Int64, b::Int64) = "rgb($r, $g, $b)"

rgba(r::Int64, g::Int64, b::Int64, a::Int64) = "rgba($r, $g, $b, $a)"

function gradient(type::Symbol = :linear, dir::String, c::String ...)
    "$type-gradient(to $dir, " * join(["$col, " for col in c]) * ")"
end

export percent, px, rgb, rgba, gradient
#==
Includes/Exports
==#
include("server/Core.jl")
include("interface/Components.jl")
# Core
export ServerTemplate, Route, Connection, WebServer, Servable
export Hash
# Server Extensions
export Logger, Files
# Servables
export File, Component
export Animation, Style

export img, link, meta, input, a, p, h, button, ul, li, divider, form, br, i
export title, span, iframe, svg, element, label, script, nav, button, form
export element, label, script, nav, button, form, body, header, section, DOCTYPE
export footer
# High-level api
export push!, getindex, setindex!, properties!, components, has_children
export children, getproperties
export animate!, style!, delete_keyframe!
export route, routes, route!, write!, kill!, unroute!, navigate!
export has_extension
export getargs, getarg, postargs, postarg, get, post, getip, getpost
#==
Project API
==#
"""
**Internals**
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
