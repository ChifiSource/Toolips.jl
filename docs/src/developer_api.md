# advanced usage
Welcome to the Toolips developer API. This section describes making
toolips extensions as well as
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
## creating connection extensions
```@docs
Toolips.AbstractConnection
```
Abstract Connections must have the extensions Dict, the routing Dict, and some
sort of writable stream called http. This needs to be binded to Base.write. A
good example of this is Toolips.SpoofStream and Toolips.SpoofConnection, which
can be used to write connection output to a string.
```julia
mutable struct SpoofStream
    text::String
    SpoofStream() = new("")
end
```
The http value can be anything, so in this case it will be a SpoofStream. The SpoofStream contains only a string, text. This is then binded to the write method:
```julia
write(s::SpoofStream, e::Any) = s.text = s.text * string(e)
write(c::SpoofStream, s::Servable) = s.f(c)
```
Finally, we make our connection, using SpoofStream as HTTP.
```
mutable struct SpoofConnection <: AbstractConnection
    routes::Dict
    http::SpoofStream
    extensions::Dict
    function SpoofConnection(r::Dict, http::SpoofStream, extensions::Dict)
        new(r, SpoofStream(), extensions)
    end
    SpoofConnection() = new(Dict(), SpoofStream(), Dict())
end
```
## creating server extensions
```@docs
Toolips.ServerExtension
```
Server extensions are a little bit more intense. There are three types of server extensions, **:func, :routing, and :connection.** The type field can be either a Vector{Symbol}, or a single symbol -- and a combination of each of these can be written. A :func extension is one that holds a function that is ran every time a Connection is routed. A :func extension requires that the function f(::AbstractConnection) or f(::Connection) exists inside of it. Here is an example:
```julia
import Toolips: ServerExtension

mutable struct MyExtension <: ServerExtension
    f::Function
    function MyExtension()
        f(c::Connection) = begin
            write!(c, "Hello!")
        end
    end
end
```
Each time the server is routed, there will now be "Hello!" written to the top of the page. A :routing extension is similar, but we will want to have the f function instead take two dictionaries. The dictionaries are specifically of type Dict{String, Function}, and Dict{Symbol, ServerExtension}. A great example of this is the Toolips.Files extension:
```julia
mutable struct Files <: ServerExtension
    type::Symbol
    directory::String
    f::Function
    function Files(directory::String = "public")
        f(r::Dict, e::Dict) = begin
            l = length(directory) + 1
            for path in route_from_dir(directory)
                push!(r, path[l:length(path)] => c::Connection -> write!(c, File(path)))
            end
        end
        new(:routing, directory, f)
    end
end
```
Finally, there is also a :connection extension. These are extensions that are to be pushed into the Connection's extensions field. Nothing extra needs to be done to these types of extensions. A great example of this is the Toolips.Logger:
```julia
mutable struct Logger <: ServerExtension
    type::Symbol
    out::String
    levels::Dict
    log::Function
    prefix::String
    timeformat::String
    writeat::Int64
    function Logger(levels::Dict{Any, Crayon} = Dict(
    1 => Crayon(foreground = :light_cyan),
    2 => Crayon(foreground = :light_yellow),
    3 => Crayon(foreground = :yellow, bold = true),
    4 => Crayon(foreground = :red, bold = true),
    :time_crayon => Crayon(foreground = :magenta, bold = true),
     :message_crayon => Crayon(foreground  = :light_blue, bold = true)
    );
    out::String = pwd() * "/logs/log.txt", prefix::String = "🌷 toolips> ",
                    timeformat::String = "YYYY:mm:dd:HH:MM", writeat::Int64 = 2)

        log(level::Int64, message::String) = _log(level, message, levels, out,
                                                prefix, timeformat, writeat)
        log(message::String) = _log(1, message, levels, out, prefix, timeformat,
        writeat)
        log(c::Connection, message::String) = _log(c, message)
        # These bindings are left open-ended for extending via
                                            # import Toolips._log
        log(level::Int64, message::Any) = _log(level, a, levels, out, prefix,
                                            timeformat)
        new(:connection, out::String, levels::Dict, log::Function,
                    prefix::String, timeformat::String, writeat::Int64)::Logger
    end
end
```
## toolips internals
If you're looking at the internals, you are probably good enough at reading documentation... Here are the doc-strings, my friend. **Thank you** for contributing.
```@docs
Toolips.write(::SpoofStream, ::Any)
Toolips.write(::SpoofStream, ::Servable)
Toolips.create_serverdeps
Toolips.serverfuncdefs
Toolips._start
Toolips.generate_router
Toolips._log
Toolips.string
Toolips.SpoofConnection
Toolips.SpoofStream
Toolips.route_from_dir
Toolips.show(::Base.TTY, ::Component)
Toolips.show(::Component)
Toolips.show_log
Toolips.@L_str
Toolips.has_extension(d::Dict, t::Type)
Toolips.argsplit
Toolips.string(::Vector{UInt8})
Toolips.showchildren
```
