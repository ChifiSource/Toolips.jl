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
using Sockets: TCPServer
using ToolipsServables
import ToolipsServables: style!, set_children!, write!
using ParametricProcesses
import ParametricProcesses: distribute!, assign!, waitfor, assign_open!, distribute_open!, put!
using HTTP
using Pkg
using Markdown
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
export IP4, route, Connection, WebServer, log, write!, File, start!, TCPServer, route!, assign!, distribute!, waitfor
export get, post, proxy_pass!, get_route, get_args, get_host, get_parent, AbstractRoute, get_post, get_client_system, Routes
include("extensions.jl")
export on, bind, ClientModifier, move!, remove!, set_text!, set_children!, append!, insert!, sleep!, set_style!, focus!, blur!, alert!
export redirect!, next!, update!, update_base64!

function toolips_header(c::Connection)
    bttnsty = style("a.menbut", "border" => "2px solid gray", "background" => "transparent", "font-weight" => "bold", 
    "padding" => 8px, "transition" => .6s, "margin" => 5px, "text-decoration" => "none", "cursor" => "pointer")
    bttnsty:"hover":["border-color" => "orange", "border-radius" => 2px, "transform" => scale(1.1)]
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
    docsbttn = a("docs_bttn", text = "documentation", class = "menbut")
    bod = body("mainbod")
    style!(bod, "transition" => 1s)
    on(docsbttn, "click") do cl
        style!(cl, "mainbod", "opacity" => 0percent, "translateY" => -20percent)
        next!(cl, bod) do cl2
            redirect!(cl2, "/docs")
        end
    end
    style!(docsbttn, "border-width" => 2px, "border-bottom" => "3px solid #6c7cac", "background" => "transparent", "color" => "#6c7cac", 
    "opacity" => 0percent, "transition" => 2s, "transform" => translateX(30percent))
    push!(landerdiv, tlheader, its_up, welcometo, tltext, br(),
    tlappbttn, docsbttn)
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
    menuitem = Style("div.menuitem", "padding" => 4px, "background-color" => "#885baf", "color" => "white", 
    "transition" => 500ms, "cursor" => "pointer")
    menuitem:"hover":["transform" => "scale(1.02)", "border-left" => "3px solid white"]
    menucontainer = Style("div.menucontainer", "padding" => 3perc, "background-color" => "#715db6")
    pstyle = Style("p", "color" => "white", "font-size" => 13pt)
    hstyle = Style("h1", "color" => "white", "font-size" => 22pt)
    h2style = Style("h2", "color" => "lightgray", "font-size" => 20pt)
    h3style = Style("h3", "color" => "#FF781F", "font-size" => 18pt)
    h4style = Style("h4", "color" => "white", "font-size" => 15pt)
    h5style = Style("h5", "color" => "#301934", "font-size" => 18pt)
    h6style = Style("h6", "color" => "lightblue", "font-size" => 18pt)
    astyle = Style("a", "background-color" => "#574a82", "color" => "white",
    "font-size" => 13pt, "font-weight" => "bold", "font-decoration" => "none", "border-radius" => 2px,
    "padding" => 6px, "transition" => 600ms)
    menlabel = Style("a.menulabel", "color" => "white", "font-weight" => "bold", "font-size" => 17px, 
    "background" => "transparent")
    astyle:"hover":["transform" => scale(1.5perc), "color" => "#FF781F"]
    scrollbars = Style("::-webkit-scrollbar", "width" => 14px)
    scrtrack = Style("::-webkit-scrollbar-track", "background" => "transparent")
    scrthumb = Style("::-webkit-scrollbar-thumb", "background" => "#715db6",
    "border-radius" => "5px")
    codestyle = Style("code", "color" => "#d8e8ef", "background-color" => "#0b0930", "font-size" => 11pt, 
    "padding" => 3px, "border-radius" => 1px)
    h6style = Style("pre", "background-color" => "#0b0930", "padding" => 10px, "border-radius" => 3px)
    [menu, menuitem, menucontainer, pstyle, hstyle, h2style, h3style, h4style, h5style, h6style, 
    codestyle, scrollbars, scrtrack, scrthumb, astyle, menlabel]
