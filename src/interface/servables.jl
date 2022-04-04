#==
Servables!
==#

#==
 text/html
    Components
==#

function html(hypertxt::String)
    return(http -> hypertxt)
end

function html_file(URI::String)
    return(http -> HTTP.Response(200, read(URI))
end

function css(css::String)
    return(http -> "<style>" * css * "</style>")
end

function css_file(URI::String)
    http -> """<link rel="stylesheet" href="$URI">"""
end

function js(js::String)
    return(http -> "<script>" * js * "</script>")
end

function js_file(URI::String)
    http -> """<script src="$URI"></script>"""
end
#==
Functions
==#
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
abstract type FormComponent end

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

mutable struct TextBox
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


mutable struct RadioSet
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


mutable struct Slider
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
mutable struct Page
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
Canvas
==#
abstract type JSComponent end
macro script(jsc::JSComponent, inline::Symbol ...)

end
mutable struct Canvas <: JSComponent
    name::String
    width::Int64
    height::Int64
    script::String
    html::String
    f::Function
    function Canvas(name = "canvas"; width = 200, height = 200)
        new(name, width, height)
    end
end
function script_object(ctx, name, f)

end
include("methods.jl")
include("../server/serve.jl")
