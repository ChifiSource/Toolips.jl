#==
Servables!
==#
abstract type Component end
#==
 text/html
    Components
==#
"""
### html(::String) -> ::Function
------------------
Creates a servable from the provided string, which should be HTML.
#### example
"""
function html(hypertxt::String)
    return(http -> hypertxt)
end

"""
### html_file(URI::String) -> ::Function
------------------
Creates a servable which will read and return the file denoted by its path in
URI.
#### example
"""
function html_file(URI::String)
    return(http -> HTTP.Response(200, read(URI)))
end

"""
### file(URI::String) -> ::Function
------------------
Creates a servable which will read and return the file denoted by its path in
URI.
#### example
"""
function file(URI::String)
    return(http -> HTTP.Response(200, read(URI)))
end

"""
### html(::String) -> ::Function
------------------
Creates a servable from the provided string, which should be CSS.
#### example
"""
function css(css::String)
    return(http -> "<style>" * css * "</style>")
end

"""
### css_file(URI::String) -> ::Function
------------------
Creates a servable which will read and return the file denoted by its path in
URI.
#### example
"""
function css_file(URI::String)
    http -> """<link rel="stylesheet" href="$URI">"""
end

"""
### html(::String) -> ::Function
------------------
Creates a servable from the provided string, which should be JavaScript.
#### example
"""
function js(js::String)
    return(http -> "<script>" * js * "</script>")
end

"""
### js_file(URI::String) -> ::Function
------------------
Creates a servable which will read and return the file denoted by its path in
URI.
#### example
"""
function js_file(URI::String)
    http -> """<script src="$URI"></script>"""
end
#==
Functions
==#
"""
### fn(::Function) -> ::Function
------------------
Turns any function into a servable. Functions can optionally take the single
    positional argument "http."
#### example

"""
function fn(f::Function)
    m = first(methods(f))
    if m.nargs > 2 | m.nargs < 1
        throw(ArgumentError("Expected either 1 or 2 arguments."))
    elseif m.nargs == 2
        http -> f(http)
    else
        http -> f()
    end
end

    #==
    Interactive
        Components
        ==#
abstract type FormComponent <: Component end
"""
### Button
name::String
action::String
label::String
f::Function
onAction::Function
html::String
------------------
A button is a form component that allows Toolips.jl to communicate with button
clicks on a web-page. The **onAction** function denotes what the button is
to do when clicked. Name will also become the id inside of the Document. \
------------------

"""
mutable struct Button <: FormComponent
    name::String
    action::String
    label::String
    f::Function
    onAction::Function
    html::String
    function Button(name::String; onAction::Function = http -> "",
         label = "Button", value = "none")
        action = "/connect/$name"
        html = """<button name="$name" value="$value">$label</button>"""
        f(http) = """<form action="$action" method="post">""" * html * "</form>"
        new(name, action, label, f, onAction, html)
    end
end

mutable struct TextArea <: FormComponent
    name::String
    text::String
    maxlength::Int64
    rows::Int64
    cols::Int64
    f::Function
    html::String
    onAction::Function
    function TextArea(name::String; maxlength::Int64 = 25, rows::Int64 = 25,
        cols::Int64 = 50, text = "~", onAction = http -> "")
        html = """
        <textarea id="$name" name="$name" rows="$rows" cols="$cols" maxlength = "$maxlength">
        $text
        </textarea>"""
        f(http) = """<form action="$action">
        $html
        </form>"""
        set_txt(to::String) = begin
            upperlower = split(html, "~")
        end
        new(name, text, maxlength, rows, cols, f, html, onAction)
    end
end

mutable struct TextBox <: FormComponent
    name::String
    text::String
    maxlength::Int64
    f::Function
    html::String
    onAction::Function
    function Text(name::String; maxlength::Int64 = 25, text::String = "",
        onAction = http -> "")
        html = """
        <input type = "text" id = "$name" name = "$name" maxlength = "$maxlength">
        $text
        </input>
        """
        f(http) = """<form action="$action">
        $html
        </form>"""
        new(name, text, mexlength, f, html, onAction)
    end
end


mutable struct RadioSet <: FormComponent
    name::String
    setdict::Dict
    f::Function
    html::String
    onAction::Function
    function RadioSet(name::String, setdict::Dict; onAction = http -> "",
        multiple = false)
        if multiple == true
            multiple = "multiple"
        else
            multiple = ""
        end
        htmlopen = """<select id="$name" name="$name" $multiple>"""
        for option in setdict
            label = setdic[option]
            htmlopen = htmlopen * """<option value="$option">$label</option>"""
        end
        html = htmlopen * "</select>"
        f(http) = """<form action="$action">
        $html
        </form>"""
        new(name, setdict, f, html, onAction)
    end
end


mutable struct Slider <: FormComponent
    name::String
    range::UnitRange
    f::Function
    html::String
    onAction::Function
    function Slider(name::String; range = 0:100, onAction = http -> "")
        min, max = range[1], range[2]
        html = """<input type="range" id="$name" name="$name"
               min="$min" max="$max">"""
        f(http) = """<form action="$action">
               $html
               </form>"""
        new(name, range, f, html, onAction)
    end
