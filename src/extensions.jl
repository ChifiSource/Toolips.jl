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
            crayons = [Crayon(foreground  = :light_blue, bold = true), Crayon(foreground = :yellow, bold = true), 
            Crayon(foreground = :red, bold = true)]
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
    script("doc$event", text = scrpt)
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

"""
```julia
set_text!(c::AbstractComponentModifier, s::Any, txt::String) -> ::Nothing
```
---
Sets the text of the `Component` (or `Component` `name`) `s`.
#### example
```example
using Toolips
home = route("/") do c::Connection
    mytextbox = div("sampletext", text = "text will change", align = "center")
    changetxt = button("changer", text = "change text", align = "center")
    on(changetxt, "click") do cl::ClientModifier
        set_text!(cl, mytextbox, "text changed!")
    end
    write!(c, mytextbox, changetxt)
end
```
"""
function set_text!(c::AbstractComponentModifier, s::Any, txt::String)
    if typeof(s) <: AbstractComponent
        s = s.name
    end
    txt = replace(txt, "`" => "\\`", "\"" => "\\\"", "''" => "\\'")
    push!(c.changes, "document.getElementById('$s').innerHTML = `$txt`;")
    nothing::Nothing
end

"""
```julia
set_children!(cm::AbstractComponentModifier, s::Any, v::Vector{<:Servable}) -> ::Nothing
```
---
`set_children!` will set the children of `s`, a `Component` or `Component`'s `name`, to `v`.
#### example
```example
using Toolips
home = route("/") do c::Connection
    mychildbox = div("sampletext", text = "text will change", align = "center")
    change = button("changer", text = "change text")
    on(change, "click") do cl::ClientModifier
        childs = [div("sample", text = string(x)) for x in 1:5]
        set_children!(cl, mychildbox, childs)
    end
    write!(c, mychildbox, change)
end
```
"""
function set_children!(cm::AbstractComponentModifier, s::Any, v::Vector{<:Servable})
    if typeof(s) <: AbstractComponent
        s = s.name
    end
    set_text!(cm, s, join(string(serv) for serv in v))::Nothing
end

"""
```julia
append!(cm::AbstractComponentModifier, name::Any, child::AbstractComponent) -> ::Nothing
```
---
Appends the `Component` `child` to the `Component` or `Component `name` provided in the argument `name`.
#### example
```example
using Toolips
home = route("/") do c::Connection
    mychildbox = div("sampletext", text = "text will change", align = "center")
    change = button("changer", text = "change text")
    on(change, "click") do cl::ClientModifier
        newsect = a("anchor", text = "hello")
        style!(newsect, "opacity" => 50percent, "color" => "red")
        append!(cl, mychildbox, newsect)
    end
    write!(c, mychildbox, change)
end
```
"""
function append!(cm::AbstractComponentModifier, name::Any, child::AbstractComponent)
    if typeof(name) <: AbstractComponent
       name = name.name
    end
    txt::String = replace(string(child), "`" => "\\`", "\"" => "\\\"", "'" => "\\'")
    push!(cm.changes, "document.getElementById('$name').appendChild(document.createRange().createContextualFragment(`$txt`));")
    nothing::Nothing
end

"""
```julia
insert!(cm::AbstractComponentModifier, name::String, i::Int64, child::AbstractComponent) -> ::Nothing
```
---
Inserts `child` into `name` (a `Component` or its `name`) at index `i`. Note that, in true Julia fashion, 
indexes start at 1.
#### example
```example
using Toolips
home = route("/") do c::Connection
    mychildbox = div("sampletext", text = "text will change", align = "center")
    change = button("changer", text = "change text")
    firstsect = a("an", text = "initial message")
    push!(mychildbox, firstsect)
    on(change, "click") do cl::ClientModifier
        newsect = a("anchor", text = "second message")
        style!(newsect, "opacity" => 50percent, "color" => "red")
        insert!(cl, mychildbox, 1, newsect)
    end
    write!(c, mychildbox, change)
end
```
"""
function insert!(cm::AbstractComponentModifier, name::String, i::Int64, child::AbstractComponent)
    txt::String = replace(string(child), "`" => "\\`", "\"" => "\\\"", "'" => "\\'")
    push!(cm.changes, "document.getElementById('$name').insertBefore(document.createRange().createContextualFragment(`$txt`), document.getElementById('$name').children[$(i - 1)]);")
    nothing::Nothing
