abstract type HTMLComponent <: Component end
abstract type JavaScriptComponent <: Component end
abstract type CSSComponent <: Component end

#== component types
The component types are important because they delimit how much effort should be
given by the renderer, instead==#
mutable struct Heading <: HTMLComponent
    tag::String
    level::Int64
    string::String
    function Heading(s::String, level::Int64 = 1)
        tag = string("<h", string(level), ">", s, "</h", string(level), ">")
        new(tag, level, string)
    end
end

mutable struct Page <: Component
    components::Vector{Component}
    add::Function
    function Page()
        components = []
        add(x::Component) = _add(components, x)
    end
end
_add(components, x) = push!(components, x)
include("renderer.jl")
include("../server/serve.jl")
