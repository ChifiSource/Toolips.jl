#==
map
- additional components
- file interpolation
- additional connections
- logger
- files
- Modifier/ClientModifier
==#

"""
```julia
tmd(name::String, md::String = "", args::Pair{String, <:Any} ...; args ...) -> ::Component{:div}
```
Creates a `Component` directly from a raw markdown String. The `Component's` children will be 
the markdown provided rendered to HTML.
---
```example
mymd = "# hello\\n **this** is markdown"

comp = tmd("mygreeting", mymd)
```
"""
function tmd(name::String, s::String = "", p::Pair{String, <:Any} ...;
    args ...)
    md = Markdown.parse(replace(s, "<" => "", ">" => "", "\"" => ""))
    htm::String = html(md)
    div(name, text = htm, p ...; args ...)::Component{:div}
end

#==
TODO InterpolatedFile here :)
deprecate ToolipsInterpolator
==#

"""
```julia
MobileConnection <: AbstractConnection
```
- stream**::HTTP.Stream**
- data**::Dict{Symbol, Any}**
- ret**::Any**

A `MobileConnection` is used with multi-route, and will be created when an incoming `Connection` is mobile. 
This is done by simply annotating your `Function`'s `Connection` argument when calling `route`. To create one 
page for both of these routes, we then use `route` to combine them.
```julia
module ExampleServer
using Toolips
main = route("/") do c::Connection
    write!(c, "this is a desktop.")
end

mobile = route("/") do c::Toolips.MobileConnection
    write!(c, "this is mobile")
end

# multiroute (will call `mobile` if it is a `MobileConnection`)
home = route(main, mobile)

# then we simply export the multi-route
export home
end
using Toolips; Toolips.start!(ExampleServer)
```
- See also: `route`, `Connection`, `route!`, `Components`, `convert`, `convert!`

It is unlikely you will use this constructor unless you are calling 
`convert!`/`convert` in your own `route!` design.
```julia
MobileConnection(stream::HTTP.Stream, data::Dict{Symbol, Any}, routes::Vector{AbstractRoute})
```
"""
mutable struct MobileConnection <: AbstractConnection
    stream::HTTP.Stream
    data::Dict{Symbol, Any}
    routes::Vector{AbstractRoute}
end

function convert(c::Connection, routes::Routes, into::Type{MobileConnection})
    get_client_system(c)[2]
end

function convert!(c::Connection, routes::Routes, into::Type{MobileConnection})
    MobileConnection(c.stream, c.data, routes)::MobileConnection
end

"""
```julia
Logger <: Toolips.AbstractExtension
```
- `crayons`**::Vector{Crayon}**
- `prefix`**::String**
- `write`**::Bool**
- `writeat`**::Int64**
- `prefix_crayon`**::Crayon**


```julia
Logger(prefix::String = "🌷 toolips> ", crayons::Crayon ...; dir::String = "logs.txt", write::Bool = false, 
writeat::Int64, prefix_crayon::Crayon = Crayon(foreground  = :blue, bold = true))
```
###### example
```example
module ExampleServer
using Toolips
crays = (Toolips.Crayon(foreground = :red), Toolips.Crayon(foreground = :black, background = :white, bold = true))
log = Toolips.Logger("yourserver>", crays ...)

# use logger
route("/") do c::Connection
    log(c, "hello world!", 1)
end
# load to server
export log
end
using Toolips; Toolips.start!(ExampleServer)
```
- See also: `route`, `Connection`, `Extension`
"""
mutable struct Logger <: AbstractExtension
    crayons::Vector{Crayon}
    prefix::String
    write::Bool
    writeat::Int64
    prefix_crayon::Crayon
    function Logger(prefix::String = "🌷 toolips> ", crayons::Crayon ...; dir::String = "logs.txt",
        write::Bool = false, writeat::Int64 = 3, prefix_crayon = Crayon(foreground  = :blue, bold = true))
        if write && ~(isfile(dir))
            try
                touch(dir)
            catch
                throw("Logger tried to make log file \"$dir\", but could not.")
            end
        end
        if length(crayons) < 1
            crayons = [Crayon(foreground  = :light_blue, bold = true)]
        end
        new([crayon for crayon in crayons], prefix, write, writeat, prefix_crayon)
    end