end

function build_servermenu(mod::Module)
    allfields = [getfield(mod, name) for name in names(mod)]
    routes = filter(a -> typeof(a) <: AbstractRoute, allfields)
end

"""
### toolips_app (Route{Connection})
`toolips_app` is an API manager for all active `Toolips` servers, ideal for 
    use during development (not production). 
    The route will be available at `/toolips` on your server.
```julia
module MyServer
using Toolips

export toolips_app
end

start!(MyServer)

# or
start!(Toolips, ip = "127.0.0.1":8001)
```
"""
toolips_app = Toolips.route("/toolips") do c::Connection
    write!(c, general_styles())
    mainbod = body("main", align = "center")
    menu = div("menu", align = "center")
    style!(menu, "background-color" => "#715db6", "padding" => 7px, "width" => 16percent, 
    "border-radius" => 2px)
    style!(mainbod, "transition" => 800ms, "overflow" => "hidden")
    args = get_args(c)
    if :server in keys(args)

    else
        scr = on("load") do cl::ClientModifier
            style!(cl, mainbod, "background-color" => "#4f2e6b")
        end
        write!(c, scr)
    end
    # build menu
    procman = c[:procs]
    menitems = [begin 
        if contains(w.name, "router")
            servname = split(w.name, " ")[1]
           div(string(servname), text = "server $servname", class = "menuitem") 
        else
            div(gen_ref(), text = w.name, class = "menuitem") 
        end
    end for w in procman.workers]
    set_children!(menu, menitems)
    push!(mainbod, menu)
    write!(c, mainbod)
end

function mod_docmenu(mod::Module)
    options = [begin
        safename = replace(string(val), "!" => "o")
        opt = div("doc$mod$safename", class = "menuitem", text = "$val")
        on(opt, "click") do cl::ClientModifier
            redirect!(cl, "/docs?get=$mod.$val")
        end
        opt
    end for val in names(mod)]
    mainframe = div("doc$mod", class = "menucontainer")
    moddoc = a("label$mod", text = string(mod), class = "menulabel")
    set_children!(mainframe, vcat(moddoc, options))
    mainframe::Component{:div}
end

"""
#### docmods
'docmods' is used by `/doc` (the toolips_doc default route) 
to load modules. Pushing to this `Vector` will add Modules to the 
`Toolips` autodocumentation page.
"""
const docmods = [Toolips, ToolipsServables]

function make_searchbar(text::String)
    scontainer = div("searchcontainer")
    style!(scontainer, "background" => "transparent", 
    "left" => 18perc, "width" => 92perc, "z-index" => "10", "display" => "flex")
    sbar = a("searchbar", text = "enter search ...", contenteditable = true)
    barstyle = ("padding" => 5px, "border-radius" => 1px, "background-color" => "#0b0930", "color" => "white", 
    "font-weight" => "bold", "font-size" => 15pt)
    style!(sbar, "width" => 40percent, "width" => 85perc, "min-width" => 85perc, barstyle ...)
    sbutton = button("sbutton", text = "search")
    style!(sbutton, barstyle ...)
    on(sbar, "click") do cl
        set_text!(cl, sbar, "")
    end
    on(sbutton, "click") do cl
        proptext = get_text(cl, "searchbar")
        redirect_args!(cl, "/docs", :search => proptext)
    end
    push!(scontainer, sbar, sbutton)
    scontainer
end

