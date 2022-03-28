#==
Servables!
==#

#==
 HTML
    Components
==#
function html(hypertxt::String)
    return(http -> hypertxt)
end
mutable struct Button

end
function html_file(hypertxt::String)

end

function css(css::String)
    return(http -> "<style>" * css * "<style>")
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

mutable struct TButton <: FormComponent
    name::String
    action::String
    label::String
    f::Function
    onClick::Function
    html::String
    function TButton(name::String; onClick::Function = http -> "",
         label = "Button")
        action = "/connect/$name"
        html = """
        <form action="$action" method="post">
            <button name="foo" value="upvote">$label</button>
            </form>
        """
        f(http) = html
        new(name, action, label, f, onClick, html)
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
    function Page(components, title = "Toolips Webapp"; icon = "/")
        f(http) = generate_page(http, title, components, icon)
        add(x::Function) = push!(components, x)
        add(x::FormComponent) = push!(components, x)
        new(f, components, add, title, icon)
    end
end

function generate_page(http, title, components, icon = "/")
    html = "<head>" * "<title>$title</title>"
end

function generate_head(title, icon)

end
include("methods.jl")
include("../server/serve.jl")
