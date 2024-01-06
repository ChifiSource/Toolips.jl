mutable struct ComponentTemplate{T <: Any}
    ComponentTemplate{T}() where {T <: Any} = new{T}()
    ComponentTemplate{T}(name::String,
    props::Any ...; args ...) where {T <: Any} = begin
        Component(ComponentTemplate{T}(), name, props::Any ...; args ...)
    end
end

Component(comp::ComponentTemplate{<:Any}, name::String, props ...; args ...) = begin
    T = typeof(comp).parameters[1]
    Component{T}(name, props ...; args ...)
end

"""
### DOCTYPE() -> ::String
------------------
DOCTYPE occassionally needs to be written to the top of files to make HTML render
properly.
#### example
```
write!(c, DOCTYPE())
```
"""
DOCTYPE() = "<!DOCTYPE html>"

const templating = ComponentTemplate{:info}

const style_properties = ComponentTemplate{:args}

const arguments = ComponentTemplate{:args}

div(name::String, args::Any ...; keyargs ...) = Component("div", name, args ...; keyargs)
h(name::String, level::Int64, args::Any ...; keyargs ...) = Component("h$level", name, args ...; keyargs)
h(level::Int64, name::String, args::Any ...; keyargs ...) = Component("h$level", name, args ...; keyargs)

const img = ComponentTemplate{:img}
const link = ComponentTemplate{:link}
const meta = ComponentTemplate{:meta}
const input = ComponentTemplate{:input}
const a = ComponentTemplate{:a}
const p = ComponentTemplate{:p}
const ul = ComponentTemplate{:ul}
const li = ComponentTemplate{:li}
const br = ComponentTemplate{:br}
const i = ComponentTemplate{:i}
const title = ComponentTemplate{:title}
const span = ComponentTemplate{:span}
const iframe = ComponentTemplate{:iframe}
const svg = ComponentTemplate{:svg}
const h1 = ComponentTemplate{:h1}
const h2 = ComponentTemplate{:h2}
const h3 = ComponentTemplate{:h3}
const h5 = ComponentTemplate{:h5}
const h4 = ComponentTemplate{:h4}
const h6 = ComponentTemplate{:h6}
const element = ComponentTemplate{:element}
const label = ComponentTemplate{:label}
const script = ComponentTemplate{:script}
const nav = ComponentTemplate{:nav}
const button = ComponentTemplate{:button}
const form = ComponentTemplate{:form}
const section = ComponentTemplate{:section}
const body = ComponentTemplate{:body}
const header = ComponentTemplate{:header}
const footer = ComponentTemplate{:footer}
const b = ComponentTemplate{:b}
const source = ComponentTemplate{:source}
const audio = ComponentTemplate{:audio}
const video = ComponentTemplate{:video}
const table = ComponentTemplate{:table}
const tr = ComponentTemplate{:tr}
const th = ComponentTemplate{:th}
const td = ComponentTemplate{:td}

push!(s::AbstractComponent, d::AbstractComponent ...) = [push!(s[:children], c) for c in d]

function style!(c::AbstractComponent, s::Pair{String, <:Any} ...)
    if "style" in keys(c.properties)
        c["style"] = c["style"][1:length(c["style"]) - 1]
    else
        c["style"] = "'"
    end
    for style in s
        k, v = style[1], style[2]
        c["style"] = c["style"] * "$k:$v;"
    end
    c["style"] = c["style"] * "'"
end

function style!(args::Any ...)
    styles = filter(v -> typeof(v) <: AbstractComponent, args)
    comps = filter(v -> ~(typeof(v) <: AbstractComponent), args)
    [style!(comp, styles ...) for comp in comps]
    nothing
end

function (:)(s::Style, name::String, ps::Vector{Pair{String, String}})
    newstyle = Style("$(s.name):$name")
    [push!(newstyle.properties, p) for p in ps]
    push!(s[:extras], newstyle)
end

(:)(s::Style, name::String) = s.extras[s.name * ":$name"]::AbstractComponent

(:)(s::AbstractComponent, name::String) = s.extras[name]::AbstractComponent

(:)(s::String, spairs::Vector{Pair{String, <:Any}} ...) = begin

end

(:)(s::Vector{String}, spairs::Vector{Pair{String, <:Any}} ...) = begin

end

(:)(s::StyleComponent ...) = begin

end

function (:)(sheet::Component{:sheet}, s::StyleComponent ...)

end

function (:)(sheet::Component{:sheet}, s::String, vec::Vector{Pair{String, String}})

end



mutable struct WebMeasure{format} end

*(i::Any, p::WebMeasure{<:Any}) = "$(i)$(typeof(p).parameters[1])"

"""
###### measures

"""
const measures = WebMeasure{:measure}()
# size
const px = WebMeasure{:px}()
const pt = WebMeasure{:pt}()
const inch = WebMeasure{:in}()
const pc = WebMeasure{:pc}()
const mm = WebMeasure{:mm}()
const cm = WebMeasure{:cm}()
# relative size
const percent = WebMeasure{:%}()
const per = WebMeasure{:%}()
const em = WebMeasure{:em}()
# time
const seconds = WebMeasure{:s}()
const s = WebMeasure{:s}()
const ms = WebMeasure{:ms}()
# angles
const deg = WebMeasure{:deg}()
const turn = WebMeasure{:turn}()
# colors and transforms
function rgba(r::Number, g::Number, b::Number, a::Float64)
    "rgb($r $g $b $a / a)"
end

translateX(s::String) = "translateX($s)"
translateY(s::String) = "translateX($s)"
rotate(s::String) = "rotate($s)"
matrix(n::Int64 ...) = "matrix(" * join([string(i) for i in n], ", ") * ")"
translate(x::String, y::String) = "translate()"
skew(one::String, two::String) = "skew($one, $two)"
scale(n::Any, n2::Any) = "scale($one, $two)"
