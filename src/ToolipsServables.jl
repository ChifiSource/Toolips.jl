"""
#### toolips servables - composable and versatile parametric components
- 0.3 January
- Created in February, 2022 by [chifi](https://github.com/orgs/ChifiSource)
- This software is MIT-licensed.

`ToolipsServables` provides a composable parametric platform for templating 
    UIs.
```example

```
"""
module ToolipsServables
import Base: div, in, getindex, setindex!, delete!, push!, string, (:), show, display, *

"""
#### abstract type Servable
A `Servable` is a type intended to be written to IO that is served to a server. ToolipsServables 
comes with two `Servable` types,
- All servables have a `name`.
- All servables are dispatched to `string`.
###### Consistencies
- name**::String**
- `string(serv:**:Servable**)`
"""
abstract type Servable end

string(serv::Servable) = ""

function write!(io::IO, servables::Servable ...)
    write(io, join([string(serv) for serv in servables]))
end

function write!(io::String, servables::Servable ...)
    io = io * join([string(serv) for serv in servables])
end

function getindex(vs::Vector{<:Servable}, n::String)
    f = findfirst(c::Servable -> c.name == name, vs)
    if ~(isnothing(f))
        return(vec[f])::Servable
    end
    println("component $name not in $(join([comp.name for comp in vec], "| "))")
    throw(KeyError(name))
end
"""
```julia
File{T <: Any} <: Servable
```
- name**::String**
- path**::String**

The `File` `Servable` writes a file to a `Connection`. `T` will be the file extension 
of the file, meaning a `.html` file becomes a `File{:html}`. Getting index on a file, `File[]`, 
will yield the field path. Using `string` on a file will read the file as a `String`.
```julia
- File(`dir`**::String**)
```
"""
mutable struct File{T <: Any} <: Servable
    name::String
    path::String
    function File(dir::String)
        dir = replace(dir, "\\" => "/")
        ftsplit = split(dir, ".")
        fending = join(ftsplit[2:length(ftsplit)])
        nsplit = split(dir, "/")
        new{:}(join(nsplit[length(nsplit)], nsplit[1:length(nsplit) - 1], "/"))::File
    end
end

function getindex(f::File{<:Any}, args ...)
    f.path * "/" * f.name
end

string(f::File{<:Any}) = read(f[], String)

"""
### abstract type AbstractComponent <: Servable
Components are html elements.
### Consistencies
- properties**::Dict{Symbol, Any}**
##### <:Servable
- `name`**::String**
- string(**::AbstractComponent**)
```
"""
abstract type AbstractComponent <: Servable end

function in(name::String, v::Vector{<:AbstractComponent})
    pos = findfirst(c::AbstractComponent -> c.name == name, pos)
    ~(isnothing(pos))
end

function getindex(vec::Vector{<:AbstractComponent}, name::String)::AbstractComponent
    f = findfirst(c::AbstractComponent -> c.name == name, vec)
    if ~(isnothing(f))
        return(vec[f])::AbstractComponent
    end
    println("component $name not in $(join([comp.name for comp in vec], "| "))")
    throw(KeyError(name))
end

function delete!(name::String, v::Vector{<:AbstractComponent})::Nothing
    f = findfirst(c::AbstractComponent -> c.name == name, vec)
    if ~(isnothing(f))
        deleteat!(vec, f); nothing
    end
    println("component $name not in $(join([comp.name for comp in vec], "| "))")
    throw(KeyError(name))
end

"""

"""
mutable struct Component{T <: Any} <: AbstractComponent
    name::String
    properties::Dict{Symbol, Any}
    tag::String

    Component{T}(name::String, tag::String, properties::Dict{Symbol, Any}) where {T <: Any} = begin
        new{T}(name, properties, tag)
    end
    function Component{T}(name::String = "-", properties::Any ...; tag::String = string(T), args ...) where {T <: Any}
        children = Vector{AbstractComponent}()
        if length(properties) > 1
            children = Vector{AbstractComponent}(filter(prop -> typeof(prop) <: AbstractComponent, properties))
            properties = filter!(prop -> typeof(prop) <: AbstractComponent, properties)
        end
        properties = Dict{Symbol, Any}(vcat([Symbol(prop[1]) => string(prop[2]) for prop in properties],
        [Symbol(prop[1]) => string(prop[2]) for prop in args], :children => children, 
        :extras => Vector{AbstractComponent}()) ...)
        new{T}(name, properties, tag)::Component{T}
    end
    function Component(tag::String, name::String, props::Any ...; args ...)
        Component{Symbol(tag)}(name, props ...; args ...)
    end
