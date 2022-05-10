#==
Servables!
==#
"""
### Servable
Consistencies
- f::Function - Function whose output to be written to http().
- properties::Dict - The properties of a given Servable.
"""
abstract type Servable end

include("../server/Core.jl")

"""
### File <: Servable
dir::String
f::Function
------------------
- dir::String - The directory of a file to serve.
- f::Function - Function whose output to be written to http().
------------------
##### constructors
File(dir::String)
"""
mutable struct File <: Servable
    dir::String
    f::Function
    function File(dir::String)
        f(c::Connection) = HTTP.Response(200, read(dir))
        new(dir, f)
    end
end

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
    properties::Dict
    function Component(name::String = "", tag::String = "",
         properties::Dict = Dict())
         f(c::Connection) = begin
             open_tag::String = "<$tag id = $name "
             text::String = ""
             for property in keys(properties)
                 if ~(property == :text)
                     prop::String = string(properties[property])
                     propkey::String = string(property)
                     open_tag = open_tag * " $propkey = $prop"
                 else
                     text = properties[property]
                 end
             end
             open_tag * ">$text</$tag>"
         end
         new(name, f, properties)::Component
    end
end

"""
### Container <: Servable
name::String
tag::String
components::Vector{Component}
f::Function
properties::Dict
add!::Function
------------------
- name::String -
------------------
##### constructors
Component(name::String, tag::String, properties::Dict)
"""
mutable struct Container <: Servable
    name::String
    tag::String
    components::Vector{Component}
    f::Function
    properties::Dict
    add!::Function
    function Container(name::String, tag::String = "",
        components::Vector{Component} = []; properties::Dict = Dict())
        add!(c::Component)::Function = push!(components, c)
        f(c::Connection) = begin
            open_tag::String = "<$tag name = $name id = $name"
            write(http, open_tag)
            write(http, join([c.f(http) for c in components]))
            cs::String = join([c.f(http) for c in components])
            open_tag * ">$cs</$tag>"
        end
        new(name, tag, components, f, properties, add!)
    end
end

function Input(name::String, type::String = "text")
    Component(name, "input", Dict(:type => type))::Component
end

function TextArea(name::String; maxlength::Int64 = 25, rows::Int64 = 25,
                cols::Int64 = 50, text::String = "")
        Component(name, "textarea", Dict(:maxlength => maxlength, :rows => rows,
         :text => text, :cols => cols))::Component
end

function Button(name::String = "Button"; text::String = "", value::Integer = "",
                action::String = "/")
    Component(name, "button", Dict(:text => text, :value => 5))::Component
end

function P(name::String = ""; maxlength::Int64 = 25, text::String = "")
    Component(name, "p", Dict(:maxlength => maxlength, :text => text))::Component
end

FileInput(name::String) = Input(name, "file")::Component

function Option(name::String = ""; value::String = "", text::String = "")
    Component(name, "option", Dict())::Component
end

function RadioInput(name::String = "", selected::String = first(options).name,
        options::Vector{Component} = Vector{Component}(),
         multiple::Bool = false)
    Container(name, "select", options, properties = Dict())::Container
end

function SliderInput(name::String = ""; range::UnitRange = 0:100,
                    text::String = "")
    Input(name, "range")::Component
end

"""
"""
function Form(name::String = "",
    components::Vector{Component} = Vector{Component}(); post::String = "",
    get::String = "")
    method::String = ""
    action::String = ""
    if get != "" || post != ""
        if length(get) > length(post)
            method = "GET"
            action = get
        else
            method = "POST"
            action = post
        end
    end
    Container(name, "form", properties = Dict(:method => method,
    :action => action))::Container
end

function Link(name::String; rel::String = "stylesheet", href::String = "")
    Component(name, "link", Dict(:rel => string(rel), :href => href))::Component
end

function MetaData(name::String = "charset", content::String = "UTF-8" )
    Component(name, "meta", Dict(:content => string(content)))::Component
end

function Header(title::String = "Toolips App";
    icon::String = "", keywords::Array{String} = [], author::String = "",
    description::String = "", links::Vector{Component} = Vector{Component}())
    cs::Vector{Component} = Vector{Component}()
    push!(cs, MetaData())
    push!(cs, Link("icon", rel = "icon", href = icon))
    push!(cs, MetaData("keywords", join(keywords, ",")))
    push!(cs, MetaData("description", description))
    [push!(cs, link) for link in cs]
    Container(name, "head", cs)::Container
end

function Div(name::String,
    cs::Vector{Component} = []; properties::Dict = Dict())
    Container(name, "tag", cs)
end

function A(name::String; text::String = "")
    Component(name, link, Dict(:text => text))
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
            s * "}</style>"
        end
        keyframes::Dict = Dict()
        new(name, keyframes, f, delay, length)
    end
end
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
