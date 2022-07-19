abstract type AbstractComponent <: Servable end

"""
### abstract type StyleComponent <: Servable
No different from a normal Servable, simply an abstract type step for the
interface to separate working with Animations and Styles.
### Servable Consistencies
```
Servables can be written to a Connection via thier f() function and the
interface. They can also be indexed with strings or symbols to change properties
##### Consistencies
- f::Function - Function whose output to be written to http. Must take a single
positonal argument of type ::Connection or ::AbstractConnection
```
"""
abstract type StyleComponent <: Servable end

"""
### Component <: AbstractComponent <: Servable
- name::String
- f::Function
- tag::String
- properties::Dict
A component is a standard servable which is used to represent HTML tag
structures. Indexing a Component with a Symbol or a String will return or set
a Component's property to that index. The two special indexes are :children and
:text. :text will change the inner content of the Component and :children is
where components that will be written inside the Component go. You can add to
these with push!(c::Servable, c2::Servable)
#### example
```
using Toolips

image_style = Style("example")
image_anim = Animation("img_anim")
image_anim[:from] = "opacity" => "0%"
image_anim[:to] = "opacity" => "100%"
animate!(image_style)

r = route("/") do c::AbstractConnection
    newimage = img("newimage", src = "/logo.png")
    style!(newimage, image_style)
    write!(c, newimage)
end
```
------------------
#### field info
- name::String - The name field is the way that a component is denoted in code.
- f::Function - The function that gets called with the Connection as an
argument.
- properties::Dict - A dictionary of symbols and values.
------------------
##### constructors
- Component(name::String = "", tag::String = "", properties::Dict = Dict())
- Component(name::String, tag::String, props::Base.Pairs)
"""
mutable struct Component{tag} <: AbstractComponent
    name::String
    f::Function
    properties::Dict{Any, Any}
    extras::Vector{Servable}
    tag::String
    function Component(name::String = "", tag::String = "",
         properties::Dict = Dict{Any, Any}())
         push!(properties, :children => Vector{Servable}())
         extras = Vector{Servable}()
         f(c::AbstractConnection) = begin
             open_tag::String = "<$tag id = $name "
             text::String = ""
             write!(c, open_tag)
             for property in keys(properties)
                 special_keys = [:text, :children]
                 if ~(property in special_keys)
                     prop::String = string(properties[property])
                     propkey::String = string(property)
                     write!(c, " $propkey = $prop ")
                 else
                     if property == :text
                         text = properties[property]
                     end
                 end
             end
             write!(c, ">")
             if length(properties[:children]) > 0
                 write!(c, properties[:children])
            end
            write!(c, "$text</$tag>")
            write!(c, extras)
         end
         new{Symbol(tag)}(name, f, properties, extras, tag)::Component
    end

    function Component(name::String, tag::String, props::Pair ...)
        props = [prop for prop in props]
        Component(name, tag, Dict{Any, Any}(props))::Component
    end
end
#==
Base
    Components
==#
"""
### img(name::String; args ...) -> ::Component
------------------
Returns the img Component with the key-word arguments provided in args as
properties.
#### example
```
image = img("mylogo", src = "assets/logo.png")
write!(c, image)
```
"""
function img(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "img", args ..., keys ...)::Component{:img}
end

"""
### link(name::String; args ...) -> ::Component
------------------
Returns the link Component with the key-word arguments provided in args as
properties.
#### example
```
mylink = link("mylink", href = "http://toolips.app")
write!(c, mylink)
```
"""
function link(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "link", args ..., keys ...)::Component{:link}
end

"""
### meta(name::String; args ...) -> ::Component
------------------
Returns the meta Component with the key-word arguments provided in args as
properties.
#### example
```
metainfo = meta("metainfo", rel = "meta-description", text = "hello")
write!(c, metainfo)
```
"""
function meta(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "meta", args ..., keys ...)::Component{:meta}
end

"""
### input(name::String; args ...) -> ::Component
------------------
Returns the input Component with the key-word arguments provided in args as
properties.
#### example
```
element = input("mylogo")
write!(c, element)
```
"""
function input(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "input", args ..., keys ...)::Component{:input}
end

"""
### a(name::String; args ...) -> ::Component
------------------
Returns the a Component with the key-word arguments provided in args as
properties.
#### example
```
element = a("mylogo")
write!(c, element)
```
"""
function a(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "a", args ..., keys ...)::Component{:a}
end


"""
### p(name::String; args ...) -> ::Component
------------------
Returns the p Component with the key-word arguments provided in args as
properties.
#### example
```
p1 = input("mylogo")
write!(c, p)
```
"""
function p(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "p", args ..., keys ...)::Component{:p}
end