end

function log(l::Logger, message::String, at::Int64 = 1)
    cray = l.crayons[at]
    println(l.prefix_crayon, l.prefix, cray, message)
end

"""
```julia
log(c::Connection, message::String, at::Int64 = 1) -> ::Nothing
```
---
`log` will print the message with your `Logger` using the crayon `at`. `Logger` 
will give a lot more information on this.
#### example
```example
module MyServer
using Toolips

logger = Toolips.Logger()

home = route("/") do c::Connection
    log(c, "hello server!")
    write!(c, "hello client!")
end

export home, logger
end
```
"""
log(c::Connection, args ...) = log(c[:Logger], args ...)

"""
```julia
mount(fpair::Pair{String, String}) -> ::Route{Connection}/::Vector{Route{Connection}}
```
---
`mount` will create a route that serves a file or a all files in a directory. 
The first part of `fpair` is the target route path, e.g. `/` would be home. If 
the provided path is as directory, the Function will return a `Vector{AbstractRoute}`. For 
a single file, this will be a route.
#### example
```example
module MyServer
using Toolips

logger = Toolips.Logger()

filemount::Route{Connection} = mount("/" => "templates/home.html")

dirmount::Vector{<:AbstractRoute} = mount("/files" => "public")

export filemount, dirmount, logger
end
```
"""
function mount(fpair::Pair{String, String})
    fpath::String = fpair[2]
    target::String = fpair[1]
    if ~(isdir(fpath))
        return(route(c::Connection -> begin
            write!(c, File(fpath))
        end, target))::AbstractRoute
    end
    [route(c::Connection -> write!(c, File(path)), target * "/" * fpath) for path in route_from_dir(fpath)]::Vector{<:AbstractRoute}
end

function route_from_dir(path::String)
    dirs::Vector{String} = readdir(dir)
    routes::Vector{String} = []
    [begin
        if isfile("$dir/" * directory)
            push!(routes, "$dir/$directory")
        else
            if ~(directory in routes)
                newread::String = dir * "/$directory"
                newrs::Vector{String} = route_from_dir(newread)
                [push!(routes, r) for r in newrs]
            end
        end
    end for directory in dirs]
    routes::Vector{String}
end

"""
```julia
abstract type Modifier <: Servable
```
A `Modifier` is a type used to create handler callbacks for front-end development. 
These are typically passed as an argument to a function to make some type of changes.
---
- See also: `AbstractComponentModifier`, `ClientModifier`, `Component`, `on`, `bind`
"""
abstract type Modifier <: Servable end

"""
```julia
abstract type AbstractComponentModifier <: Modifier
```
An `AbstractComponentModifier` is a `Modifier` for components. `Toolips` 
features the `ClientModifier`. This is a limited `ComponentModifier` that 
can be used to execute some commands on the client-side. The shortcoming is that 
we never call the server, so nothing can be done in Julia.
```julia
route("/") do c::Connection
    comp = button("testbutton", text = "press me")
    on(comp, "click") do cl::ClientModifier
        alert!(cl, "you pressed me!")
    end
    bod = body("mainbody")
    push!(bod, comp)
    write!(c, bod)
end
```
For server-side responses, add `ToolipsSession` and use the `ComponentModifier`.
---
- See also: `ClientModifier`, `Modifier`, Component`, `on`, `bind`
"""
abstract type AbstractComponentModifier <: Modifier end

setindex!(cm::AbstractComponentModifier, p::Pair, s::Any) = begin
    if typeof(s) <: AbstractComponent
        s = s.name
    end
    key, val = p[1], p[2]
    push!(cm.changes,
    "document.getElementById('$s').setAttribute('$key','$val');")
end

abstract type AbstractClientModifier <: AbstractComponentModifier end

