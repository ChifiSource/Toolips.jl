mutable struct MobileConnection <: AbstractConnection
    stream::HTTP.Stream
    data::Dict{Symbol, Any}
    routes::Vector{AbstractRoute}
end

function convert(c::Connection, routes::Routes, into::Type{MobileConnection})
    get_client_system(c)[2]
end

function convert!(c::Connection, routes::Routes, into::Type{MobileConnection})
    MobileConnection(c.stream, c.data, routes)::MobileConnection
end

abstract type AbstractProcess end

mutable struct Process{T <: Any} <: AbstractProcess

end


mutable struct ProcessRoute{CT <: AbstractConnection, PT <: Process} <: AbstractRoute

end

thread(r::Pair{Number, AbstractRoute} ...) = begin
    
end


abstract type ArgRoute{T} end
# gets args, checks args 
route(f::Function, r::Route{<:AbstractConnection}, s::Symbol ...) = begin

end
#==

function multiroute!(c::AbstractConnection, vec::Routes, r::AbstractMultiRoute)
    met = findfirst(r -> convert(c, vec, typeof(r).parameters[1]), r.routes)
    if isnothing(met)
        default = findfirst(r -> typeof(r).parameters[1] == Connection, r.routes)
        if ~(isnothing(default))
            r.routes[default].page(c)
        else
            r.routes[1].page(c)
        end
    end
    c.routes[met].page(c)
end
==#
mutable struct ToolipsDocumenter <: AbstractExtension
    
end

toolips_app = Toolips.route("/toolips") do c::Toolips.Connection
    write!(c, "new toolips app incoming ...")
    write!(c, Toolips.get_args(c))
end

toolips_doc = Toolips.route("/toolips") do c::Toolips.Connection
    write!(c, "documentation here")
end

default_404 = Toolips.route("404") do c::Toolips.Connection
    write!(c, "404")
end

#==
"""
"""
struct Logger
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
==#

mutable struct Logger <: AbstractExtension
    function Logger()

    end
end


function on_start(ext::Logger, loaded::Vector{<:AbstractExtension}, 
    data::Dict{Symbol, Any}, routes::Vector{<:AbstractRoute})
end

function log!(c::AbstractConnection, message::String, at::Int64 = 1)

end

mutable struct AbstractFileRoute <: AbstractRoute end

mutable struct FileRoute{CT <: AbstractConnection, T <: Any} <: AbstractRoute
    path::String
    file::File{T}
end

mutable struct InterpolatedFileRoute{CT <: AbstractConnection, T <: Any} <: AbstractRoute
    path::String
    file::File{T}
    args::Any
    keyargs::Any
    function InterpolatedFileRoute()

    end
end

function show!(c::Connection, plot::Any, mime::MIME{<:Any} = MIME"text/html"())
    plot_div::Component{<:Any}
    data::String = String(io.data)
    data = replace(data,
     """<?xml version=\"1.0\" encoding=\"utf-8\"?>\n""" => "")
    plot_div[:text] = data
end

function route()

end

function route(path::Pair{String, String}; raw::Bool = true, connection::Type{<:AbstractConnection} = Connection)
    f::File{<:Any} = File(path[2])
    T::Type = typeof(f).parameters[1]
    FileRoute{Connection, T}(path[1], raw, f)
end

function route(paths::Pair{String, String} ...)
    directories = filter(p -> isdir(p), paths)

    [route(path)]
end

function route!(c::AbstractConnection, f::FileRoute{<:AbstractConnection, <:Any})
    if f.raw
        write!(c, f.file)
    else
        write!(c, )
    end
end

# interpolation
string(f::Components.File{:html}) = begin
    rawfile = read(path(f), String)    
end

string(f::Components.File{:md}) = begin
    rawfile = read(path(f), String)    
end

#==
"""
**Extensions**
### show_log(level::Int64, message::String, levels::Dict{Any, Crayon},
                prefix::String, time::Any)
------------------
Prints a log to the screen.
#### example
```
show_log(1, "hello!", levels, "toolips> ", now()

[2022:05:23:22:01] toolips> hello!
```
"""
function show_log(level::Int64, message::String, levels::Dict{Any, Crayon},
    prefix::String, time::Any)

end

"""
**Extensions**
### _log(http::HTTP.Stream, message::String) -> _
------------------
Binded call for the field log() inside of Logger(). This will log both to the
    JavaScript/HTML console.
------------------
### example (Closure from Logger)
```
log(http::HTTP.Stream, message::String) = _log(http, message)
```
"""
function _log(c::Connection, message::String)
    write!(c, "<script>console.log('" * message * "');</script>")
end


"""
**Extensions**
### route_from_dir(dir::String) -> ::Vector{String}
------------------
Recursively appends filenames for a directory AND all subsequent directories.
------------------
### example
```
x::Vector{String} = route_from_dir("mypath")
```
"""


"""

==#