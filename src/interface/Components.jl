"""
### File <: Servable
dir::String
f::Function
Serves a file into a Connection.
##### example
```
f = File("hello.txt")
r = route("/") do c
    write!(c, f)
end
```
------------------
##### field info
- dir::String - The directory of a file to serve.
- f::Function - Function whose output to be written to http().
------------------
##### constructors
- File(dir::String)
"""
mutable struct File <: Servable
    dir::String
    f::Function
    function File(dir::String)
        f(c::Connection) = begin
            open(dir) do f
                write(c.http, f)
            end
        end
        new(dir, f)
    end
end

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
        props::Vector{Pair{Any, Any}} = [prop for prop in props]
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
    extras::Vector{Servable}
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
        new(name, properties, Vector{Servable}(), f, delay, length, iterations)::Animation
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
    function Style(name::String, prop; props ...)
        properties::Dict{Any, Any} = Dict{Any, Any}([prop for prop in vcat(prop, props)])
        extras::Vector{Servable} = Vector{Servable}()
        f(c::AbstractConnection) = begin
            css = "<style id=$name>$name { "
            [begin
                property::String = string(rule)
                value::String = string(properties[rule])
                css = css * "$property: $value; "
            end for rule in keys(properties)]
            end
            css = css * "}</style>"
            write!(c, css)
            write!(c, extras)
        end
        new(name::String, f::Function, properties::Dict, extras)::Style
    end
    Style(name::String, props::Pair ...; args ...) = Style(props, args)::Style
end

"""
**Interface**
### properties!(c::Servable, s::Servable) -> _
------------------
Copies properties from s,properties into c.properties.
#### example
```
comp = AbstractComponent()
othercomp = AbstractComponent()
othercomp["opacity"] = "100%"
properties!(comp, othercomp)

comp["opacity"]
        100%
```
"""
properties!(c::AbstractComponent, s::AbstractComponent) = merge!(c.properties, s.properties)

"""
**Interface**
### getproperties(c::AbstractComponent) -> ::Dict
------------------
Returns a Dict of properties inside of c.
#### example
```
props = properties(c)
```
"""
getproperties(c::AbstractComponent) = c.properties

"""
**Interface**
### children(c::AbstractComponent) -> ::Vector{Servable}
------------------
Returns Vector{Servable} of children inside of c.
#### example
```
children(c)
```
"""
children(c::AbstractComponent) = c.properties[:children]

"""
**Interface**
### copy(c::AbstractComponent) -> ::AbstractComponent
------------------
copies c.
#### example
```
c = p("myp")
t = copy!(c)
```
"""
function copy(c::AbstractComponent)
    props = copy(c.properties)
    extras = copy(c.extras)
    tag = copy(c.tag)
    name = copy(c.name)
    comp = AbstractComponent(name, tag, props)
    comp.extras = extras
    comp
end

"""
**Interface**
### has_children(c::AbstractComponent) -> ::Bool
------------------
Returns true if the given component has children.
#### example
```
c = AbstractComponent()
otherc = AbstractComponent()
push!(c, otherc)

has_children(c)
    true
has_children(otherc)
    false
```
"""
function has_children(c::AbstractComponent)
    if length(c[:children]) != 0
        return true
    else
        return false
    end
end

"""
**Interface**
### push!(s::AbstractComponent, d::AbstractComponent ...) -> ::AbstractComponent
------------------
Adds the child or children d to s.properties[:children]
#### example
```
c = AbstractComponent()
otherc = AbstractComponent()
push!(c, otherc)
```
"""
push!(s::AbstractComponent, d::AbstractComponent ...) = [push!(s[:children], c) for c in d]

"""
**Interface**
### getindex(s::AbstractComponent, symb::Symbol) -> ::Any
------------------
Returns a property value by symbol or name.
#### example
```
c = p("hello", text = "Hello world")
c[:text]
    "Hello world!"

c["opacity"] = "50%"
c["opacity"]
    "50%"
```
"""
getindex(s::AbstractComponent, symb::Symbol) = s.properties[symb]

"""
**Interface**
### getindex(::Servable, ::String) -> ::Any
------------------
Returns a property value by string or name.
#### example
```
c = p("hello", text = "Hello world")
c[:text]
    "Hello world!"

c["opacity"] = "50%"
c["opacity"]
    "50%"
```
"""
getindex(s::AbstractComponent, symb::String) = s.properties[symb]

"""
**Interface**
### setindex!(s::Servable, a::Any, symb::Symbol) -> _
------------------
Sets the property represented by the symbol to the provided value.
#### example
```
c = p("world")
c[:text] = "hello world!"
```
"""
setindex!(s::AbstractComponent, a::Any, symb::Symbol) = s.properties[symb] = a

