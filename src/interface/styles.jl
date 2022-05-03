Canvas = """.newspaper {
column-width: 100px;
}
.column {
float: left;
width: $perc_txt;
}
.row:after {
content: "";
display: table;
clear: both;
}"""

abstract type AbstractStyle <: Component end
abstract type StyleComponent end

mutable struct StyleSheet <: Component
    name::String
    f::Function
    components::Vector{AbstractStyle}
    function StyleSheet(name::String = "Toolips", styles::Vector{Style})
        f(http::HTTP.Stream) = join([c.f(http) for c in components])
        new(name, html, f, components)
    end
end

mutable struct Style{T} <: AbstractStyle
    name::String
    class::T
    html::String
    f::Function
    rules::Dict
    add::Function
    function Style(name::String, class::Any; animation = nothing)
        f(http::HTTP.Stream) = begin
            name = string(class)
            css = "<style>$name { "
            if animation != nothing
                anim = animation.name
                css = css * "animation: $anim;"
            end
            for rule in rules
                property = string(rule)
                value = string(rules[rule])
                css = css * "$property: $value; "
            end
            css * "}</style>"
        end
        add(sc::StyleComponent) = merge!(rules, c.f())
        add(newrule::Pair{Symbol, Any}) = push!(rules, newrule)
        new{String}(name::String, class::String,
         html::String, animation::Any, f::Function, rules::Dict, add::Function)
    end
end

mutable struct Animation <: StyleComponent
    name::String
    keyframes::Dict
    f::Function
    delay::Float64
    length::Float64
    function Animation(name::String = "animation"; delay::Float64 = 0,
        length::Float64 = 0)
        f(http) = begin

        end
    end
end

animate!(s::AbstractStyle, a::Animation) = s.rules[:animation] = a.name
style!(c::Component, s::Style) = c.properties[:class] = s.name
copystyle!(c::Component, c2::Component) = c.properties[:class] = c2.properties[:class]

macro keyframes!(anim::Animation, percentage::Float64, expr::Expression)
    percent = _percentage_text(percentage)
    try
        anim.keyframes[string(percentage)] = vcat(anim.keyframes[string(method)]
        eval(expr))
    catch
        anim.keyframes[Symbol("$percent")] = eval(expr)
    end
end

macro keyframes!(anim::Animation, percentage::Int64, expr::Expression)
    keyframes!(anim, float(percentage), expr)
end

macro keyframes!(anim::Animation, method::Symbol, expr::Expression)
    try
        anim.keyframes[string(method)] = vcat(anim.keyframes[string(method)],
        eval(expr))
    catch
        anim.keyframes[string(method)] = eval(expr)
    end
end
