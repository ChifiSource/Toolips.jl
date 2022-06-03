#==
Servables!
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
abstract type Servable end

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
- name::String - The name of the container. This is used in a lot of different
places, and can be referenced in HTML.
- tag::String - The HTML tag that this component ultimately will become.
- components::Vector{Component} - The components to contain in the container.
- f::Function - The servable f function. Writes the servable, with its
properties, then writes the Components contained in components into the
component.
- properties::Dict - A dictionary of property values to keys.
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
    function Container(name::String, tag::String = "",
        components::Vector{Component} = []; properties::Dict = Dict())
        f(c::Connection) = begin
            open_tag::String = "<$tag name = $name id = $name"
            write(http, open_tag)
            write(http, join([c.f(http) for c in components]))
            cs::String = join([c.f(http) for c in components])
            open_tag * ">$cs</$tag>"
        end
        new(name, tag, components, f, properties)
    end
end

"""
### input(name::String, type::String = "text") -> ::Component
Constructs an input component.
#### example

"""
function input(name::String, type::String = "text")
    Component(name, "input", Dict(:type => type))::Component
end

"""
### textarea(name::String ;
     maxlength::Int64 = 25, rows::Int64 = 25, cols::Int64 = 25,
     text::String = "") -> ::Component
Constructs a TextArea component.
#### example

"""
function textarea(name::String; maxlength::Int64 = 25, rows::Int64 = 25,
                cols::Int64 = 50, text::String = "")
        Component(name, "textarea", Dict(:maxlength => maxlength, :rows => rows,
         :text => text, :cols => cols))::Component
end

"""
### button(name::String ;
     text::String = "", value::Integer = "", action::String =) -> ::Component
Constructs a Button Component
#### example

"""
function button(name::String = "Button"; text::String = "", value::Integer = "")
    Component(name, "button", Dict(:text => text, :value => value))::Component
end

"""
p(name::String;
 maxlength::Int64 = 25, text::String = "") -> ::Component
 Constructs a "p" (paragraph) tag in HTML.
 #### example
"""
function p(name::String = ""; maxlength::Int64 = 25, text::String = "")
    Component(name, "p", Dict(:maxlength => maxlength, :text => text))::Component
end

"""
fileinput(name::String;
 maxlength::Int64 = 25, text::String = "") -> ::Component
Returns a file-input component.
 #### example
"""
fileinput(name::String) = Input(name, "file")::Component

"""
option(name::String;
 value::String = "", text::String = "") -> ::Component
Returns a option-input component. Preferable application belongs in a radioinput
form, for more info try ?(radioinput)
 #### example
"""
function option(name::String = ""; value::String = "", text::String = "")
    Component(name, "option", Dict())::Component
end

"""
radioinput(name::String;
 value::String = "", text::String = "") -> ::Container
Returns a option-input component. Preferable application belongs in a radioinput
form, for more info try ?(radioinput)
 #### example
"""
function radioinput(name::String = "", selected::String = first(options).name,
        options::Vector{Component} = Vector{Component}(),
         multiple::Bool = false)
    Container(name, "select", options, properties = Dict())::Container
end

"""
sliderinput(name::String;
 range::UnitRange = 0:100, text::String) -> ::Component
Returns a slider input with the range **range**.
 #### example
"""
function sliderinput(name::String = ""; range::UnitRange = 0:100,
                    text::String = "")
    input(name, "range")::Component
end

"""
form(name::String,
 components::Vector{Component}; post = "") -> ::Component
Returns a form which posts to **post** or navigates to **get**, depending on
which kwarg is used. **components** in this instance should be a vector of
input components.
 #### example
"""
function form(name::String = "",
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

function link(name::String; rel::String = "stylesheet", href::String = "")
    Component(name, "link", Dict(:rel => string(rel), :href => href))::Component
end

function metadata(name::String = "charset", content::String = "UTF-8" )
    Component(name, "meta", Dict(:content => string(content)))::Component
end

function header(title::String = "Toolips App";
    icon::String = "", keywords::Array{String} = [], author::String = "",
    description::String = "", links::Vector{Component} = Vector{Component}())
    cs::Vector{Component} = Vector{Component}()
    push!(cs, metadata())
    push!(cs, link("icon", rel = "icon", href = icon))
    push!(cs, metadata("keywords", join(keywords, ",")))
    push!(cs, metadata("description", description))
    [push!(cs, link) for link in cs]
    Container(name, "head", cs)::Container
end

function div(name::String,
    cs::Vector{Component} = Vector{Component}(); properties::Dict = Dict())
    Container(name, "div", cs, properties = properties)::Container
end

function body(name::String, cs::Vector{Component} = Vector{Component}();
    properties::Dict = Dict())
    Container(name, "body", cs, properties = properties)::Container
end

function a(name::String; text::String = "")
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
    properties::Dict
    function Style(name::String; animation::Animation = nothing)
        f(c::Connection) = begin
            css = "<style>$name { "
            if animation != nothing
                anim = animation.name
                css = css * "animation: $anim;"
            end
            for rule in keys(properties)
                property = string(rule)
                value = string(properties[rule])
                css = css * "$property: $value; "
            end
            css * "}</style>"
        end
        new(name::String, f::Function, properties::Dict)
    end
end
