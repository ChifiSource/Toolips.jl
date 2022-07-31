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
import Base: showerror, in, Pairs, Exception, div, keys, *, vect, read, cp
#==
WebMeasures / Colors
==#
"""
### WebMeasure{format}
WebMeasures are simple measurement Symbols that are used to create
the `px` and `percent` syntax.
##### example
```
# px/percent examples:
mydiv = div("mydiv", align = "center")
style!(mydiv, "padding" => 15px, "width" => 50percent)
# What this looks like in toolips:
const px = WebMeasure{:px}()
*(i::Int64, p::WebMeasure{:px}) = i * "px"
```
------------------
##### constructors
WebMeasure{format}()
"""
mutable struct WebMeasure{format} end

const px = WebMeasure{:px}()
*(i::Int64, p::WebMeasure{:px}) = "$(i)px"

const percent = WebMeasure{:percent}()
*(i::Int64, p::WebMeasure{:percent}) = "$(i)%"

const seconds = WebMeasure{:seconds}()
*(i::Int64, p::WebMeasure{:seconds}) = "$(i)s"
*(i::Float64, p::WebMeasure{:seconds}) = "$(i)s"
const ms = WebMeasure{:ms}()
*(i::Int64, p::WebMeasure{:ms}) = "$(i)ms"
const pt = WebMeasure{:pt}()
*(i::Int64, p::WebMeasure{:pt}) = "$(i)pt"
"""
**Interface**
### rgb(r::Int64, g::Int64, b::Int64) -> ::String
------------------
Creates a style rgb color.
#### example
```
myp = p("myp", text = "example")
style!(myp, "color" => rgb(1, 5, 9))
```
"""
rgb(r::Int64, g::Int64, b::Int64) = "rgb($r, $g, $b)"

"""
**Interface**
### rgb(r::Int64, g::Int64, b::Int64, a::Int64) -> ::String
------------------
Creates a style rgba color.
#### example
```
myp = p("myp", text = "example")
style!(myp, "color" => rgba(1, 5, 9, 100))
```
"""
rgba(r::Int64, g::Int64, b::Int64, a::Int64) = "rgba($r, $g, $b, $a)"

"""
**Interface**
### gradient(type::Symbol, dir::String = "right", c::String ...) -> ::String
------------------
Creates a style a gradient of type type in direction dir with colors c. Types are
- radial
- linear
#### example
```
mydiv = div("mydiv", text = "example")
style!(mydiv, "background" => gradient(:linear, "right", "blue", "green"))
```
"""
function gradient(type::Symbol, dir::String = "right", c::String ...)
    "$type-gradient(to $dir, " * join(["$col, " for col in c]) * ")"
end

export percent, px, rgb, rgba, gradient, pt, seconds, ms
#==
Includes/Exports
==#
include("server/Core.jl")
include("interface/Components.jl")
# Core
export ServerTemplate, Route, Connection, WebServer, Servable, ServerExtension
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
### create_serverdeps(name::String, exts::Vector{String} = ["Logger"], inc::String = "") -> _
------------------
Creates the essential portions of the webapp file structure, where name is the
project's name and inc is any extensions or strings to incorporate at the top
of the file. Exts is a list of Server extensions.
#### example
```
create_serverdeps("ToolipsApp")
```
"""
function create_serverdeps(name::String, exts::Vector{String} = ["Logger"],
    inc::String = "")
    extstr::String = "Vector{ServerExtension}([" * join(["$e(), " for e in exts]) * "])"
    Pkg.generate(name)
    Pkg.activate(name)
    Pkg.add(url = "https://github.com/ChifiSource/Toolips.jl.git")
    Pkg.add("Revise")
    dir = pwd() * "/"
    src::String = dir * name * "/src"
    if "Logger" in exts
        logs::String = dir * name * "/logs"
        mkdir(logs)
        touch(logs * "/log.txt")
    end
    touch(name * "/dev.jl")
    touch(name * "/prod.jl")
    rm(src * "/$name.jl")
    touch(src * "/$name.jl")
    open(src * "/$name.jl", "w") do io
        write(io, """
module $name
using Toolips
$inc
# welcome to your new toolips project!
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

