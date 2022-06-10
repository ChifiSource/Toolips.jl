module Toolips
#==
Toolips.jl, a module created for light-weight interaction with Javascript via
bursts of HTML and Javascript working in tandem. There might be entirely new
intentions for this design, and dramatic changes. There are numerous features
coming to spruce up this code base to better facilitate things like
authentication.
~ TODO LIST ~ If you want to help out, you can try implementing the following:
=========================
- TODO Load environment in default files
- TODO Setup the Pkg environment with the given loaded files
- TODO Finish docs
- TODO Testings
==#
using Crayons
using Sockets, HTTP, Pkg
import Base: getindex, setindex!, push!
include("interface/Servables.jl")
include("interface/Interface.jl")
# Core Server
export ServerTemplate, Route, Connection
# Server Extensions
export Logger, Files
# Function returns
export html, css, js, fn
# Servables
export File, Component, Container
export input, textarea, button, p, option, radioinput, sliderinput, imageinput
export form, link, metadata, header, div, body, img, h
export Animation, Style, StyleSheet
# High-level api
export properties, push!, getindex, setindex!, properties!
export animate!, style!, keyframe!, delete_keyframe!, @keyframe!
export route, routes, route!, write!, stop!, unroute!, navigate!, stop!
export getargs, getarg, postargs, postarg, get, post

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
function main(routes::Vector{Route})
    server = ServerTemplate(IP, PORT, routes, extensions = extensions)
    server.start()
end
\n
hello_world = route("/") do c
    write!(c, p("hello", text = "hello world!"))
end
fourofour = route("404", p("404", text = "404, not found!"))
rs = routes(hello_world, fourofour)
main(rs)

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
    open(name * "/dev.jl", "w") do io
        write(io, """
        using Toolips
        IP = "127.0.0.1"
        PORT = 8000
        extensions = Dict(:logger => Logger())
        include("src/$name.jl")
        """)
    end
    open(name * "/prod.jl", "w") do io
        write(io, """
        using Toolips
        IP = "127.0.0.1"
        PORT = 8000
        extensions = Dict(:logger => Logger())
        include("src/$name.jl")
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
    create_serverdeps(name)
    open(name * "/dev.jl", "w") do io
        write(io, """
        using Toolips
        IP = "127.0.0.1"
        PORT = 8000
        extensions = Dict(:logger => Logger(), :public => Files("public"))
        include("src/$name.jl")
        """)
    end
    open(name * "/prod.jl", "w") do io
        write(io, """
        using Toolips
        IP = "127.0.0.1"
        PORT = 8000
        extensions = Dict(:logger => Logger(), :public => Files("public"))
        include("src/$name.jl")
        """)
    end
    public = pwd() * "/$name/public"
    mkdir(public)
#    Pkg.add(url = "https://github.com/ChifiSource/Toolips.jl.git")
end
export new_webapp, new_app
# --

end