"""
```julia
ClientModifier <: AbstractClientModifier
```
- name**::String**
- changes**::Vector{String}**

A `ClientModifier` helps to template functions on the client-side. These are 
ran without the use of the server. Base `Toolips` does not include server-handled callbacks. 
The downside to client-side callbacks is that they are limited in what they can do. 
We cannot retrieve data from or use julia for this response. All of the code server-side 
    will be ran on the initial response with this type. `ToolipsSession` provides the `ComponentModifier`, 
    which will provide a lot more capabilities as far as this goes.
    
- See also: `keyframes`, `style!`, `style`, `StyleComponent`, `templating`
```julia
ClientModifier(name::String = gen_ref())
```
---
An `AbstractComponentModifier` will typically be used with `on`. For a client-side `on` 
event, simply call `on` on a `Component` with the event selected:
```example
module NewServer
using Toolips
using Toolips.Components
route("/") do c::Connection
    butt = button("mainbutton", text = "click me")
    style!(butt, "padding" => 10px, "background-color" => "darkred", 
    "color" => "white")
    on(butt, "click") do cl::ClientModifier
        style!(cl, butt, "transform" => translateX(20percent))
    end
    write!(c, butt)
end
```
Adding `ToolipsSession` will allow us to add server-side callbacks by 
adding `Connection` to our `on` call will create a server-side callback, 
which allows us to read back `Component` properties
```julia
on(c, butt, "click") do cm::ComponentModifier
    sample::String = cm[butt]["text"]
end
```
"""
mutable struct ClientModifier <: AbstractClientModifier
    name::String
    changes::Vector{String}
    ClientModifier(name::String = gen_ref()) = begin
        new(name, Vector{String}())::ClientModifier
    end
end

"""
```julia
get_text(cl::AbstractClientModifier, name::String) -> ::Component{:property}
```
`get_text` is used to retrieve the text of a `Component` in a `ClientModifier`. 
The `Component{:property}` can then be used with `setindex!`.
#### example
The following example is the function that makes the searchbar for the 
    `Toolips` app. This simple searchbar uses `get_text` and `redirect_args!` to 
    redirect the client with new `GET` arguments. This is a simple way to create a 
    complex website without using callbacks.
```example
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
```
"""
function get_text(cl::AbstractClientModifier, name::String)
    Component{:property}("document.getElementById('$name').textContent;")
end

setindex!(cm::AbstractClientModifier, name::String, property::String, comp::Component{:property}) = begin
    push!(cm.changes, "document.getElementById('$name').setAttribute('$property',$comp);")
end

write!(c::AbstractConnection, cm::ClientModifier) = write!(c, funccl(cm))

"""
```julia
funccl(cm::ClientModifier, name::String = cm.name) -> ::String
```
---
Converts a `ClientModifier` to a JavaScript `Function`.
#### example
```example
module MyServer
using Toolips

logger = Toolips.Logger()

home = route("/") do c::Connection
    log(c, "hello server!")
    write!(c, "hello client!")
end

export home, logger
end
```
"""
function funccl(cm::ClientModifier = ClientModifier(), name::String = cm.name)
    """function $(name)(event){$(join(cm.changes))}"""
end

"""
```julia
on(f::Function, ...) -> ::Nothing/::Component{:script}
```
---
`on` is used to register events to components or directly to pages using 
Javascript's EventListeners. `on` will generally be passed a `Component` and 
an event.
```julia
on(f::Function, component::Component{<:Any}, event::String) -> ::Nothing
on(f::Function, event::String) -> ::Component{:script}
```
- See also: `ClientModifier`, `move!`, `remove!`, `append!`, `set_children!`
#### example
```example
module MyServer
using Toolips
using Toolips.Components

home = route("/") do c::Connection
    mybutton = div("mainbut", text = "click this button")
    style!(mybutton, "border-radius" => 5px)
    on(mybutton, "click") do cl::ClientModifier
        alert!(cl, "hello world!")
    end
    write!(c, mybutton)
end

export home
end
```
"""
function on end

function on(f::Function, component::Component{<:Any}, event::String)
    cl::ClientModifier = ClientModifier("$(component.name)$(event)")
    f(cl)
    component["on$event"] = "$(cl.name)(event);"
    push!(component[:extras], script(cl.name, text = funccl(cl)))
    nothing::Nothing
