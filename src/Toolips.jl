"""
#### toolips - a manic web-development framework
Created in February, 2022 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
- This software is MIT-licensed.
### Toolips
**Toolips.jl** is a **fast**, **asynchronous**, **low-memory**, **full-stack**,
and **reactive** web-development framework **always** written in **pure** Julia.
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

function getindex(mod::Module, field::Symbol)
    getfield(mod, field)
end

function getindex(mod::Module, T::Type)
    fields = names(mod, all = true)
    founds = Vector{Any}(filter!(x -> ~(isnothing(x)), [begin 
        if typeof(mod[t]) == T
            getfield(mod, t)
        end
    end for t in fields]))
end

function getindex(mod::Module, T::Function, args::Type ...)
    ms = methods()
    arguments = [begin

    end]
    [arguments]
end

#==
Includes/Exports
==#
include("server/Core.jl")
include("interface/Components.jl")
# Core
export Extension
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
    Pkg.add("Toolips")
    Pkg.add("Revise")
    dir = pwd() * "/"
    src::String = dir * name * "/src"
    if "Logger" in exts
        logs::String = dir * name * "/logs"
        mkdir(logs)
        touch(logs * "/log.txt")
    end
    touch(name * "/dev.jl")
    rm(src * "/$name.jl")
    touch(src * "/$name.jl")
    open(src * "/$name.jl", "w") do io
    write(io, 
"""module $name
# toolips 0.3 syntax
using Toolips

function start(IP::String = "127.0.0.1", PORT::Integer = 8000)
    ws = WebServer(IP, PORT)
    start!(ws, $name)
end

# load extensions
# function load!(ext::Extension{Files}) end

# main
main = route("/") do cm::ComponentModifier

end

# 404
err_404 = route(Toolips.default_404, "404")

# import: export `load!`

export load!
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
    public = pwd() * "/$name/public"
    mkdir(public)
end

# --

end