end


mutable struct Form <: FormComponent
    action::String
    f::Function
    html::String
    components::AbstractArray
    onAction::Function
    function Form(components...; onAction::Any = http -> "", action::String = "")
        html = """<form action="$action" method = "GET">"""
        components = [c for c in components]
        for comp in components
            html = html * comp.html
        end
        html = html * "</form>"
        f(http) = html
        new(action, f, html, components, onAction)
    end
end
#==
Page
==#
mutable struct Page <: Component
    f::Function
    components::AbstractVector
    add::Function
    # Document
    title::String
    icon::String
    function Page(components = [], title = "Toolips Webapp"; icon = "/")
        f(http) = generate_page(http, title, components, icon)
        add(x::Function) = push!(components, x)
        add(x::FormComponent) = push!(components, x)
        new(f, components, add, title, icon)
    end
end

function generate_page(http, title, components, icon = "/")
    html = "<head>" * "<title>$title</title>" * "</head>"
    write(http, html)
    body = ""
    for comp in components
        if typeof(comp) <: FormComponent
            body = body * comp.f(http)
        else
            body = body * comp(http)
        end
    end
    body
end
#==
Other
    Components
==#
abstract type ComponentPart end
mutable struct Context <: ComponentPart
    codestrings::AbstractArray
    update::Function
    fillRect::Function
    strokeRect::Function
    beginPath::Function
    closePath::Function
    moveTo::Function
    lineTo::Function
    fill::Function
    stroke::Function
    arc::Function
    rect::Function
    function Context(ctx::String = "2d", name::String = "canvas")
        codestrings = []
        push!(codestrings, """var canvas = document.getElementById("$name");
            var $namectx = canvas.getContext($ctx);""")
        namectx = "$name" * ctx
        update() = script = join(codestrings)
        rect(x::Integer, y::Integer, w::Integer, h::Integer) =
            push!(codestrings, "$namectx.rect($x, $y, $w, $h);")
        fillRect(x::Integer, y::Integer, w::Integer, h::Integer) = begin
            push!(codestrings, "$namectx.fillRect($x, $y, $w, $h);")
        end
        strokeRect(x::Integer, y::Integer, w::Integer, h::Integer) =
            push!(codestrings, "$namectx.strokeRect($x, $y, $w, $h);")
        arc(x, y, r, sa, ea, ccw) = begin
            push!(codestrings, "$namectx.arc($x, $y, $r, $sa, $ea, $ccw);")
        end
        beginPath() = begin
            push!(codestrings, "$namectx.beginPath();")
        end
        closePath() = begin
            push!(codestrings, "$namectx.closePath();")
        end
        moveTo(x::Integer, y::Integer) = begin
            push!(codestrings, "$namectx.moveTo($x, $y);")
        end
        lineTo(x::Integer, y::Integer) = begin
            push!(codestrings, "$namectx.lineTo($x, $y);")
        end
        fill() = begin
            push!(codestrings, "$namectx.fill();")
        end
        stroke() = begin
            push!(codestrings, "$namectx.stroke();")
        end
        new(codestrings, update, fillRect, strokeRect, beginPath, closePath, moveTo,
        lineTo, fill, stroke, arc, rect)
    end
end
mutable struct Canvas <: Component
    name::String
    width::Int64
    height::Int64
    html::String
    ctx::Context
    context::Function
    f::Function
    function Canvas(name = "canvas"; width = 200, height = 200, mode = "2d")
        ctx = Context(mode, name)
        html = """<canvas id="$name" width="$width" height="$height"></canvas>"""
        context(f::Function) = f(ctx)
        f(http) = """<canvas id="$name" width="$width" height="$height"><script>""" * join(ctx.codestrings) * "</script></canvas>"
        new(name, width, height, html, ctx, context, f)
    end
end

abstract type ListComponent <: Component end

mutable struct List <: ListComponent
    name::String
    label::String
    html::String
    f::Function
    href::String
    function List(name::String = "list"; label = "hello world!", href = "")
        if href != ""
            href = "href='$href'"
        end
        html = """<li id='$name'><a $href>$label</a></li>"""
        f(http) = html
        new(name, label, html, f, href)
    end
end

mutable struct UnorderedList
    name::String
    html::String
    f::Function
    lists::Vector{List}
    function UnorderedList(name::String = "ul", comps::Array{List} = [])
        html = "<ul id = '$name'>"

        f(http) = "<ul id='$name'>" * join([l.f(http) for l in comps]) * "</ul>"
        new(name, html, f, comps)
    end
     function UnorderedList(name::String = "ul")
        UnorderedList(name, comps)
    end
         function UnorderedList(comps::Vector{List})
        name = ""
        UnorderedList(name, comps)
    end
end

mutable struct DropDown <: Component

end

mutable struct A <: Component

end
include("methods.jl")
include("../server/serve.jl")