"""
**Interface**
### setindex!(s::Servable, a::Any, symb::String) -> _
------------------
Sets the property represented by the string to the provided value. Use the
appropriate web-format, such as "50%" or "50px".
#### example
```
c = p("world")
c["align"] = "center"
```
"""
setindex!(s::AbstractComponent, a::Any, symb::String) = s.properties[symb] = a
#==
Styles
==#
"""
**Interface**
### style!(c::Servable, s::Style) -> _
------------------
Applies the style to a servable.
#### example
```
serv = p("wow")
mystyle = Style("mystyle", color = "lightblue")
style!(serv, mystyle)
```
"""
function style!(c::Component{Any}, s::Style)
        if :class in keys(c.properties)
            if contains(s.name, ".")
                c.properties[:class] = "$(c.properties[:class]) " * split(s.name, ".")[end]
            else
                c.properties[:class] = s.name
            end
        else
            if contains(s.name, ".")
                c.properties[:class] = split(s.name, ".")[end]
            else
                c.properties[:class] = s.name
            end
        end

        push!(c.extras, s)
end

"""
**Interface**
### :(s::Style, name::String, ps::Vector{Pair{String, String}})
------------------
Creates a sub-style of a given style with the pairs provided in ps.
#### example
```
s = Style("buttonstyle", color = "white")
s["background-color"] = "blue"
s:"hover":["background-color" => "blue"]
```
"""
function (:)(s::Style, name::String, ps::Vector{Pair{String, String}})
    newstyle = Style("$(s.name):$name")
    [push!(newstyle.properties, p) for p in ps]
    push!(s.extras, newstyle)
end

(:)(s::Style, name::String) = s.extras[string(split(name, ":")[2])]::AbstractComponent
"""
**Interface**
### style!(c::Servable, s::Pair ...) -> _
------------------
Applies the style pairs to the servable's "style" property.
#### example
```
mycomp = p("mycomp")
style!(mycomp, "background-color" => "lightblue", "color" => "white")
```
"""
function style!(c::Component{Any}, s::Pair ...)
    style!(c, [p for p in s])
end

"""
**Interface**
### style!(c::Servable, s::Vector{Pair}) -> _
------------------
Applies the style pairs to the servable's "style" property.
#### example
```
mycomp = p("mycomp")
style!(mycomp, ["background-color" => "lightblue", "color" => "white"])
```
"""
function style!(c::Component{Any}, s::Vector{Pair{String, String}})
    if "style" in keys(c.properties)
        c["style"][length(c["style"])] = ""
    else
        c["style"] = "'"
    end
    for style in s
        k, v = style[1], style[2]
        c["style"] = c["style"] * "$k: $v;"
    end
    c["style"] = c["style"] * "'"
end

"""
**Interface**
### style!(::Style, ::Style) -> _
------------------
Copies the properties from the second style into the first style.
#### example
```
style1 = Style("firsts")
style2 = Style("seconds")
style1["color"] = "orange"
style!(style2, style1)

style2["color"]
    "orange"
```
"""
style!(s::Style, s2::Style) = merge!(s.properties, s2.properties)

function style!(s::Style, p::Pair ...)
    [push!(s.properties, pa) for pa in p]
end
"""
**Interface**
### animate!(s::Style, a::Animation) -> _
------------------
Sets the Animation as a property of the style.
#### example
```
anim = Animation("fade_in")
anim[:from] = "opacity" => "0%"
anim[:to] = "opacity" => "100%"

animated_style = Style("example")
animate!(animated_style, anim)
```
"""
function animate!(s::Style, a::Animation)
    s["animation-name"] = string(a.name)
    s["animation-duration"] = string(a.length) * "s"
    if a.iterations == 0
        s["animation-iteration-count"] = "infinite"
    else
        s["animation-iteration-count"] = string(a.iterations)
    end
    push!(s.extras, a)
end

"""
**Interface**
### animate!(s::AbstractComponent, a::Animation) -> _
------------------
Sets the animation of a AbstractComponent directly
#### example
```
anim = Animation("fade_in")
anim[:from] = "opacity" => "0%"
anim[:to] = "opacity" => "100%"

myp = p("myp", text = "I fade in!")
animate!(myp, anim)
```
"""
function animate!(s::AbstractComponent, a::Animation)
    push!(s.extras, a)
    if a.iterations == 0
        iters = "infinite"
    else
        iters = string(a.iterations)
    end
    if "style" in keys(s.properties)
        sty = c["style"]
        sty[length(sty)] = " "
        sty = sty * "'animation-name: $(a.name); animation-duration: $(a.length)"
        sty = sty * "animation-iteration-count: $iters;'"
        c["style"] = sty
    else
        str = "'animation-name: $(a.name); animation-duration: $(a.length);"
        str = str * "animation-iteration-count: $iters;'"
        c["style"] = str
    end
end

