module Toolips
clone(name::String = ""; args ...) = Component(name, "clone", args)::Component
#==
~ TODO LIST ~ If you want to help out, you can try implementing the following:
=========================
- TODO Finish docs
- TODO Testing
==#
using Crayons
using Sockets, HTTP, Pkg
import Base: getindex, setindex!, push!
include("interface/Servables.jl")
include("interface/Interface.jl")
# Core Server
export ServerTemplate, Route, Connection, WebServer
# Server Extensions
export Logger, Files
# Servables
export File, Component
export img, link, meta, input, a, p, h, button, ul, li, divider, form, br
export header
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
    servername = name * "Server"
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


function start(IP::String, PORT::String, extensions::Dict)
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
    open(name * "/dev.jl", "w") do io
        write(io, """
        using Pkg; Pkg.activate(".")
        using Toolips
        IP = "127.0.0.1"
        PORT = 8000
        extensions = Dict(:logger => Logger())
        include("src/$name.jl")
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
        include("src/$name.jl")
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
    create_serverdeps(name)
    open(name * "/dev.jl", "w") do io
        write(io, """
        using Toolips
        IP = "127.0.0.1"
        PORT = 8000
        extensions = Dict(:logger => Logger(), :public => Files("public"))
        include("src/$name.jl")
        $servername = $name.start(IP, PORT, extensions)
        """)
    end
    open(name * "/prod.jl", "w") do io
        write(io, """
        using Toolips
        IP = "127.0.0.1"
        PORT = 8000
        extensions = Dict(:logger => Logger(), :public => Files("public"))
        include("src/$name.jl")
        $servername = $name.start(IP, PORT, extensions)
        """)
    end
    public = pwd() * "/$name/public"
    mkdir(public)
#    Pkg.add(url = "https://github.com/ChifiSource/Toolips.jl.git")
end
export new_webapp, new_app
# --

end