"""
### h(name::String; args ...) -> ::Component
------------------
Returns the h Component with the key-word arguments provided in args as
properties.
#### example
```
h1 = h("heading1", 1)
write!(c, h1)
```
"""
function h(name::String = "", level::Integer = 1,
    args::Pair{String, String} ...; keys ...)
    tg = Symbol("h$level")
    Component(name, "h$level", args ..., keys ...)::Component{tg}
end

"""
### h(name::String; args ...) -> ::Component
------------------
Returns the h Component with the key-word arguments provided in args as
properties.
#### example
```
h1 = h("heading1", 1)
write!(c, h1)
```
"""
function h1(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "h1", args ..., keys ...)::Component{:h1}
end


"""
### ul(name::String; args ...) -> ::Component
------------------
Returns the ul Component with the key-word arguments provided in args as
properties.
#### example
```
ul1 = ul("mylogo")
write!(c, ul)
```
"""
function ul(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "ul", args ..., keys ...)::Component{:ul}
end

"""
### li(name::String; args ...) -> ::Component
------------------
Returns the li Component with the key-word arguments provided in args as
properties.
#### example
```
li1 = li("mylogo")
write!(c, li)
```
"""
function li(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "li", args ..., keys ...)::Component{:li}
end

"""
### divider(name::String; args ...) -> ::Component
------------------
Returns the div Component with the key-word arguments provided in args as
properties.
#### example
```
divider1 = divider("mylogo")
write!(c, divider)
```
"""
function div(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "div", args ..., keys ...)::Component{:div}
end

"""
### divider(name::String; args ...) -> ::Component
------------------
Returns the div Component with the key-word arguments provided in args as
properties.
#### example
```
divider1 = divider("mylogo")
write!(c, divider)
```
"""
function divider(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "div", args ..., keys ...)::Component{:div}
end

"""
### br(name::String; args ...) -> ::Component
------------------
Returns the br Component with the key-word arguments provided in args as
properties.
#### example
```
comp = br("newcomp")
write!(c, comp)
```
"""
function br(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "br", args ..., keys ...)::Component{:br}
end

"""
### i(name::String; args ...) -> ::Component
------------------
Returns the i Component with the key-word arguments provided in args as
properties.
#### example
```
comp = i("newcomp")
write!(c, comp)
```
"""
function i(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "i", args ..., keys ...)::Component{:i}
end

"""
### title(name::String; args ...) -> ::Component
------------------
Returns the title Component with the key-word arguments provided in args as
properties.
#### example
```
comp = title("newcomp")
write!(c, comp)
```
"""
function title(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "title", args ..., keys ...)::Component{:title}
end

"""
### span(name::String; args ...) -> ::Component
------------------
Returns the span Component with the key-word arguments provided in args as
properties.
#### example
```
comp = span("newcomp")
write!(c, comp)
```
"""
function span(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "span", args ..., keys ...)::Component{:span}
end

"""
### iframe(name::String; args ...) -> ::Component
------------------
Returns the iframe Component with the key-word arguments provided in args as
properties.
#### example
```
comp = iframe("newcomp")
write!(c, comp)
```
"""
function iframe(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "iframe", args ..., keys ...)::Component{:iframe}
end

"""
### svg(name::String; args ...) -> ::Component
------------------
Returns the svg Component with the key-word arguments provided in args as
properties.
#### example
```
comp = svg("newcomp")
write!(c, comp)
```
"""
function svg(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "svg", args ..., keys ...)::Component{:svg}
end

"""
### element(name::String; args ...) -> ::Component
------------------
Returns the element Component with the key-word arguments provided in args as
properties.
#### example
```
comp = element("newcomp")
write!(c, comp)
```
"""
function element(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "element", args ..., keys ...)::Component{:element}
end

"""
### label(name::String; args ...) -> ::Component
------------------
Returns the label Component with the key-word arguments provided in args as
properties.
#### example
```
lbl = label("mylogo", src = "assets/logo.png")
write!(c, lbl)
```
"""
function label(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "label", args ..., keys ...)::Component{:label}
end

"""
### script(name::String; args ...) -> ::Component
------------------
Returns the script Component with the key-word arguments provided in args as
properties.
#### example
```
comp = script("newcomp")
write!(c, comp)
```
"""
function script(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "script", args ..., keys ...)::Component{:script}
end
"""
### nav(name::String; args ...) -> ::Component
------------------
Returns the nav Component with the key-word arguments provided in args as
properties.
#### example
```
comp = nav("newcomp")
write!(c, comp)
```
"""
function nav(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "nav", args ..., keys ...)::Component{:nav}
end

"""
### button(name::String; args ...) -> ::Component
------------------
Returns the button Component with the key-word arguments provided in args as
properties.
#### example
```
comp = button("newcomp")
write!(c, comp)
```
"""
function button(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "button", args ..., keys ...)::Component{:button}
end