routes = [route("/", home), fourofour]
extensions = $extstr
\"\"\"
start(IP::String, PORT::Integer, ) -> ::ToolipsServer
--------------------
The start function starts the WebServer.
\"\"\"
function start(IP::String = "127.0.0.1", PORT::Integer = 8000)
     ws = WebServer(IP, PORT, routes = routes, extensions = extensions)
     ws.start(); ws
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
        using Pkg; Pkg.activate(".")
        using Toolips
        using Revise
        using $name

        IP = "127.0.0.1"
        PORT = 8000
        $servername = $name.start(IP, PORT)
        """)
    end
    open(name * "/prod.jl", "w") do io
        write(io, """
        using Pkg; Pkg.activate(".")
        using Toolips
        using $name

        IP = "127.0.0.1"
        PORT = 8000
        $servername = $name.start(IP, PORT)
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
    create_serverdeps(name, ["Logger", "Files", "Session"],
    "using ToolipsSession")
    Pkg.add("ToolipsSession")
    open(name * "/dev.jl", "w") do io
        write(io, """
        using Pkg; Pkg.activate(".")
        using Toolips
        using Revise
        using $name

        IP = "127.0.0.1"
        PORT = 8000
        $servername = $name.start(IP, PORT)
        """)
    end
    open(name * "/prod.jl", "w") do io
        write(io, """
        using Pkg; Pkg.activate(".")
        using Toolips
        using $name

        IP = "127.0.0.1"
        PORT = 8000
        $servername = $name.start(IP, PORT)
        """)
    end
    public = pwd() * "/$name/public"
    mkdir(public)
end

"""
**Core**
### new_defaultapp(::String) -> _
------------------
Adds a toolips project with the standard library (Session, Base64, Markdown, Defaults)
installed. More of a built default project with examples is created.
#### example
```
using Toolips
Toolips.new_defaultapp("ToolipsApp")
```
"""
function new_defaultapp(name::String = "ToolipsApp")
    create_serverdeps(name, ["Logger", "Files", "Session"],
    Pkg.add("ToolipsSession")
    Pkg.add("ToolipsDefaults")
    Pkg.add("ToolipsMarkdown")
    Pkg.add("ToolipsBase64")
    "using ToolipsSession\nusing ToolipsDefaults\nusing ToolipsMarkdown")
    open(name * "/dev.jl", "w") do io
        write(io, """
        using Pkg; Pkg.activate(".")
        using Toolips
        using Revise
        using $name

        IP = "127.0.0.1"
        PORT = 8000
        $servername = $name.start(IP, PORT)
        """)
    end
    open(name * "/prod.jl", "w") do io
        write(io, """
        using Pkg; Pkg.activate(".")
        using Toolips
        using $name

        IP = "127.0.0.1"
        PORT = 8000
        $servername = $name.start(IP, PORT)
        """)
    end
    mkdir(pwd() * "/$name/public")
    cp(@__DIR__ * "/../assets/icon.png", pwd() * "/$name/public/favicon.png", force = true)
    open(name * "/src/$name.jl", "w") do io
        write(io, """module $name
        using Toolips
        using ToolipsSession
        using ToolipsDefaults
        using ToolipsMarkdown
        using ToolipsBase64
        # welcome to your new toolips project!
        myheader = div("myheader", align = "center")
        headerlogo = img("headerlogo", src = "/favicon.png")
        push!(myheader, headerlogo, h("headerlabel", 4, text = "toolips"))

        \"\"\"
        home(c::Connection) -> _
        --------------------
        The home function is served as a route inside of your server by default. To
            change this, view the start method below.
        \"\"\"
        function home(c::Connection)
            styles::Component{:sheet} = sheet("newapp")
            styles[:children][:button]["background-color"] = lineargradient("blue", "lightblue")
            write!(c, styles)
            write!(c, myheader)

            mainbody::Component{:body} = body("mainbody")

        end

        fourofour = route("404") do c
            write!(c, p("404message", text = "404, not found!"))
        end

        routes = [route("/", home), fourofour]
        extensions = [Logger(), Files(), Session()]
        \"\"\"
        start(IP::String, PORT::Integer, ) -> ::ToolipsServer
        --------------------
        The start function starts the WebServer.
        \"\"\"
        function start(IP::String = "127.0.0.1", PORT::Integer = 8000)
             ws = WebServer(IP, PORT, routes = routes, extensions = extensions)
             ws.start(); ws
        end
        end # - module
        """)
    end
end
# --

end