end

getindex(s::AbstractComponent, symb::Symbol) = s.properties[symb]
getindex(s::AbstractComponent, symb::String) = s.properties[Symbol(symb)]

setindex!(s::AbstractComponent, a::Any, symb::Symbol) = s.properties[symb]::typeof(a) = a
setindex!(s::AbstractComponent, a::Any, symb::String) = s.properties[Symbol(symb)]::typeof(a) = a

function propstring(properties::Dict{Symbol, Any})::String
    notupe::Tuple{Symbol, Symbol} = (:text, :children, :extras)
   join(["$(prop[1])=\"$(prop[2])\"" for prop in filter(c -> c[1] in notupe, properties)], " ")
end

string(comp::Component{<:Any}) = begin
    text::String = comp.properties[:text]
    children = [string(child) for child in comp.properties[:children]]
    extras = [string(child) for child in comp.properties[:extras]]
    "$extras<$(comp.tag) id=\"$(comp.name)\" $(propstring(comp.properties))>$children$text</$(comp.tag)>"::String
end

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
function copy(c::Component{<:Any})
    comp = Component(name, tag, copy(c.properties))
    comp
end

"""

"""
abstract type StyleComponent <: AbstractComponent end


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
    properties::Dict{Any, Any}
    extras::Vector{Servable}
    function Style(name::String, properties::Dict{Any, Any}, extras::Vector{Servable})
        new(name, properties, extras)::Style
    end
    function Style(name::String, a::Pair ...; args ...)
        props::Vector{Pair{Any, Any}} = Base.vect(args ..., a ...)
        properties::Dict{Any, Any} = Dict{Any, Any}(props)
        extras::Vector{Servable} = Vector{Servable}()
        Style(name, properties, extras)::Style
    end
end

string(comp::Style) = begin
    properties = comp.properties
    name = comp.name
    extras = comp.extras
    css::String = "<style id=$name>$name { "
    [begin
        property::String = string(rule)
        value::String = string(properties[rule])
        css = css * "$property: $value; "
    end for rule in keys(properties)]
    css = css * "}</style>"
    write!(c, css)
    write!(c, extras)
end

abstract type AbstractAnimation <: StyleComponent end

"""

"""
mutable struct KeyFrameAnimation <: AbstractAnimation
    name::String
    properties::Dict{String, Vector{String}}
    delay::Float64
    length::Float64
    iterations::Float64
    function Animation(name::String = "animation"; delay::Float64 = 0.0,
        length::Float64 = 5.2, iterations::Integer = 1)
        properties::Dict{Symbol, AnimationFrame{<:Any}} = 
        Dict{Symbol, AnimationFrame{<:Any}}()
        new(name, properties, f, delay, length, iterations)::Animation
    end
end

const from = "from"
const to = "to"

function keyframes(name::String, pairs::Pair{String, Vector{String}} ...; delay::Number, length::Number, 
    iterations::Number)
    KeyFrameAnimation(name, Dict())
end

function string(anim::AbstractAnimation)
    """@keyframes $(anim.dame)"""
end


       #== f(c::AbstractConnection) = begin
@keyframes example {
  from {background-color: red;}
  to {background-color: yellow;}
}
        ==#

function show(io::Base.TTY, c::AbstractComponent)
    print("""$(c.name) ($(c.tag))\n
    $(join([string(prop[1]) * " = " * string(prop[2]) * "\n" for prop in c.properties]))
    $(showchildren(c))
    """)
end

function show(io::Base.TTY, c::StyleComponent)
    println("$(c.name) $(typeof(c))\n")
end

function show(io::IO, f::File)
    println("File: $(f.dir)")
end

display(io::IO, m::MIME"text/html", s::Servable) = show(io, m, s)

show(io::IO, m::MIME"text/html", s::Servable) = begin
    show(io, string(s))
end

show(io::IO, m::MIME"text/html", s::Vector{<:AbstractComponent}) = begin
    show(io, join([string(comp) for comp in s]))
end

include("templating.jl")
include("componentio.jl")


export px, pt, per, s, ms, deg, turn
export rgba, translate, matrix, skew, rotate, scale
export Servable, Component, AbstractComponent, File, write!
export animate!, style!
export templating, DOCTYPE, h, img, link, meta, input, a, p, h, ul, li
export br, i, title, span, iframe, svg, h1, h2, h3, h4, h5, h6
export element, label, script, nav, button, form, section, body, header, footer, b
export source, audio, video, table, tr, th, td
end # module ToolipsServables