"""
### form(name::String; args ...) -> ::Component
------------------
Returns the form Component with the key-word arguments provided in args as
properties.
#### example
```
comp = form("newcomp")
write!(c, comp)
```
"""
function form(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "form", args ..., keys ...)::Component{:form}
end

"""
### section(name::String; args ...) -> ::Component
------------------
Returns the form Component with the key-word arguments provided in args as
properties.
#### example
```
comp = section("newcomp")
write!(c, comp)
```
"""
function section(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "section", args ..., keys ...)::Component{:section}
end

"""
### body(name::String; args ...) -> ::Component
------------------
Returns the form Component with the key-word arguments provided in args as
properties.
#### example
```
comp = body("newcomp")
write!(c, comp)
```
"""
function body(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "body", args ..., keys ...)::Component{:body}
end

"""
### header(name::String; args ...) -> ::Component
------------------
Returns the form Component with the key-word arguments provided in args as
properties.
#### example
```
comp = header("newcomp")
write!(c, comp)
```
"""
function header(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "header", args ..., keys ...)::Component{:header}
end

"""
### footer(name::String; args ...) -> ::Component
------------------
Returns the form Component with the key-word arguments provided in args as
properties.
#### example
```
comp = footer("newcomp")
write!(c, comp)
```
"""
function footer(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "footer", args ..., keys ...)::Component{:footer}
end

function b(name::String = "", args::Pair{String, String} ...; keys ...)
    Component(name, "b", args ..., keys ...)::Component{:b}
end

DOCTYPE() = "<!DOCTYPE html>"
#==
Style
    Components
    ==#
"""
### Animation
- name::String
- properties::Dict
- f::Function
- delay::Float64
- length::Float64
- iterations::Integer
An animation can be used to animate Styles with the animate! method. Animating
is done by indexing by either percentage, or symbols, such as from and to.
##### example
```
anim = Animation("myanim")
anim[:from] = "opacity" => "0%"
anim[:to] = "opacity" => "100%"
style = Style("example")
animate!(style, anim)
```
------------------
##### field info
- name::String - The name of the animation.
- properties::Dict - The properties that have been pushed so far.
- f::Function - The function called when writing to a Connection.
- delay::Float64 - The delay before the animation begins.
- length::Float64 - The amount of time the animation should play.
- iterations::Integer - The number of times the animation should repeat. When
set to 0 the animation will loop indefinitely.
------------------
##### constructors
Animation(name::String = "animation", delay::Float64 = 0.0,
        length::Float64 = 5.2, iterations::Integer = 1)
    """
mutable struct Animation <: StyleComponent
    name::String
    properties::Dict
    f::Function
    delay::Float64
    length::Float64
    iterations::Integer
    function Animation(name::String = "animation"; delay::Float64 = 0.0,
        length::Float64 = 5.2, iterations::Integer = 1)
        f(c::AbstractConnection) = begin
            s::String = "<style> @keyframes $name {"
            for anim in keys(properties)
                vals = properties[anim]
                s = s * "$anim {" * vals * "}"
            end
            write!(c, string(s * "}</style>"))
        end
        f() = begin
            s::String = "<style> @keyframes $name {"
            for anim in keys(properties)
                vals = properties[anim]
                s = s * "$anim {" * vals * "}"
            end
            string(s * "}</style>")::String
        end
        properties::Dict = Dict()
        new(name, properties, f, delay, length, iterations)
    end
end

"""
### Style
- name::String
- f::Function
- properties::Dict{Any, Any}
- extras::Vector{Servable}
Creates a style from attributes, can style a Component using the style! method.
Names should be consistent with CSS names. For example, a default h1 style would
be named "h1". A heading style for a specific class should be "h1.myheading"
##### example
```
style = Style("p.mystyle", color = "blue")
style["opacity"] = "50%"
comp = Component()
style!(comp, style)
```
------------------
##### field info
- name::String - The name of the style. Should be consistent with CSS naming.
- f::Function - The function f, called by write! when writing to a Connection.
- properties::Dict{Any, Any} - A dict of style attributes.
- extras::String - Extra components to be written along with the style. Usually
this is an animation.
------------------
##### constructors
- Style(name::String; props ...)
"""
mutable struct Style <: StyleComponent
    name::String
    f::Function
    properties::Dict{Any, Any}
    extras::Vector{Servable}
    function Style(name::String; props ...)
        properties::Dict{Any, Any} = Dict{Any, Any}([prop for prop in props])
        extras::Vector{Servable} = Vector{Servable}()
        f(c::AbstractConnection) = begin
            css = "<style>$name { "
            for rule in keys(properties)
                property = string(rule)
                value = string(properties[rule])
                css = css * "$property: $value; "
            end
            css = css * "}</style>"
            write!(c, css)
            write!(c, extras)
        end
        new(name::String, f::Function, properties::Dict, extras)::Style
    end
    Style(name::String, props::Pair ...; args ...) = Style(props, args)::Style
end
