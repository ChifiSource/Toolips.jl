abstract type AbstractStyle <: Component end
abstract type StyleComponent end

mutable struct StyleSheet <: Component
    name::String
    html::String
    f::Function
    components::Vector{AbstractStyle}
    function StyleSheet(name::String = "Toolips", styles::Vector{Style})
        html = "<style></style>"
        f(http::HTTP.Stream) = join([c.f(http) for c in components])
        new(name, html, f, components)
    end
end

mutable struct Style{T} <: AbstractStyle
    name::String
    class::T
    html::String
    animation::Any
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
    html::String
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

mutable struct Border <: StyleComponent
    style::String
    color::String
    width::Integer
    f::Function
    function Border(; border = 2, width = 2, style = "solid")
        f() = Dict("border-style" => style,
        "color" => color, "width" => width)
        new(style, color, width, f)
    end
end

mutable struct Margins <: StyleComponent
    top::Integer
    right::Integer
    bottom::Integer
    left::Integer
    f::Function
    function Margins(; top = 0, right = 0, left = 0, bottom = 0)
        f() = Dict("top-margin" => top,
        "left-margin" => left, "right-margin" => right,
        "bottom-margin" => bottom)
        new(top, right, bottom, left, f)
    end
end