"""
### toolips_doc (Route{Connection})
`toolips_doc` is a documentation generator built into the `Toolips` 
web-framework. In order to use this route, simply `export` it in your 
server or call `start!(Toolips)` to use the entire `Toolips` development 
server system. The route will be available at `/doc` on your website!
This includes a simple API manager/status tracker, as well as 
a documentation page (and a home page, which links to the two.)
```julia
module MyServer
using Toolips

export toolips_doc
end

start!(MyServer)

# or
start!(Toolips, ip = "127.0.0.1":8001)
```
"""
toolips_doc = Toolips.route("/docs") do c::Connection
    write!(c, general_styles())
    args = get_args(c)
    mds = Dict(Symbol(m) => m for m in docmods)
    mainbod = body("docbody")
    style!(mainbod, "overflow-x" => "hidden", "overflow-y" => "hidden")
    searchbar = make_searchbar("")
    docmenus = vcat(searchbar, [mod_docmenu(mod) for mod in docmods])
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
        selectedmod = Symbol(modf[1])
        if selectedmod in keys(mds)
            try
                reqdoc = getfield(mds[selectedmod], Symbol(modf[2]))
                md = mds[selectedmod].eval(Meta.parse("@doc($reqdoc)"))
                push!(content, tmd("$(modf[2])", string(md)))
            catch
               #  specific docs not found
               write!(c, modf[2])
               return
            end
        else
            # docs mod not found
        end
    elseif :search in keys(args)
        requested = args[:search]
        allnames = vcat([["$(mod).$(name)" for name in names(mod)] for mod in docmods] ...)
        results = findall(x::String -> contains(x, requested), allnames)
        style!(content, "width" => 70perc)
        resultheading = h1("results", text = "search results")
        items = [begin
            val = allnames[val]
            safename = replace(string(val), "!" => "", "." => "")
            opt = div("doc$safename", class = "menuitem", text = "$val")
            on(opt, "click") do cl::ClientModifier
                redirect!(cl, "/docs?get=$(val)")
            end
            opt
        end for val in results]
        push!(content, resultheading, items ...)
        
    else
        # no documentation selected
        style!(searchbar, "opacity" => 0percent, "transform" => translateY(-10perc), 
        "transition" => 2s)
        style!(menu, "opacity" => 0percent, "width" => 0percent)
        style!(content, "opacity" => 0percent, "width" => 0perc)
        scr = on("load") do cl::ClientModifier
            style!(cl, menu, "opacity" => 100perc, "width" => 18perc)
            next!(cl, menu) do cl2
                style!(cl2, content, "opacity" => 100perc, "width" => 70perc)
                next!(cl2, content) do cl3
                    style!(cl3, searchbar, "transform" => translateY(0perc), "opacity" => 100percent)
                end
            end
        end
        write!(c, scr)
        md_message = """# toolips docs
        welcome to the `Toolips` in-module documentation browser! **helpful links**:
        - [toolips on github]()
        - [issues]()
        - [examples]()"""
        if "/toolips" in c.routes
            md_message = md_message * "\n- [your in-module server manager](/toolips)"
        end
        push!(content, tmd("maingreet", md_message))
    end
    write!(c, mainbod)
end

default_404 = Toolips.route("404") do c::Connection
    write!(c, toolips_header(c))
    write!(c, h6("404-header", text = "404 -- not found"))
end

export default_landing, toolips_app, toolips_doc, default_404

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
    # extensions
    logger = Toolips.Logger()

    # routes
    otherpage = route("/page/path") do c::Connection
        greeter = h2("maingreeting", text = "hello!")
        curr_client = h3("clientn", text = "you are client number ...")
        num = a("num", text = string(c[:clients]))
        maindiv = div("maindiv")
        push!(maindiv, greeter, curr_client, num)
        write!(c, DOCTYPE(), greeter, curr_client, num)
    end
    
    main = route("/") do c::Connection
        if ~(:clients in c.data)
            c[:clients] = 0
        end
        c[:clients] += 1
        log(logger, "served client #\$(clients)")
        route!(c, otherpage)
    end

    mobile = route("/") do c::Toolips.MobileConnection

    end

    # multiroute (will call `mobile` if it is a `MobileConnection`)
    home = route(main, mobile)

    # docs & api manager (/doc && /toolips)
    api_manager = toolips_app
    docs = toolips_doc


    export home, otherpage, default_404
    export api_manager, docs
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

end # Toolips c:
