"""
### Component <: Servable
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
mutable struct Component{tag} <: Servable
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
         new{tag}(name, f, properties, extras, tag)::Component
    end

    Component(name::String, tag::String, props::Base.Pairs,
    keys::Vector{Pair{Any, Any}}) = begin
        props = Vector{Pair{Any, Any}}
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
img(name::String = "", keys::Pair{Any, Any} ...; args ...) = Component(name,
"img", args, keys)::Component

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
link(name::String = "", keys::Pair{Any, Any} ...; args ...) = Component(name,
 "link", args, keys)::Component

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
meta(name::String = "", keys::Pair{Any, Any} ...; args ...) = Component(name, "meta", args)::Component

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
input(name::String = "", keys::Pair{Any, Any} ...; args ...) = Component(name, "input", args)::Component

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
a(name::String = "", keys::Pair{Any, Any} ...; args ...) = Component(name, "a", args)::Component

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
p(name::String = "", keys::Pair{Any, Any} ...; args ...) = Component(name, "p", args)::Component

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
h(name::String = "", n::Int64 = 1, keys::Pair{Any, Any} ...; args ...) = Component(name, "h$n",
                                                                args)::Component


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
ul(name::String = "", keys::Pair{Any, Any} ...; args ...) = Component(name, "ul", args)::Component

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
li(name::String = "", keys::Pair{Any, Any} ...; args ...) = Component(name, "li", args)::Component

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
divider(name::String = "", keys::Pair{Any, Any} ...; args ...) = Component(name, "div", args)::Component

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
br(name::String = "", keys::Pair{Any, Any} ...; args ...) = Component(name, "/br", args)::Component

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
i(name::String = "", keys::Pair{Any, Any} ...; args ...) = Component(name, "i", args)::Component

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
title(name::String = "", keys::Pair{Any, Any} ...; args ...) = Component(name, "title", args)::Component

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
span(name::String = "", keys::Pair{Any, Any} ...; args ...) = Component(name, "span", args)::Component

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
iframe(name::String = ""; args ...) = Component(name, "iframe", args)::Component

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
svg(name::String = ""; args ...) = Component(name, "svg", args)::Component

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
element(name::String = ""; args ...) = Component(name, "element",
                                                                args)::Component

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
label(name::String = ""; args ...) = Component(name, "label", args)::Component

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
script(name::String = ""; args ...) = Component(name, "script", args)::Component

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
nav(name::String = ""; args ...) = Component(name, "nav", args)::Component

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
button(name::String = ""; args ...) = Component(name, "button", args)::Component

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
form(name::String = ""; args ...) = Component(name, "form", args)::Component

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
section(name::String = ""; args ...) = Component(name, "section",
                                                                args)::Component

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
body(name::String = ""; args ...) = Component(name, "body", args)::Component

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
header(name::String = ""; args ...) = Component(name, "header", args)::Component

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
footer(name::String = ""; args ...) = Component(name, "footer", args)::Component

DOCTYPE() = "<!DOCTYPE html>"
#==
Style
    Components
    ==#
"""
### Animation
- name::String
- keyframes::Dict
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
- keyframes::Dict - The keyframes that have been pushed so far.
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
    keyframes::Dict
    f::Function
    delay::Float64
    length::Float64
    iterations::Integer
    function Animation(name::String = "animation"; delay::Float64 = 0.0,
        length::Float64 = 5.2, iterations::Integer = 1)
        f(c::AbstractConnection) = begin
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
        properties::Dict = Dict{Any, Any}(props)
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
end
