#==
Servables!
==#
abstract type Servable end
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
    Workable
        Components
        ==#
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
to do when clicked. Name will also become the id inside of the Document.
------------------

"""
mutable struct Component <: Servable
    name::String
    f::Function
    properties::Dict
    function Component(name::String = "", tag::String = "",
         properties::Dict = Dict())
         f(http::HTTP.Stream) = begin
             open_tag = "<$tag id = $name "
             for property in keys(properties)
                 if ~(property == :action || property == :text)
                     prop = properties[property]
                     propstring = string(property)
                     open_tag = " $open_tag $property"
                 end
             end
             open_tag * ">$text</$tag>"
         end
         new(name, f, properties)
    end
end
mutable struct Container <: Servable
    name::String
    tag::String
    ID::Integer
    components::Vector{Component}
    properties::Dict
    function Container()

    end
end

function Input(name::String, type::String = "text")
    Component(name, "input", Dict(:type => type))::Component
end

function TextArea(name::String; maxlength::Int64 = 25, rows::Int64 = 25,
                cols::Int64 = 50, text::String = "")
        Component(name, "textarea", Dict(:maxlength => maxlength, :rows => rows,
         :text => text, :cols => cols))::Component
end

function Button(name::String = "Button"; text::String = "", value::Integer = "",
                action::String = "/")
    Component(name, "button", Dict(:text => text, :value => 5))::Component
end

function P(name::String; maxlength::Int64 = 25, text::String = "")
    Component(name, "p", Dict(:maxlength => maxlength, :text => text))::Component
end

FileInput(name::String) = Input(name, "file")::Component

function Option(name::String; )

end

function RadioInput(name::String; multiple::Bool = false)
    Component(name, "select", Dict(:multiple => multiple))
end

function SliderInput(name::String; range::UnitRange)

end

mutable struct Slider <: FormComponent
    name::String
    range::UnitRange
    f::Function
    html::String
    onAction::Function
    action::String
    class::Any
    function Slider(name::String; range = 0:100, onAction = http -> "",
        class::Any = Slider)
        min, max = range[1], range[2]
        action = "/connect/$name"
        html = """<input type="range" id="$name" name="$name"
               min="$min" max="$max">"""
        f(http) = """<form action="$action">
               $html
               </form>"""
        new(name, range, f, html, onAction, action, class)
    end
end


mutable struct Form <: FormComponent
    action::String
    f::Function
    html::String
    components::AbstractArray
    onAction::Function
    class::Any
    function Form(components...; onAction::Any = http -> "", action::String = "",
        method::String = "GET", class::Any = Form)
        html = """<form action="$action" method = "$method">"""
        components = [c for c in components]
        for comp in components
            html = html * comp.html
        end
        html = html * "</form>"
        f(http) = html
        new(action, f, html, components, onAction)
    end
end

mutable struct Header <: Component
    title::String
    icon::String
    keywords::Array
    author::String
    description::String
    f::Function
    stylesheet::StyleSheet
    links::Link
    function Header(; title::String = "Toolips App", icon::String = "/icon.png",
         keywords::Array{String} = [],
        author::String = "Toolips", description::String = "A new Toolips App",
        stylesheet::StyleSheet = ToolipsDefaultStyle())
        kws = join(keywords)
        f(http) = """
        <meta charset="UTF-8">
        <meta name="description" content="$description">
        <meta name="keywords" content="$kws">
        <meta name="author" content="$author">
        <link rel="icon" href="$icon">
        <meta name="viewport" content="width=device-width, initial-scale=1.
        <title>$title</title>
        """
        new(title, icon, keywords, author, description, f, stylesheet)
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
    header::Header
    function Page(components::AbstractVector = [], header::Header = Header())
        f(http) = generate_page(http, header)
        add(x::Function) = push!(components, x)
        add(x::Component) = push!(components, x)
        new(f::Function, components::AbstractVector, add::Function, header::Header)
    end
end

function generate_page(http::HTTP.Stream, header::Header)
    header = header.f(http)
    write(http, header)
    body = ""
    for comp in components
        try
            body::String = body * comp.f(http)
        catch
            body::String = body * comp(http)
        end
    end
    body
end
#==
Other
    Components
==#
abstract type ComponentPart <: Component end
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
    class::Any
    function Canvas(name = "canvas"; width = 200, height = 200, mode = "2d",
        class::Any = Canvas)
        ctx = Context(mode, name)
        html = """<canvas id="$name" width="$width" height="$height"></canvas>"""
        context(f::Function) = f(ctx)
        f(http) = """<canvas id="$name" width="$width" height="$height"script = '""" * join(ctx.codestrings) * "'</script></canvas>"
        new(name, width, height, html, ctx, context, f, class)
    end
end

abstract type ListComponent <: Component end

mutable struct List <: ListComponent
    name::String
    label::String
    html::String
    f::Function
    href::String
    class::Any
    style::String
    function List(name::String = "list"; label::String = "hello world!",
        href::String = "",
        class::Any = List, style::String = "")
        if href != ""
            href = "href='$href'"
        end
        html = """<li id='$name'><a $href>$label</a></li>"""
        f(http) = html
        new(name, label, html, f, href, class, style)
    end
end

mutable struct UnorderedList
    name::String
    html::String
    f::Function
    lists::Vector{List}
    class::Any
    function UnorderedList(name::String = "ul", comps::Array{List} = [];
        class::Any = UnorderedList)
        html = "<ul id = '$name'>"

        f(http) = "<ul id='$name'>" * join([l.f(http) for l in comps]) * "</ul>"
        new(name, html, f, comps, class)
    end
     function UnorderedList(name::String = "ul"; class::Any = UnorderedList)
        UnorderedList(name, [], class = class)
    end
    function UnorderedList(comps::Vector{List}; class::Any = UnorderedList)
        name = ""
        UnorderedList(name, comps, class = class)
    end
end

mutable struct A <: ComponentPart
    name::String
    href::String
    f::Function
    html::String
    class::Any
    style::Any
    function A(name = "a"; href = "", label = "a", style::String = "",
         class::Any = A)
        f(http) = "<a id='$name' href='$href' style = '$style'>$label</a>"
        html = "<a id='$name' href='$href'>$label</a>"
        new(name, href, f, html, style, class)
    end
end

mutable struct DropDown <: Component
    name::String
    html::String
    href::String
    As::AbstractArray{Component}
    f::Function
    class::Any
    function DropDrown(name::String = "dropdown", As::A ...;
        label::String = "dropdown", href::String = "#",
        class::Any = DropDown)
        html = "<div id='$name' href='$href'></div>"
        f(http) = begin
            """<div id="$name">
              <button class="dropbtn">$label
                </button>
                <div id=$name-content>
                """ * join([a.f(http) for a in As]) * "</div></div>"
            end
            new(name, html, href, As, f, class)
        end
end

mutable struct DocumentFunction <: Component
    name::String
    f::Function
    actions::Array{String}
    function DocumentFunction(name::String = "func"; actions::Array{String} = Vector{String}())
        f(http) = begin
            "<script>" * join(actions) * "</script>"
        end
        new(name, html, f, actions)
    end
end

mutable struct Div <: Component
    name::String
    f::Function
    components::AbstractArray
    align::String
    function Div(name::String, components::Vector{Component} = [];
         align = "left")
         f(http::HTTP.Stream) = begin
             "<div></div>"
    end
end


include("methods.jl")
include("../server/serve.jl")
include("routing.jl")
