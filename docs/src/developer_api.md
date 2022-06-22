# creating extensions
There are both Connection and Server extensions. Here is how to make them.
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
