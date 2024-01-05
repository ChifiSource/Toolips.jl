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
using ToolipsWebMeasures
using ToolipsServables
using ToolipsServables: File
using HTTP
using Pkg
using ParseNotEval
using Dates
import Base: getindex, setindex!, push!, get,string, write, show, display, (:)
import Base: showerror, in, Pairs, Exception, div, keys, *, read

const WebMeasures = ToolipsWebMeasures

const Components = ToolipsServables

export Components
function getindex(mod::Module, field::Symbol)
    getfield(mod, field)
end

function getindex(mod::Module, T::Type)
    fields = names(mod)
    poss = findall(feld -> typeof(getfield(mod, feld)) <: T, fields)
    res = [getfield(mod, fields[feld]) for feld in poss]
    if length(res) == 0
        return(Vector{T}()::Vector{T})
    end
    res::Vector{<:T}
end

function getindex(mod::Module, T::Function, args::Type ...)
    ms = methods()
    arguments = [begin

    end for m in ms]
    [arguments]
end

include("core.jl")
include("extensions.jl")
include("toolipsapp.jl")
# Core
export IP4, Extension, route, Connection, WebServer, log!, write!, File, start!
export get, post, proxy_pass!, get_route, getargs, get_host, get_parent
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

    start(IP::String = "127.0.0.1", PORT::Integer = 8000) = start!($name, ip, PORT)

    # load extensions
    # function load!(ext::Extension{Files}) end

    # routes
    main = route("/") do cm::ComponentModifier

    end

    # 404
    err_404 = route(Toolips.default_404, "404")

    # important !: export `load!` to use extensions.
    export load!
    end # - module""")
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

end
