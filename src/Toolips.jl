module Toolips
clone(name::String = ""; args ...) = Component(name, "clone", args)::Component
#==
~ TODO LIST ~ If you want to help out, you can try implementing the following:
=========================
- TODO Finish docs
- TODO Testing
==#
using Crayons
using Sockets, HTTP, Pkg, JSON, ParseNotEval
import Base: getindex, setindex!, push!, get
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
export Animation, Style
# High-level api
export push!, getindex, setindex!, properties!, components
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
        using Toolips
        using Revise

        IP = "127.0.0.1"
        PORT = 8000
        extensions = Dict(:logger => Logger(), :public => Files("public"))
        using $name
        $servername = $name.start(IP, PORT, extensions)
        """)
    end
    open(name * "/prod.jl", "w") do io
        write(io, """
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