end

"""
```julia
sleep!(cm::AbstractComponentModifier, time::Any) -> ::Nothing
```
---
`sleep!` will cause a client-side timeout for `time` milliseconds. This can be used to delay 
different actions in a callback, which might be especially useful in the `ClientModifier` context.
#### example
```example
using Toolips
home = route("/") do c::Connection
    mychildbox = div("sampletext", text = "text will change", align = "center")
    change = button("changer", text = "change text")
    firstsect = a("an", text = "initial message")
    push!(mychildbox, firstsect)
    on(change, "click") do cl::ClientModifier
        newsect = a("anchor", text = "second message")
        style!(newsect, "opacity" => 50percent, "color" => "red")
        insert!(cl, mychildbox, 1, newsect)
        sleep!(cl, 500)
        style!(cl, change, "background-color" => "black", "color" => "white")
    end
    write!(c, mychildbox, change)
end
```
"""
function sleep!(cm::AbstractComponentModifier, time::Any)
    push!(cm.changes, "await new Promise(r => setTimeout(r, $time));")
    nothing::Nothing
end

"""
```julia
style!(cm::AbstractComponentModifier, name::Any, sty::Pair{String, <:Any} ...) -> ::Nothing
```
---
Styles `name` with the stylepairs `sty` in a callback. Note that `style!` will only add to the style, 
whereas `set_style!` may be used to change the style. `name` should be a `Component` or a `Component`'s name.
```example
using Toolips
home = route("/") do c::Connection
    change = button("changer", text = "change text")
    on(change, "click") do cl::ClientModifier
        style!(cl, change, "background-color" => "green", "color" => "white")
    end
    write!(c, change)
end
```
"""
function style!(cm::AbstractComponentModifier, name::Any, sty::Pair{String, <:Any} ...)
    if typeof(name) <: AbstractComponent
        name = name.name
    end
    push!(cm.changes,
        join(("document.getElementById('$name').style['$(p[1])'] = '$(p[2])';" for p in sty)))
    nothing::Nothing
end

"""
```julia
set_style!(cm::AbstractComponentModifier, name::Any, sty::Pair{String, <:Any} ...) -> ::Nothing
```
---
Sets the style of the `Component` `name` (provided as itself or its `Component.name`) to `sty` in a callback. 
Note that this function sets style, removing all previous styles. In order to simply add to the style, or alter it, 
    use `style!(::AbstractComponentModifier, ...)`.
```example
using Toolips
home = route("/") do c::Connection
    change = button("changer", text = "change text")
    style!(change, "color" => "white", "background-color" => "darkred")
    on(change, "click") do cl::ClientModifier
        set_style!(cl, change, "background-color" => "green")
    end
    write!(c, change)
end
```
"""
function set_style!(cm::AbstractComponentModifier, name::Any, sty::Pair{String, String} ...)
    sstring::String = join(("$(p[1]):$(p[2])" for p in sty), ";")
    if typeof(name) <: AbstractComponent
        name = name.name
    end
    push!(cm.changes, "document.getElementById('$name').style = '$sstring'")
    nothing::Nothing
end

write!(c::Connection, ac::AbstractComponentModifier) = write!(c, join(ac.changes))

