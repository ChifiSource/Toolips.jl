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
    return(http -> write_file(URI, http))
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
         label = "Button")
        action = "/connect/$name"
        html = """<button name="$name" value="upvote">$label</button>"""
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
        cols::Int64 = 50, text = "", onAction = http -> "")
        html = """
        <textarea id="$name" name="$name" rows="$rows" cols="$cols" maxlength = "$maxlength">
        $text
        </textarea>"""
        f(http) = """<form action="$action">
        <textarea id="$name" name="$name" rows="$rows" cols="$cols" maxlength = "$maxlength">
        $text
        </textarea>
        </form>"""
        new(name, text, maxlength, rows, cols, f, html, onAction)
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
include("methods.jl")
include("../server/serve.jl")
