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

Toolips is an **extensible**, *declarative*, and **versatile** web-development framework for the Julia programming language.
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
##### provides
- `new_app`
- `default_404`
- `Components`
- `make_docroute`
- **core**
  - `Cookie` (see `respond!`)
  - `IP4`
  - `get(::String)`
  - `post`
  - `AbstractConnection`
  - `distribute!`
  - `assign!`
  - `assign_open!`
  - `distribute_open!`
  - `waitfor`
  - `put!`
  - `Connection`
  - `write!`
  - `IOConnection`
  - `get_ip`
  - `get_ip4`
  - `get_args`
  - `get_post`
  - `get_method`
  - `get_route`
  - `get_host`
  - `get_client_system`
  - `get_heading`
  - `get_headers`
  - `get_parent`
  - `get_cookies`
  - `download!`
  - `proxy_pass!`
  - `respond!`
  - `Route`
  - `route`
  - `route!`
  - `AbstractExtension`
  - `QuickExtension`
  - `on_start`
  - `ServerTemplate`
  - `WebServer`
  - `kill!`
  - `start!`
  - `connect`
- **extensions**
  - `MobileConnection`
  - `Logger`
  - `log(::AbstractConnection, ::String, ::Int64)`
  - `mount`

"""
module Toolips
using Crayons
using Sockets
import Sockets: connect
import ToolipsServables
using ToolipsServables.Markdown
import ToolipsServables: style!, write!, AbstractComponentModifier, Modifier, File, AbstractComponent, on, ClientModifier, h6, gen_ref, p, percent, img, body, interpolate!
using ParametricProcesses
import ParametricProcesses: distribute!, assign!, waitfor, assign_open!, distribute_open!, put!, AbstractProcessManager
using HTTP
import HTTP: Cookie
using Pkg
import Base: getindex, setindex!, push!, get,string, write, show, display, (:), delete!, eof
import Base: showerror, in, Pairs, Exception, div, keys, *, read, insert!, log, readavailable

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

connect(ip::IP4) = connect(ip.ip, ip.port)

connect(host::IP4, to::IP4) = connect(host.ip, host.port, to.ip, to.port)

export IP4, route, mount, Connection, AbstractConnection, WebServer, log, write!, File, start!, route!, assign!, distribute!, waitfor, get_ip, kill!
export get, post, proxy_pass!, get_route, get_args, get_host, get_parent, AbstractRoute, get_post, get_client_system, Routes, get_method, interpolate!
export get_cookies, connect, respond!, get_headers, handler, clear_cookies!, SocketConnection, read_all
include("extensions.jl")
export is_closed, is_connected, handler
#==
Project API
==#
"""
```julia
create_serverdeps(name::String) -> _
```
Creates the base server file-system for a `Toolips` app.
```example
create_serverdeps("ToolipsApp")
```
"""
function create_serverdeps(name::String)
    err::Pipe = Pipe()
    std::Pipe = Pipe()
    dir::String = pwd() * "/"
    src::String = dir * name * "/src"
    @info "generating toolips project..."
    Pkg.generate(name)
    Pkg.activate(name)
    Pkg.add("Toolips")
    Pkg.add("Revise")
    touch(name * "/dev.jl")
    rm(src * "/$name.jl")
    touch(src * "/$name.jl")
    open(src * "/$name.jl", "w") do io
        write(io, 
"""
module $name
using Toolips
# using Toolips.Components

# optional, gives CLI access to server, procs, and/or data:
server = nothing
data = nothing
procs = nothing

#==
extensions
==#
logger = Toolips.Logger()    

#==
routes
==#

main = route("/") do c::Toolips.AbstractConnection
    post_data = get_post(c)
    args = get_args(c)
    client_number = string(c[:clients])
    log(logger, "served client " * client_number)
    write!(c, "hello client #" * client_number)
end

# files:
# public = mount("/public" => "public")


# make sure to export!
export start!, main, default_404
end # - module $name <3""")
    end
    @info "project `$name` created!"
end