"""
```julia
alert!(cm::AbstractComponentModifier, s::Striing) -> ::Nothing
```
---
Alerts the client with the `String` `s` in a callback.
```example
module Server
using Toolips
home = route("/") do c::Connection
    albutt = button("changer", text = "alert me!")
    style!(change, "color" => "white", "background-color" => "darkred")
    on(albutt, "click") do cl::ClientModifier
        alert!(cl, "hello world!")
    end
    write!(c, albut)
end

export home, start!
end
```
"""
alert!(cm::AbstractComponentModifier, s::String) = push!(cm.changes, "alert('$s');"); nothing::Nothing

"""
```julia
focus!(cm::AbstractComponentModifier, name::String) -> ::Nothing
```
---
Focuses the `Component` provided in `name` in a callback from the `Client`. `name` will be either 
a `Component`, or the `Component`'s `name`. `focus!` will put the user's cursor/text input into the element. 
The inverse to `focus!` is `blur!`.
```example
using Toolips
home = route("/") do c::Connection
    tbox = textdiv("sample")
    style!(tbox, "background-color" => "red", "color" => "white", "padding" => 5px)
    change = button("changer", text = "enter your name")
    on(change, "click") do cl::ClientModifier
        focus!(cl, tbox)
    end
    write!(c, tbox, change)
end
```
"""
function focus!(cm::AbstractComponentModifier, name::Any)
    push!(cm.changes, "document.getElementById('$name').focus();")
end

"""
```julia
blur!(cm::AbstractComponentModifier, name::String) -> ::Nothing
```
---
Un-focuses the `Component` provided in `name` in a callback from the `Client`. `name` will be either 
a `Component`, or the `Component`'s `name`. This will unselect the currently focused element, the inverse of 
`focus!`
```example
module Server
using Toolips

home = route("/") do c::Connection
    tbox = textdiv("sample")
    style!(tbox, "background-color" => "red", "color" => "white", "padding" => 5px)
    change = button("changer", text = "enter your name")
    on(change, "click") do cl::ClientModifier
        focus!(cl, tbox)
        sleep!(cl, 20)
        blur!(cl, tbox)
    end
    write!(c, tbox, change)
end

export home, start!
end
```
"""
function blur!(cm::AbstractComponentModifier, name::String)
    push!(cm.changes, "document.getElementById('$name').blur();")
    nothing::Nothing
end

"""
```julia
redirect!(cm::AbstractComponentModifier, url::AbstractString, delay::Int64 = 0) -> ::Nothing
```
---
`redirect!` will cause the client to send a `GET` request to `url`. `delay` can be used to add a millisecond delay. 
This can also be used for navigating users around your website. It might also be useful to check out `redirect_args!` 
    for redirecting a `ClientModifier` with arguments.
```example
using Toolips
home = route("/") do c::Connection
    change = button("changer", text = "go to github")
    on(change, "click") do cl::ClientModifier
        redirect!(cl, "https://github.com/")
    end
    write!(c, hange)
end
```
"""
function redirect!(cm::AbstractComponentModifier, url::AbstractString, delay::Int64 = 0)
    push!(cm.changes, """setTimeout(
    function () {window.location.href = "$url";}, $delay);""")
end