"""
**Interface**
### delete_keyframe!(a::Animation, key::Int64) -> _
------------------
Deletes a given keyframe from an animation by keyframe percentage.
#### example
```
anim = Animation("")
anim[0] = "opacity" => "0%"
delete_keyframe!(anim, 0)
```
"""
function delete_keyframe!(a::Animation, key::Int64)
    delete!(a.properties, "$key%")
end

"""
**Interface**
### delete_keyframe!(a::Animation, key::Symbol) -> _
------------------
Deletes a given keyframe from an animation by keyframe name.
#### example
```
anim = Animation("")
anim[:to] = "opacity" => "0%"
delete_keyframe!(anim, :to)
```
"""
function delete_keyframe!(a::Animation, key::Symbol)
    delete!(a.properties, string(key))
end

"""
**Interface**
### setindex!(anim::Animation, set::Pair, n::Int64) -> _
------------------
Sets the animation at the percentage of the Int64 to modify the properties of
pair.
#### example
```
a = Animation("world")
a[0] = "opacity" => "0%"
```
"""
function setindex!(anim::Animation, set::Pair, n::Int64)
    prop = string(set[1])
    value = string(set[2])
    n = string(n)
    if n in keys(anim.properties)
        anim.properties[n] = anim.properties[n] * "$prop: $value;"
    else
        push!(anim.properties, "$n%" => "$prop: $value; ")
    end
end

"""
**Interface**
### setindex!(anim::Animation, set::Pair, n::Symbol) -> _
------------------
Sets the animation at the corresponding key-word's position. Usually these are
:to and :from.
#### example
```
a = Animation("world")
a[:to] = "opacity" => "0%"
```
"""
function setindex!(anim::Animation, set::Pair, n::Symbol)
    prop = string(set[1])
    value = string(set[2])
    n = string(n)
    if n in keys(anim.properties)
        anim.properties[n] = anim.properties[n] * "$prop: $value; "
    else
        push!(anim.properties, "$n" => "$prop: $value; ")
    end
end

#==
Vectorization
==#
"""
**Interface**
### components(cs::Servable ...) -> ::Vector{Servable}
------------------
Creates a Vector{Servable} from multiple servables. This is useful because
a vector of components could potentially become a Vector{AbstractComponent}, for example
and this is not the dispatch that is used universally across the package.
#### example
```
c = AbstractComponent()
c2 = AbstractComponent()
components(c, c2)
    Vector{Servable}(AbstractComponent(), AbstractComponent())
```
"""
components(cs::Servable ...) = Vector{Servable}([s for s in cs])

vect(cs::Servable ...) = Vector{Servable}([s for s in cs])
vect(cs::AbstractComponent ...) = Vector{Servable}([s for s in cs])

#==
Show
==#
"""
**Interface**
### string(c::AbstractComponent) -> ::String
------------------
Shows c as a string representation of itself.
#### example
```
c = divider("example", align = "center")
string(c)
    "divider: align = center"
```
"""
function string(c::AbstractComponent)
    base = c.name
    properties = ": "
    for pair in c.properties
        key, val = pair[1], pair[2]
        if ~(key == :children)
            properties = properties * "  $key = $val  "
        end
    end
    base * properties
end

function show(io::Base.TTY, c::AbstractComponent)
    children = showchildren(c)
    display("text/markdown", """##### $(c.tag)
        $(string(c))
        $children
        """)
end

function show(IO::IO, c::AbstractComponent)
    myc = SpoofConnection()
    write!(myc, c)
    display("text/html", myc.http.text)
end

function display(m::MIME{Symbol("text/html")}, c::AbstractComponent)
    myc = SpoofConnection()
    write!(myc, c)
    display("text/html", myc.http.text)
end

"""
**Internals**
### showchildren(x::AbstractComponent) -> ::String
------------------
Get the children of x as a markdown string.
#### example
```
c = divider("example")
child = p("mychild")
push!(c, child)
s = showchildren(c)
println(s)
"##### children
|-- mychild
```
"""
function showchildren(x::AbstractComponent)
    prnt = "##### children \n"
    for c in x[:children]
        prnt = prnt * "|-- " * string(c) * " \n "
        for subc in c[:children]
            prnt = prnt * "   |---- " * string(subc) * " \n "
        end
    end
    prnt
end

function display(m::MIME{Symbol("text/html")}, c::Style)
    myc = SpoofConnection()
    write!(myc, c)
    displayer = h1("displayh", text = "style")
    style!(displayer, c)
    write!(myc, displayer)
    display("text/html", myc.http.text)
end

function display(m::MIME{Symbol("text/html")}, c::Animation)
    myc = SpoofConnection()
    write!(myc, c)
    displayer = h1("displayh", text = "style")
    animate!(displayer, c)
    write!(myc, displayer)
    display("text/html", myc.http.text)
end
