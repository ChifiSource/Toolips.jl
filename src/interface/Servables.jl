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
ul(name::String = ""; args ...) = Component(name, "ul", args)::Component
li(name::String = ""; args ...) = Component(name, "li", args)::Component
divider(name::String = ""; args ...) = Component(name, "div", args)::Component
br(name::String = ""; args ...) = Component(name, "/br", args)::Component
i(name::String = ""; args ...) = Component(name, "i", args)::Component
title(name::String = ""; args ...) = Component(name, "title", args)::Component
span(name::String = ""; args ...) = Component(name, "span", args)::Component
iframe(name::String = ""; args ...) = Component(name, "iframe", args)::Component
svg(name::String = ""; args ...) = Component(name, "svg", args)::Component
element(name::String = ""; args ...) = Component(name, "element", args)::Component
label(name::String = ""; args ...) = Component(name, "label", args)::Component
script(name::String = ""; args ...) = Component(name, "script", args)::Component
nav(name::String = ""; args ...) = Component(name, "nav", args)::Component
button(name::String = ""; args ...) = Component(name, "button", args)::Component
form(name::String = ""; args ...) = Component(name, "form", args)::Component
#==
Style
    Components
    ==#
mutable struct Animation <: StyleComponent
    name::String
    keyframes::Dict
    f::Function
    delay::Float64
    length::Float64
    iterations::Integer
    function Animation(name::String = "animation"; delay::Float64 = 0.0,
        length::Float64 = 5.2, iterations::Integer = 1)
        f(c::Connection) = begin
            s::String = "<style> @keyframes $name {"
            for anim in keys(keyframes)
                vals = keyframes[anim]
                s = s * "$anim {" * vals * "}"
            end
            write!(c, string(s * "}</style>"))
        end
        f() = begin
            s::String = "<style> @keyframes $name {"
            for anim in keys(keyframes)
                vals = keyframes[anim]
                s = s * "$anim {" * vals * "}"
            end
            string(s * "}</style>")::String
        end
        keyframes::Dict = Dict()
        new(name, keyframes, f, delay, length, iterations)
    end
end

mutable struct Style <: StyleComponent
    name::String
    f::Function
    properties::Dict{Any, Any}
    extras::String
    function Style(name::String; props ...)
        properties::Dict = Dict{Any, Any}(props)
        extras::String = ""
        f(c::Connection) = begin
            css = "<style>.$name { "
            for rule in keys(properties)
                property = string(rule)
                value = string(properties[rule])
                css = css * "$property: $value; "
            end
            css = css * "}</style>" * extras
            write!(c, css)
        end
        new(name::String, f::Function, properties::Dict, extras)::Style
    end
end