"""
```julia
redirect_args!(cm::AbstractComponentModifier, url::AbstractString, with::Pair{Symbol, Component{:property}} ...) -> ::Nothing
```
---
`redirect_args!` is used to change redirects based on arguments entirely on the client side. In most cases, we will be using `redirect!` to 
move clients to a different page -- even with a `ClientModifier`. This provides a tool for the exception, where we want to work with `Component` 
properties on the client side. We are able to get `Component{:property}`'s back from a `ClientModifier` by using `getindex` or `get_text`. Note that this 
`ComponentProperty` is not a Julia-bound type, this is a representation of that property in JavaScript which is ran without Julia on the client. 
In order to run callbacks on the server, instead just use `ToolipsSession` and provide a `Connection` to `on`. (`using ToolipsSession; ?(on)`)
#### example
The following example is from the `Toolips` documentation site's searchbar. This example uses `get_text` to retrieve the text property. Note that 
`getindex` is used for regular properties, whereas `get_text` is exclusively used for text.
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
function redirect_args!(cm::AbstractClientModifier, url::AbstractString, with::Pair{Symbol, Component{:property}} ...; 
    delay::Int64 = 0)
    args = join(("'$(w[1])=' + $(w[2].name)" for w in with), " + ")
    push!(cm.changes, """setTimeout(
    function () {window.location.href = "$url" + "?" + $args;}, $delay);""")
    nothing::Nothing
end

"""
```julia
next!(f::Function, cl::AbstractComponentModifier, comp::Any) -> ::Nothing
```
---
`next!` creates a sequence of events to occur after a component's transition as ended. `comp` can be 
the component's `name` or the `Component` itself. Note that the `Component` has to be in a transition to 
use `next!`, which means we will need to mutate its style. For simply creating a delay, there is `sleep!` -- 
among other options. `next!` is ideal for multi-stage client-side animations, and interactive multi-stage callbacks.
```example
module AmericanServer
using Toolips
home = route("/") do c::Connection
    change = button("changer", text = "go to github", align = "center")
    # setting the transition time vvv
    style!(change, "transition" => 500ms)
    on(change, "click") do cl::ClientModifier
        style!(cl, change, "background-color" => "red")
        next!(cl, "changer") do cl2::ClientModifier
            style!(cl2, change, "background-color" => "white")
            next!(cl, "changer") do cl3::ClientModifier
                style!(cl3, change, "background-color" => "blue")
                set_text!(cl3, change, "amurica")
            end
        end
    end
    write!(c, change)
end
export home, start!
end

start!(AmericanServer)
```
"""
function next!(f::Function, cl::AbstractComponentModifier, comp::Any)
    if typeof(comp) <: AbstractComponent
        comp = comp.name
    end
    newcl::ClientModifier = ClientModifier()
    f(newcl)
    push!(cl.changes,
    "document.getElementById('$comp').addEventListener('transitionend', $(funccl(newcl)));")
    nothing::Nothing
end

"""
```julia
update!(cm::AbstractComponentModifier, ppane::Any, plot::Any) -> ::Nothing
```
---
`update!` is used to put a Julia object into a `Component` in a callback. This `Function` will 
use `show(io::IO, ::MIME{Symbol("text/html")}, PLOT::Any)` with your type. This being considered, ensure 
this binding exists.
"""
function update!(cm::AbstractComponentModifier, ppane::Any, plot::Any)
    io::IOBuffer = IOBuffer();
    show(io, "text/html", plot)
    data::String = String(io.data)
    data = replace(data,
     """<?xml version=\"1.0\" encoding=\"utf-8\"?>\n""" => "")
    set_text!(cm, ppane, data)::Nothing
end

"""
```julia
update_base64!(cm::AbstractComponentModifier, name::Any, raw::Any, filetype::String = "png") -> ::Nothing
```
---
This `Function` is used to update the `Base64` of a given `base64_img` inside of a callback. `name` in this case will 
be the `Component` or the `Component`'s `name` which should hold the image (this should be a `Component{:img}` or the name of one.)
##### example
```julia
module Example
using Toolips
using Toolips.Components
using Plots

plt = plot([5, 10, 15], [5, 10, 15])
plt2 = plot([1, 2, 7], [6, 4, 3])
home = route("/") do c::Connection
    comp = base64img("plot", plt)
    on(comp, "click") do cl::ClientModifier
        update_base64!(cl, comp, plt2)
    end
    write!(c, comp)
end

export home
end
```
"""
function update_base64!(cm::AbstractComponentModifier, name::Any, raw::Any,
    filetype::String = "png")
    io::IOBuffer = IOBuffer();
    b64::Base64EncodePipe = ToolipsServables.Base64.Base64EncodePipe(io)
    show(b64, "image/$filetype", raw)
    close(b64)
    mysrc::String = String(io.data)
    cm[name] = "src" => "data:image/$filetype;base64," * mysrc
end