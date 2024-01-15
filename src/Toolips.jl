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
using ParametricProcesses
@everywhere using Toolips
import ToolipsServables: write!
import ToolipsServables: style!, set_children!
using HTTP
using Pkg
using Markdown
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
export get, post, proxy_pass!, get_route, get_args, get_host, get_parent, AbstractRoute
include("extensions.jl")


function toolips_header(c::Connection)
    bttnsty = style("a.menbut", "border" => "2px solid gray", "background" => "transparent", "font-weight" => "bold", 
    "padding" => 8px, "transition" => .6s, "margin" => 5px, "text-decoration" => "none")
    bttnsty:"hover":["border-color" => "orange", "border-radius" => 2px]
    write!(c, bttnsty)
    if ~("/toolips03.png" in c.routes)
        dir = @__DIR__
        mount_r = mount("/toolips03.png" => dir * "/toolips03.png")
        push!(c.routes, mount_r)
    end
    tltop = img("tl", "src" => "/toolips03.png", width = 150, align = "center")
    style!(tltop, "margin-top" => 10per, "transition" => 900ms)
    write!(c, DOCTYPE(), bttnsty)
    tltop
end

default_landing = Toolips.route("/") do c::Connection
    landerdiv = div("mainlander", align = "center")
    tlheader = toolips_header(c)
    style!(tlheader, "opacity" => 0perc, "transform" => translateY(20perc))
    its_up = h2("itsup", text = "it's up!")
    style!(its_up, "font-weight" => "bold", "font-color" => "darkgray", 
    "opacity" => 0perc, "transition" => 1.5s)
    welcometo = a("welcometo", text = "welcome to ")
    tltext = a("too", text = "toolips!")
    style!(welcometo, "font-size" => 12pt, "opacity" => 0per)
    style!(tltext, "font-size" => 14pt, "font-weight" => "bold", "color" => "#6c7cac", "opacity" => 0per)
    tlappbttn = a("tlapp_bttn", text = "toolips app introspector", onclick = "/toolips", class = "menbut",
    href = "/toolips")
    style!(tlappbttn, "border-bottom" => "3px solid #8c7cc4", "color" => "#8c7cc4", "opacity" => 0percent, "transition" => 2s, 
    "transform" => translateX(30percent))
    docsbttn = a("docs_bttn", text = "documentation", onclick = "/docs", class = "menbut", href = "/docs")
    style!(docsbttn, "border-width" => 2px, "border-bottom" => "3px solid #6c7cac", "background" => "transparent", "color" => "#6c7cac", 
    "opacity" => 0percent, "transition" => 2s, "transform" => translateX(30percent))
    push!(landerdiv, tlheader, its_up, welcometo, tltext, br(),
    tlappbttn, docsbttn)
    bod = body("mainbod")
    loadscript = on("load") do cl
        style!(cl, tlheader, "opacity" => 100perc, "transform" => translateY(0perc))
        style!(cl, welcometo, "opacity" => 100perc, "transition" => 500ms)
        style!(cl, its_up, "opacity" => 100perc, "transform" => translateX(0percent))
        style!(cl, tltext, "opacity" => 100perc, "transition" => 500ms)
        next!(cl, tlheader) do cl2
            style!(cl2, tlappbttn, "opacity" => 100percent, "transform" => translateX(0perc))
            style!(cl2, docsbttn, "opacity" => 100percent, "transform" => translateX(0perc))
        end
    end
    push!(bod, loadscript)
    push!(bod, landerdiv)
    write!(c, bod)
end

