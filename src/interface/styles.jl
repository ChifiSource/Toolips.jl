

abstract type AbstractStyle <: Component end
abstract type StyleComponent <: Component end

mutable struct StyleSheet <: Component
    name::String
    html::String
    f::Function
    components::Vector{Style}
    function StyleSheet(name::String = "Toolips", styles::Vector{Style})

    end
end
@keyframes example {
  from {background-color: red;}
  to {background-color: yellow;}
}

mutable struct Style <: AbstractStyle

end

mutable struct Animation <: AbstractStyle
    name::String
    html::String
    expression::Expr
    f::Function
    apply::Function
    function Animation(name::String = "animation")

    end
end

mutable struct Border <: StyleComponent
    keyframes::
end