"""
```julia
new_app(name**::String**, template::Type{<:ServerTemplate} = WebServer) -> ::Nothing
```
Creates a new toolips app with name `name`. A `template` may also be provided to build a project 
from a `ServerTemplate`. The only `ServerTemplate` provided by `Toolips` is the `WebServer`, server 
templates are used as a base to start a server from default files. 

As of `0.3.11`, `new_app` also contains additional server template types. The canonical example of this from 
`Toolips` being the TCP server. Calling `new_app` for a specific server type mirrors calling `start!` for a 
specific server type. Simply provide the symbol of the server type.
```julia
new_app(st::Symbol, args ...; keyargs ...)
```
```example
using Toolips
Toolips.new_app("ToolipsApp")

# new non-HTTP TCP server:
Toolips.new_app(:TCP, "RegularApp")

# extension new_app
using ToolipsUDP

ToolipsUDP.new_app(:UDP, "UDPApp")
```
```example
using Toolips
Toolips.new_app("ToolipsApp", Toolips.WebServer)
```
- See also: `Toolips`, `route`, `start!`, `Connection`, `make_docroute`
"""
function new_app(name::String)
    create_serverdeps(name)
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

new_app(st::Symbol, args ...; keyargs ...) = new_app(ServerTemplate{st}, args ...; keyargs ...)

default_404 = Toolips.route("404") do c::AbstractConnection
    if ~("/toolips03.png" in c.routes)
        dir::String = @__DIR__ 
        mount_r::Route = mount("/toolips03.png" => dir * "/toolips03.png")
        c.routes = vcat(c.routes, mount_r)
    end
    tltop = img("tl", "src" => "/toolips03.png", width = 150, align = "center")
    style!(tltop, "margin-top" => 10percent, "transition" => "900ms", "opacity" => 0percent, "transform" => "translateY(10%)")
    notfound = Components.h6("404-header", text = "404 -- not found", align = "center")
    style!(notfound, "color" => "#333333", "font-size" => "12pt")
    uphead = Components.a("upheader", text = "your server is up! ")
    style!(uphead, "color" => "darkblue", "font-size" => "15pt", "font-weight" => "bold")
    messg = Components.a("rtnt", text = "this route ($(get_route(c))) does not exist on your server.")
    style!(messg, "color" => "#6879D0", "font-size" => "13pt")
    exported_footer = Components.a("eport", text = " (make sure it is exported.)")
    style!(exported_footer, "color" => "#gray", "font-size" => "13pt")
    mainbod = body("404-main", align = "center")
    scr = on("load") do cl::ClientModifier
        style!(cl, tltop, "opacity" => 100percent, "transform" => "translateY(0%)")
    end
    push!(mainbod, tltop, notfound, uphead, Components.br(), messg, exported_footer, scr)
    write!(c, mainbod)
end 

