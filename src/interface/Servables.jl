# Servables.jl
#==
Servable
    Core
==#
"""
### abstract type Servable
Servables are components that can be rendered into HTML via thier f()
function with the properties provided in their properties dict.
##### Consistencies
- f::Function - Function whose output to be written to http().
- properties::Dict - The properties of a given Servable. These are written
into the servable on the calling of f().
"""
abstract type Servable <: Any end

include("../server/Core.jl")


"""
### Component <: Servable
name::String
f::Function
properties::Dict
------------------
- name::String - The name field is the way that a component is denoted in code.
- f::Function - The function that gets called with the Connection as an
argument.
- properties::Dict - A dictionary of symbols and values.
------------------
##### constructors
Component(name::String, tag::String, properties::Dict)
"""
mutable struct Component <: Servable
    name::String
    f::Function
    properties::Dict{Any, Any}
    function Component(name::String = "", tag::String = "",
         properties::Dict = Dict{Any, Any}())
         properties[:children] = Vector{Any}()
         f(c::Connection) = begin
             open_tag::String = "<$tag id = $name "
             text::String = ""
             write!(c, open_tag)
             for property in keys(properties)
                 special_keys = [:text, :children]
                 if ~(property in special_keys)
                     prop::String = string(properties[property])
                     propkey::String = string(property)
                     write!(c, " $propkey = $prop")
                 else
                     if property == :text
                         text = properties[property]
                     end
                 end
             end
             write!(c, ">")
             if :children in keys(properties)
                 [write!(c, s) for s in properties[:children]]
            end
            write!(c, "$text</$tag>")
         end
         new(name, f, properties)::Component
    end
    Component(name::String, tag::String, props::Base.Pairs) = begin
        Component(name, tag, Dict{Any, Any}(props))
    end
end
#==
Base
    Components
==#
img(name::String = ""; args ...) = Component(name, "img", args)::Component
link(name::String = ""; args ...) = Component(name, "link", args)::Component
meta(name::String = ""; args ...) = Component(name, "meta", args)::Component
input(name::String = ""; args ...) = Component(name, "input", args)::Component
a(name::String = ""; args ...) = Component(name, "a", args)::Component
p(name::String = ""; args ...) = Component(name, "p", args)::Component
h(name::String = "", n::Int64 = 1; args ...) = Component(name, "h$n", args)::Component
button(name::String = ""; args ...) = Component(name, "button", args)::Component
ul(name::String = ""; args ...) = Component(name, "ul", args)::Component
li(name::String = ""; args ...) = Component(name, "li", args)::Component
divider(name::String = ""; args ...) = Component(name, "div", args)::Component
form(name::String = ""; args ...) = Component(name, "form", args)::Component
br(name::String = ""; args ...) = Component(name, "/br", args)::Component


function header(title::String = "Toolips App";
    icon::String = "", keywords::Array{String} = [], author::String = "",
    description::String = "", links::Vector{Component} = Vector{Component}())
    cs::Vector{Component} = Vector{Component}()
    push!(cs, metadata())
    push!(cs, link("icon", rel = "icon", href = icon))
    push!(cs, metadata("keywords", join(keywords, ",")))
    push!(cs, metadata("description", description))
    [push!(cs, link) for link in cs]
    newc = Component("", "header")
    newc[:children] = cs
    newc::Component
end
#==
Style
    Components
    ==#
abstract type StyleComponent <: Servable end

mutable struct Animation <: StyleComponent
    name::String
    keyframes::Dict
    f::Function
    delay::Float64
    length::Float64
    function Animation(name::String = "animation"; delay::Float64 = 0.0,
        length::Float64 = 5.2)
        f(c) = begin
            s::String = "<style> @keyframes $name {"
            for anim in keys(keyframes)
                vals = keyframes[anim]
                s = s * "$anim {" * vals * "}"
            end
            write!(c, s * "}</style>")
        end
        keyframes::Dict = Dict()
        new(name, keyframes, f, delay, length)
    end
end

mutable struct Style <: StyleComponent
    name::String
    f::Function
    properties::Dict
    function Style(name::String)
        properties::Dict = Dict()
        f(c::Connection) = begin
            css = "<style>$name { "
            for rule in keys(properties)
                property = string(rule)
                value = string(properties[rule])
                css = css * "$property: $value; "
            end
            css * "}</style>"
            write!(c, css)
        end
        new(name::String, f::Function, properties::Dict)
    end
end