end

function on(f::Function, event::String)
    cl = ClientModifier(); f(cl)
    scrpt = """addEventListener("$event", $(funccl(cl)));"""
    script("doc$event", text = scrpt)::Component{:script}
end

"""
```julia
bind(f::Function, key::String, eventkeys::Symbol ...; on::Symbol = :down) -> ::Component{:script}
```
---
`bind` is used to bind inputs other than clicks and drags to a `Component` or `Connection`.
This `bind!` simply generates a `Component{:script}` that will bind keyboard events.
- See also: `ClientModifier`, `on`, `set_text!`, `set_children!`, `alert!`
#### example
```example
module MyServer
using Toolips
using Toolips.Components

home = route("/") do c::Connection
    scr = bind("Z", :ctrl) do cl::ClientModifier
        alert!(cl, "undo")
    end
end

export home
end
```
"""
function bind end

function bind(f::Function, key::String, eventkeys::Symbol ...; on::Symbol = :down)
    eventstr::String = join(" event.$(event)Key && " for event in eventkeys)
    cl = ClientModifier()
    f(cl)
    script(cl.name, text = """addEventListener('key$on', function(event) {
            if ($eventstr event.key == "$(key)") {
            $(join(cl.changes))
            }
            });""")
end

"""
```julia
move!(cm::AbstractComponentModifier, p::Pair{<:Any, <:Any}) -> ::Nothing
```
---
`move!` is a `ComponentModifier` `Function` that will move a `Component` into 
another `Component`. The values of `p` -- as is the case in most `ComponentModifier` functions which take 
a `Component` -- can be `Component` names or the Components themselves. The key of the `Pair` 
will become the child of the value.
#### example
```example
using Toolips
home = route("/") do c::Connection
    child = div("moved", text = "hello")
    parent = div("movedinto")
    style!(parent, "margin" => 10px, "background-color" => "red")
    on(c, parent, "click") do cl::ClientModifier
        move!(cl, "moved" => "movedinto")
    end
    write!(c, child, parent)
end
```
"""
function move!(cm::AbstractComponentModifier, p::Pair{<:Any, <:Any})
    firstname = p[1]
    secondname = p[2]
    if firstname <: AbstractComponent
        firstname = firstname.name
    end
    if secondname <: AbstractComponent
        secondname = secondname.name
    end
    push!(cm.changes, "
    document.getElementById('$secondname').appendChild(document.getElementById('$firstname'));
  ")
  nothing::Nothing
end

"""
```julia
remove!(cm::AbstractComponentModifier, s::Any) -> ::Nothing
```
---
`remove!` is a `ComponentModifier` `Function` that will remove a `Component` 
from the page. `s` can be either a `String`, the component's `name` or the 
`Component` itself.
#### example
```example
using Toolips
home = route("/") do c::Connection
    box = div("sample")
    style!(box, "margin" => 10px, "background-color" => "red")
    on(c, box, "click") do cl::ClientModifier
        remove!(cl, "sample")
    end
    write!(c, box)
end
```
"""
function remove!(cm::AbstractComponentModifier, s::Any)
    if typeof(s) <: AbstractComponent
        s = s.name
    end
    push!(cm.changes, "document.getElementById('$s').remove();")
    nothing::Nothing
end

function set_text!(c::Modifier, s::Any, txt::Any)
    if typeof(s) <: AbstractComponent
        s = s.name
    end
    if typeof(txt) <: AbstractComponent
        push!(c.changes, "document.getElementById('$s').innerHTML = $(txt.name);")
       return 
    end
    txt = replace(txt, "`" => "\\`")
    txt = replace(txt, "\"" => "\\\"")
    txt = replace(txt, "''" => "\\'")
    push!(c.changes, "document.getElementById('$s').innerHTML = `$txt`;")
end

function set_children!(cm::AbstractComponentModifier, s::Any, v::Vector{Servable})
    if typeof(s) <: AbstractComponent
        s = s.name
    end
    set_text!(cm, s, join([string(serv) for serv in v]))
end

function append!(cm::AbstractComponentModifier, name::Any, child::Servable)
    if typeof(name) <: AbstractComponent
       name = name.name
    end
    txt = replace(string(child), "`" => "\\`", "\"" => "\\\"", "'" => "\\'")
    push!(cm.changes, "document.getElementById('$name').appendChild(document.createRange().createContextualFragment(`$txt`));")
end

function insert!(cm::AbstractComponentModifier, name::String, i::Int64, child::Servable)
    spoofconn = Toolips.SpoofConnection()
    write!(spoofconn, child)
    txt = replace(spoofconn.http.text, "`" => "\\`", "\"" => "\\\"", "'" => "\\'")
    push!(cm.changes, "document.getElementById('$name').insertBefore(document.createRange().createContextualFragment(`$txt`), document.getElementById('$name').children[$(i - 1)]);")
end

function sleep!(cm::AbstractComponentModifier, time::Int64)
    push!(cm.changes, "await new Promise(r => setTimeout(r, $time));")
end

function style!(cc::Modifier, name::Any,  sname::Style)
    sname = sname.name
    if typeof(name) <: AbstractComponent
        name = name.name
    end
    push!(cc.changes, "document.getElementById('$name').className = '$sname';")
end

function style!(cm::AbstractComponentModifier, name::Any, sty::Pair{String, String} ...)
    if typeof(name) <: AbstractComponent
        name = name.name
    end
    push!(cm.changes,
        join(("document.getElementById('$name').style['$(p[1])'] = '$(p[2])';" for p in sty)))
end

function set_style!(cm::AbstractComponentModifier, name::Any, sty::Pair{String, String} ...)
    sstring = join(["$(p[1]):$(p[2])" for p in sty], ";")
    if typeof(name) <: AbstractComponent
        name = name.name
    end
    push!(cm.changes, "document.getElementById('$name').style = '$sstring'")
end

write!(c::Connection, ac::AbstractComponentModifier) = write!(c, join(ac.changes))

alert!(cm::AbstractComponentModifier, s::AbstractString) = push!(cm.changes,
        "alert('$s');")

function focus!(cm::AbstractComponentModifier, name::String)
    push!(cm.changes, "document.getElementById('$name').focus();")
end

function blur!(cm::AbstractComponentModifier, name::String)
    push!(cm.changes, "document.getElementById('$name').blur();")
end

function redirect!(cm::AbstractComponentModifier, url::AbstractString, delay::Int64 = 0)
    push!(cm.changes, """setTimeout(
    function () {window.location.href = "$url";}, $delay);""")
end

function redirect_args!(cm::AbstractClientModifier, url::AbstractString, with::Pair{Symbol, Component{:property}} ...; 
    delay::Int64 = 0)
    args = join(("'$(w[1])=' + $(w[2].name)" for w in with), " + ")
    push!(cm.changes, """setTimeout(
    function () {window.location.href = "$url" + "?" + $args;}, $delay);""")
end

function next!(f::Function, cl::AbstractComponentModifier, comp::Any)
    if typeof(comp) <: AbstractComponent
        comp = comp.name
    end
    newcl = ClientModifier()
    f(newcl)
    fcl = funccl(newcl)
    push!(cl.changes,
    "document.getElementById('$comp').addEventListener('transitionend', $fcl);")
end

function update!(cm::AbstractComponentModifier, ppane::AbstractComponent, plot::Any)
    io::IOBuffer = IOBuffer();
    show(io, "text/html", plot)
    data::String = String(io.data)
    data = replace(data,
     """<?xml version=\"1.0\" encoding=\"utf-8\"?>\n""" => "")
    set_text!(cm, ppane.name, data)
end

function update_base64!(cm::AbstractComponentModifier, name::String, raw::Any,
    filetype::String = "png")
    io = IOBuffer();
    b64 = ToolipsServables.Base64.Base64EncodePipe(io)
    show(b64, "image/$filetype", raw)
    close(b64)
    mysrc = String(io.data)
    cm[name] = "src" => "data:image/$filetype;base64," * mysrc
end