"""
```julia
make_docroute(mod::Module) -> ::Route{Connection}
```
`make_docroute` automatically creates a simple web-based documentation browser for **any module**. 
Simply provide the `Module` and export the `Route` that comes as a return.
```julia
module DocServer
using Toolips

base_docs = Toolips.make_docroute(Base)
toolips_docs = Toolips.make_docroute(Toolips)
components_docs = Toolips.make_docroute(Toolips.Components)

export base_docs, toolips_docs, components_docs, start!
end

using Main.DocServer; start!(Main.DocServer)
```
- **see also:** `Toolips`, `route`, `start!`, `Connection`, `new_app`
"""
function make_docroute(mod::Module)
    function build_doc_page(name::String, docstring::String, value::Any)
        name_label = Components.h2("$name-label", text = name)
        style!(name_label, "font-weight" => "bold", "font-size" => "15pt", "color" => "white")
        type_label = Components.h4("$name-type", text = "    " * string(typeof(value)))
        style!(type_label, "color" => "#dbac4d")
        docstring = Components.tmd("docstring-$name", docstring)
        page_container::Components.Component{:div} = Components.div("$name", children = [name_label, type_label, docstring])
        style!(page_container, "background-color" => "#141e33", "padding" => "30px")
        page_container
    end
    function build_doc_page(name::String, docstring::String, value::Function)
        name_label = Components.h2("$name-label", text = replace(name, "macr_" => "@", "expl_" => "!"))
        style!(name_label, "font-weight" => "bold", "font-size" => "15pt", "color" => "lightblue", "display" => "auto")
        type_label = Components.h4("$name-type", text = "Function")
        style!(type_label, "color" => "#dbac4d")
        docstring = Components.tmd("docstring-$name", docstring)
        page_container::Components.Component{:div} = Components.div("$name", children = [name_label, type_label, docstring])
        style!(page_container, "background-color" => "#141e33", "padding" => "30px")
        page_container
    end
    modname = lowercase(string(mod))
    route("/docs/$modname") do c::AbstractConnection
        args::Dict{Symbol, String} = get_args(c)
        if ~(Symbol("doc$modname") in c)
            docbuttons = Vector{AbstractComponent}()
            docs = Vector{AbstractComponent}(filter!(k -> ~(isnothing(k)), [begin
                if contains(string(name), "#")
                    nothing
                else
                   try
                        value = nothing
                        value = getfield(mod, name)
                        docstring = string(mod.eval(Meta.parse("@doc($name)")))
                        name = replace(string(name), "!" => "expl_", "@" => "macr_")
                        page = build_doc_page(string(name), docstring, value)
                        
                        doc_button = Components.div("docbutton$name", children = [page[:children]["$name-label"], 
                        Components.br(), page[:children]["$name-type"]])
                        style!(doc_button, "cursor" => "pointer", "width" => "35%", "height" => "10%", 
                        "display" => "inline-flex", "border-radius" => "3px", "border" => "3px solid #333333", 
                        "background-color" => "#141e33", "padding" => "5px")
                        Components.on(doc_button, "dblclick") do cl::ClientModifier
                            Components.redirect!(cl, "/docs/$modname?select=$name")
                        end
                        push!(docbuttons, doc_button)
                        page
                    catch e
                        nothing
                    end
                end
            end for name in names(mod, all = true)]))
            push!(c.data, Symbol("doc$(modname)") => docs, Symbol("doc$(modname)buttons") => docbuttons)
        end
        if haskey(args, :select)
            post_style = Components.style("p", "color" => "white")
            h1_style = Components.style("h1", "color" => "white")
            h2_style = Components.style("h2", "color" => "pink")
            h3_style = Components.style("h3", "color" => "white")
            h4_style = Components.style("h4", "color" => "white")
            h5_style = Components.style("h5", "color" => "white")
            a_style = Components.style("a", "color" => "lightblue")
            code_style = Components.style("code", "background-color" => "white", "padding" => "1px", 
            "border-radius" => "4px", "color" => "black")
            li_style = Components.style("li", "padding" => "4px", "color" => "white")
            back_button = div("backb", text = "<- back")
            style!(back_button, "padding" => "7px", "background-color" => "white", "color" => "#333333", 
            "font-weight" => "bold", "font-size" => "14pt", "cursor" => "pointer", 
            "border-top" => "2px solid #1e1e1e", "border-right" => "2px solid #1e1e1e", "border-left" => "2px solid #1e1e1e")
            Components.on(back_button, "click") do cl::ClientModifier
                Components.redirect!(cl, "/docs/$modname")
            end
            write!(c, post_style, h1_style, h2_style, h3_style, h4_style, h5_style, a_style, code_style, 
            li_style)
            mainbod = body("mainbody", children = [back_button, c[Symbol("doc$modname")][args[:select]]])
            style!(mainbod, "background-color" => "#9bb0b0")
            write!(c, mainbod)
            return
        end
        mainbod = body("mainbody", align = "center", children = c[Symbol("doc$(modname)buttons")])
        style!(mainbod, "background-color" => "#9bb0b0")
        write!(c, mainbod)
    end
end

export default_404

end # Toolips c:
