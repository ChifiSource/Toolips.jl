#==
Servables!
==#
abstract type Servable end
mutable struct File <: Servable
    dir::String
    f::Function
    function File(dir::String)
        f(c::Connection) = HTTP.Response(200, read(dir))
        new(dir, f)
    end
end

"""
### Component
name::String
f::Function
properties::Dict
------------------

------------------

"""
mutable struct Component <: Servable
    name::String
    f::Function
    properties::Dict
    function Component(name::String = "", tag::String = "",
         properties::Dict = Dict())
         f(c::Connection) = begin
             open_tag::String = "<$tag id = $name "
             for property in keys(properties)
                 if ~(property == :text)
                     prop::String = string(properties[property])
                     propkey::String = string(property)
                     open_tag = open_tag * " $propkey = $prop"
                 end
             end
             open_tag * ">$text</$tag>"
         end
         new(name, f, properties)::Component
    end
end

"""
### Container
name::String
f::Function
properties::Dict
------------------

------------------

"""
mutable struct Container <: Servable
    name::String
    tag::String
    ID::Integer
    components::Vector{Component}
    f::Function
    properties::Dict
    add!::Function
    function Container(name::String, tag::String = "", ID::Integer = 1,
        components::Vector{Component} = []; properties::Dict = Dict())
        add!(c::Component)::Function = push!(components, c)
        f(c::Connection) = begin
            open_tag::String = "<$tag name = $name id = $name"
            write(http, open_tag)
            write(http, join([c.f(http) for c in components]))
            cs::String = join([c.f(http) for c in components])
            open_tag * ">$cs</$tag>"
        end
        new(name, tag, ID, components, f, properties, add!)
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

function RadioInput(name::String = "", ID::Int64, select::Component,
        options::Vector{Component} = Vector{Component}();
         multiple::Bool = false)
    Container(name, "select", ID, options, properties = Dict())::Container
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
    Container(name, "form", 5, properties = Dict(:method => method,
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
    Container(name, "head", 1, cs)::Container
end

function Div(name::String, properties::Dict = Dict(),
    cs::Vector{Component} = [])
    Container(name, "tag", 1, cs)
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
    function Animation(name::String = "animation"; delay::Float64 = 0,
        length::Float64 = 0)
        f(http) = begin

        end
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


include("../server/Extensions.jl")
include("../server/Core.jl")
include("interface.jl")
