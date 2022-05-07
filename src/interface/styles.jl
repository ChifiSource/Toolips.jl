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

abstract type StyleComponent <: Servable end

mutable struct Style <: StyleComponent
    name::String
    f::Function
    rules::Dict
    function Style(name::String; animation::Animation = nothing)
        f(c::Connection) = begin
            css = "<style>$name { "
            if animation != nothing
                anim = animation.name
                css = css * "animation: $anim;"
            end
            for rule in keys(rules)
                property = string(rule)
                value = string(rules[rule])
                css = css * "$property: $value; "
            end
            css * "}</style>"
        end
        new(name::String, f::Function, rules::Dict)
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

animate!(s::StyleComponent, a::Animation) = s.rules[:animation] = a.name

style!(c::Servable, s::Style) = c.properties[:class] = s.name

function copystyle!(c::Servable, c2::Servable)
    c.properties[:class] = c2.properties[:class]
end

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
