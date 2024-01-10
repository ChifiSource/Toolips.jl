#==
map
- imports
- `Components`
- helpful `Module` introspection dispatches.
- default projects
==#
"""
#### toolips 0.3 - a manic web-development framework
- Created in January, 2024 by [chifi](https://github.com/orgs/ChifiSource)
- This software is MIT-licensed.

Toolips is an **extensible** and **declarative** web-development for julia.

```example
module MyServer
using Toolips
using Toolips.Components
# import 
# create a logger
logger = Logger()

# quick extension

const people = Extension{:people}

# mount difrectory "MyServer/public" to "/public"
public = route("/public" => "public")

# create a route
main = route("/") do c::Connection

end

# multiroute

# export routes
export public

# export extensions

# export server data
export people
end # module
```
####### provides
- `new_app(name**::String, )`
"""
module Toolips
using Crayons
using Sockets
using Sockets: TCPServer
using ToolipsServables
import ToolipsServables: write!
using HTTP
using Pkg
using ParseNotEval
using Dates
import Base: getindex, setindex!, push!, get,string, write, show, display, (:)
import Base: showerror, in, Pairs, Exception, div, keys, *, read

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
export IP4, Extension, route, Connection, WebServer, log!, write!, File, start!, TCPServer
export get, post, proxy_pass!, get_route, get_args, get_host, get_parent, toolips_app
include("extensions.jl")
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
    using Toolips
    # routes
    main = route("/") do c::Connection

    end

    otherpage = route("/page/path") do c::Connection

    end

    mobile = route("/") do c::Toolips.MobileConnection

    end

    post = route("/") do c::Toolips.PostConnection

    end

    # multiroute
    home = route(main, mobile, post)

    # server development assistant
    toolipsapp = toolips_app
    # data
    name::String = ""
    # extensions
    documentation = ToolipsDocumenter()
    export home, otherpage, default_404
    export documentation, data
    end # - module""")
    end
end

"""
```julia
new_app(name**::String**, template::Type{<:ServerTemplate} = WebServer) -> ::Nothing
```
---
Creates a new toolips app with name `name`. A `template` may also be provided to build a project 
from a `ServerTemplate`. The only `ServerTemplate` provided by `Toolips` is the `WebServer`, server 
templates are used as a base to start a server from, `WebServer` in this case just means TCPServer.
##### example
```example
using Toolips
Toolips.new_app("ToolipsApp")
```
```example
using Toolips
Toolips.new_app("ToolipsApp", Toolips.WebServer)
```
---
- **see also:**
```julia

```
"""
function new_app(name::String, template::Type{<:ServerTemplate} = WebServer)
    create_serverdeps(name)
    servername = name * "Server"
    open(name * "/dev.jl", "w") do io
        write(io, """
        using Pkg; Pkg.activate(".")
        using Revise
        using Toolips
        using $name
        $(name)INFO = start!($name)
        start!(Toolips, ) # dev helper
        """)
    end
end

end