function general_styles()
    menu = Style("div.menu", "display" => "inline-block", "width" => 18perc, "left" => 0px, 
    "height" => 100percent, "overflow-x" => "hidden", "overflow-y" => "scroll", "top" => 0perc,
    "background-color" => "#8c7cc4", "position" => "absolute", "transition" => 650ms)
    menuitem = Style("div.menuitem", "padding" => 4px, "background-color" => "#885baf", "color" => "white")
    menucontainer = Style("div.menucontainer", "padding" => 4px, "background-color" => "#715db6")
    pstyle = Style("p", "color" => "white", "font-size" => 13pt)
    hstyle = Style("h1", "color" => "lightgray", "font-size" => 22pt)
    h2style = Style("h2", "color" => "white", "font-size" => 20pt)
    h3style = Style("h3", "color" => "orange", "font-size" => 18pt)
    h4style = Style("h4", "color" => "white", "font-size" => 15pt)
    h5style = Style("h5", "color" => "red", "font-size" => 15pt)
    h6style = Style("h6", "color" => "lightblue", "font-size" => 14pt)
    scrollbars = Style("::-webkit-scrollbar", "width" => 14px)
    scrtrack = Style("::-webkit-scrollbar-track", "background" => "transparent")
    scrthumb = Style("::-webkit-scrollbar-thumb", "background" => "#797ef6",
    "border-radius" => "5px")
    codestyle = Style("code", "color" => "#d8e8ef", "background-color" => "#0b0930", "font-size" => 11pt, 
    "padding" => 3px, "border-radius" => 1px)
    h6style = Style("pre", "background-color" => "#0b0930", "padding" => 10px, "border-radius" => 3px)
    [menu, menuitem, menucontainer, pstyle, hstyle, h2style, h3style, h4style, h5style, h6style, 
    codestyle, scrollbars, scrtrack, scrthumb]
end

toolips_app = Toolips.route("/toolips") do c::Connection
    write!(c, "route manager here")
end

function mod_docmenu(mod::Module)
    options = [begin
        opt = div("doc$mod$val", class = "menuitem", text = "$val")
        on(opt, "click") do cl::ClientModifier
            redirect!(cl, "/docs?get=$mod.$val")
        end
        opt
    end for val in names(mod)]
    mainframe = div("doc$mod", class = "menucontainer")
    moddoc = a("label$mod", text = string(mod))
    style!(moddoc, "color" => "white", "font-weight" => "bold", "font-size" => 17px)
    set_children!(mainframe, vcat(moddoc, options))
    mainframe::Component{:div}
end

toolips_doc = Toolips.route("/docs") do c::Connection
    write!(c, general_styles())
    args = get_args(c)
    mainbod = body("docbody")
    style!(mainbod, "overflow-x" => "hidden", "overflow-y" => "hidden")
    docmenus = [mod_docmenu(mod) for mod in (Toolips, Components)]
    menu = div("menu", class = "menu", children = docmenus)
    content = div("content")
    style!(content, "background-color" => "#8c7cc4", "display" => "inline-block", 
    "position" => "absolute", "left" => 18perc, "height" => 90percent, "top" => 0perc, 
    "padding" => 6perc, "padding-top" => 2perc, "overflow-x" => "wrap", "overflow-y" => "scroll", 
    "transition" => 700ms)
    push!(mainbod, menu, content)
    if :get in keys(args)
        style!(content, "width" => 70perc)
        modf = split(args[:get], ".")
        if modf[1] == "Toolips"
            reqdoc = getfield(Toolips, Symbol(modf[2]))
            md = string(eval(Meta.parse("@doc($reqdoc)")))
            push!(content, tmd("$(modf[2])", md))
        else
            reqdoc = getfield(Components, Symbol(modf[2]))
        end
    else
        style!(menu, "opacity" => 0percent, "width" => 0percent)
        style!(content, "opacity" => 0percent, "width" => 0perc)
        scr = on("load") do cl::ClientModifier
            style!(cl, menu, "opacity" => 100perc, "width" => 18perc)
            next!(cl, menu) do cl2
                style!(cl2, content, "opacity" => 100perc, "width" => 70perc)
            end
        end
        write!(c, scr)
    end

    write!(c, mainbod)
    
end

default_404 = Toolips.route("404") do c::Connection
    write!(c, toolips_header(c))
end

export default_landing, toolips_app, toolips_doc, default_404

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
    # extensions
    logger = Toolips.Logger()

    # routes
    clients_served = 0
    main = route("/") do c::Connection
        clients_served += 1
        log(logger, "served client #\$(clients_served)")
        route!(c, "/page/path")
    end

    mobile = route("/") do c::Toolips.MobileConnection

    end

    otherpage = route("/page/path") do c::Connection
        greeter = h2("maingreeting", text = "hello!")
        curr_client = h3("clientn", text = "you are client number ...")
        num = a("num", text = string(clients_served))
    end

    # multiroute
    home = route(main, mobile)

    # docs & api manager (/doc && /toolips)
    api_man = toolips_app
    docs = toolips_doc


    export home, otherpage, default_404
    export api_man, docs
    export logger
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
        toolips_process = start!($name)
        """)
    end
end

end
