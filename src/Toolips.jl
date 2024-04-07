#==
map
- imports
- `Components`
- helpful `Module` introspection dispatches.
- includes/exports
- default pages
- project generation
==#

"""
#### toolips 0.3 - a manic web-development framework
- Created in January, 2024 by [chifi](https://github.com/orgs/ChifiSource)
- This software is MIT-licensed.

Toolips is an **extensible** and **declarative** web-development framework for the julia programming language. 
The intention with this framework is to *fill most web-development needs well.* While there are lighter options for 
APIs and heavier options for web-apps, `Toolips` presents a plethora of capabilities for both of these contexts -- as well as many more!

```example
module MyServer
using Toolips
using Toolips.Components
# import 
# create a logger
logger = Logger()

# quick extension

const people = Extension{:people}

# mount directory "MyServer/public" to "/public"
public = mount("/public" => "public")

# create a route
main = route("/") do c::Connection

end

# export routes
export public
export main

# export extensions
export logger
end # module
```
####### provides
- `new_app(name**::String, )`
"""
module Toolips
using Crayons
using Sockets
import ToolipsServables
import ToolipsServables: style!, write!, AbstractComponentModifier, Modifier, File, AbstractComponent, Markdown, Servables
using ParametricProcesses
import ParametricProcesses: distribute!, assign!, waitfor, assign_open!, distribute_open!, put!
using HTTP
using Pkg
import Base: getindex, setindex!, push!, get,string, write, show, display, (:)
import Base: showerror, in, Pairs, Exception, div, keys, *, read, insert!, log

const Components = ToolipsServables

export Components, distribute!, assign!, new_job, @everywhere, distribute_open!, waitfor, assign_open!

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

function show(io::IO, pm::ProcessManager)
    headers::Vector{String} = ["pid", "process type", "name", "active"]
    md = """
    $(join(headers, "|"))
    $(join(fill("----", length(headers)), "|"))
    """
    for worker in pm.workers
        row = [string(worker.pid), string(typeof(worker).parameters[1]), worker.name, string(worker.active)]
        md *= join(row, "|") * "\n"
    end
    display(Markdown.parse(md))
end

include("core.jl")
export IP4, route, mount, Connection, WebServer, log, write!, File, start!, route!, assign!, distribute!, waitfor, get_ip
export get, post, proxy_pass!, get_route, get_args, get_host, get_parent, AbstractRoute, get_post, get_client_system, Routes, get_method
include("extensions.jl")

#==
Project API
==#
"""
```julia
create_serverdeps(name::String) -> _
```
---
Creates a `Toolips` app template with a corresponding `Project.toml` environment and `dev.jl` 
file to quickly get started.
#### example
```example
create_serverdeps("ToolipsApp")
```
"""
function create_serverdeps(name::String)
    Pkg.generate(name)
    Pkg.activate(name)
    Pkg.add("Toolips")
    Pkg.add("Revise")
    dir = pwd() * "/"
    src::String = dir * name * "/src"
    touch(name * "/dev.jl")
    rm(src * "/$name.jl")
    touch(src * "/$name.jl")
    open(src * "/$name.jl", "w") do io
    write(io, 
    """module $name
    using Toolips
    # using Toolips.Components

    # extensions
    logger = Toolips.Logger()
    
    main = route("/") do c::Connection
        if ~(:clients in c.data)
            c[:clients] = 0
        end
        c[:clients] += 1

        log(logger, "served client " * c[:clients])
        write!(c, "hello client #" * c[:clients])
    end

    mobile = route("/") do c::Toolips.MobileConnection
        write!(c, "hello mobile device!")
    end

    # multiroute (will call `mobile` if it is a `MobileConnection`)
    home = route(main, mobile)

    # make sure to export!
    export home, default_404
    export logger
    end # - module $name <3""")
    end
end

"""
```julia
new_app(name**::String**, template::Type{<:ServerTemplate} = WebServer) -> ::Nothing
```
---
Creates a new toolips app with name `name`. A `template` may also be provided to build a project 
from a `ServerTemplate`. The only `ServerTemplate` provided by `Toolips` is the `WebServer`, server 
templates are used as a base to start a server from default files.
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
- **see also:** `Toolips`, `route`, `start!`, `Connection`
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
        toolips_process = start!($name)
        """)
    end
end

default_404 = Toolips.route("404") do c::Connection
    dir::String = @__DIR__
    raw::String = read(dir, String)
    headerimg::Component{:img} = base64img("tlheader", raw, align = "center")
    write!(c, headerimg)
    write!(c, h6("404-header", text = "404 -- not found"))
end

export default_404

end # Toolips c:
