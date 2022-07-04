## creating servables
Servables are probably the most approachable type to make for
your first extension. Servable extensions work by simply making
a sub-type of Servable. For example, the Component's source code:
```julia
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
     new(name, f, properties, extras, tag)::Component
end
```
The Interface portion of this module is actually built as a Toolips extension
itself. Anyway, as you can see, the function f is provided. This is the one
consistent field every servable must have. In that field you are able to write
to the document with text how you normally would. That being said, Servable
extensions can be used simply to generate one portion of your website while
holding some information in a constructor. As soon as it is created, it is
immediately dispatched to methods like write!, etc. Here is another, more simple
example where we write a header.
```@docs
Toolips.Servable
```
```julia
import Toolips: Servable
mutable struct MyHeader <: Servable
    f::Function
    cs::Vector{Servable}
    function MyHeader(name = "Hello World")
        anim = Animation("fade_in")
        div_s = Style("div.myheaderstyle", color = "lightblue")
        header_div = divider("header_div", align = "center")
        heading = h(1, "Hello, welcome!", align = "center")
        style!(heading, "color" => "white")
        push!(header_div, heading)
        animate!(div_s, anim)
        cs = components(div_s, header_div)
        f(c::Connection) = write!(c, cs)
        new(f, cs)
    end
end
```
Is this the best way to serve your websites? It could be depending on your
application!
