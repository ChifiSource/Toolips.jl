abstract type StyleComponent <: Component end

mutable struct Styler{C<:Component} <: StyleComponent
    name::String
    html::String
    f::Function
    rules::Dict
    keyframes::Function
    useid::Bool
    component::C
    function Style(name::String = "style"; rules = Dict(), useid = false)
        keyframes(f::Function) = animate(style, f)
        rules = TLDEFAULT_doc
        html = "<style></style>"
        f(http) = "<style>" * rules_css(rules) * "</style>"
    end
    function Style(c::Component)
        rules = default_style(typeof(c))
    end

end

copystyle!(c::StyleComponent, c2::StyleComponent) = c.rules = c2.rules

function default_style()

end
