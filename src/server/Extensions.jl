using Dates

"""
### abstract type ServerExtension
Server extensions are loaded into the server on startup, and
can have a few different abilities according to their type
field's value. There are three types to be aware of.
-
##### Consistencies

"""
abstract type ServerExtension end

"""
### Logger
out::String
levels::Dict
log::Function
------------------
##### Field Info
- out::String
Rgw output file for the logger to write to.
- log::Function
A Logger logs information with different levels. Holds the function log(),
connected to the function _log(). Methods:
- log(::Int64, ::String)
- log(::String)
- log(::HTTP.Stream, ::String)
Writes to HTML console, and also logs at level 1 with logger.
- levels::Dict
------------------
##### Constructors
Logger(levels::Dict{level_count::Int64 => crayon::Crayons.Crayon};
                    out::String = pwd() * "logs/log.txt")
Logger(; out::String = pwd() * "/logs/log.txt")
"""
mutable struct Logger <: ServerExtension
    type::Symbol
    out::String
    levels::Dict
    log::Function
    function Logger(levels::Dict; out::String = pwd() * "logs/log.txt")
        log(level::Int64, message::String) = _log(level, message, levels, out)
        log(message::String) = _log(1, message, levels, out)
        log(c::Connection, message::String) = _log(c.http, message)
        new(:connection, out::String, levels::Dict, log::Function)
    end
    function Logger(; out = pwd() * "/logs/log.txt")
        if contains(out, "src")
            out = pwd() * "../logs/log.txt"
        end
        levels::Dict{Integer, Crayon} = Dict(
        1 => Crayon(foreground = :light_cyan),
        2 => Crayon(foreground = :light_yellow),
        3 => Crayon(foreground = :yellow, bold = true),
        4 => Crayon(foreground = :red, bold = true))
        Logger(levels; out = out)
    end
end
# print(, "In red. ", Crayon(bold = true), "Red and bold")
"""
### _log(level::Int64, message::String, levels::Dict, out::String) -> _
------------------
Binded call for the field log() inside of Logger(). See ?(Logger) for more
    details on the field log. All arguments are fields of that type. Return is a
    printout into the REPL as well as an append to the log file, provided by the
    out URI.
------------------
### example (Closure from Logger)
log(level::Int64, message::String) = _log(level, message, levels, out)
log(message::String) = _log(1, message, levels, out)
"""
function _log(level::Int64, message::String, levels::Dict, out::String)
    time = now()
    if level > 1
        open(out, "a") do o
            try
                write(o, "[" * string(time) * "]: $message\n")
            catch
                try
                    touch(out)
                    write(o, "[" * string(time) * "]: $message\n")
                catch
                    throw(ArgumentError("Cannot access logs."))
                end
            end
        end
    end
    println(Crayon(foreground = :light_gray, bold = true), "[", levels[level],
     string(time), Crayon(foreground = :light_gray, bold = true), "]: ",
     message)
end

"""
### _log(http::HTTP.Stream, message::String) -> _
------------------
Binded call for the field log() inside of Logger(). This will log both to the
    JavaScript/HTML console
------------------
### example (Closure from Logger)
log(http::HTTP.Stream, message::String) = _log(http, message)
"""
function _log(http::HTTP.Stream, message::String)
    write(http, "<script>console.log('" * message * "');</script>")
end


"""
### route_from_dir(dir::String) -> ::Vector{String}
------------------
Recursively appends filenames for a directory AND all subsequent directories.
------------------
### example
x::Vector{String} = route_from_dir("mypath")
"""
function route_from_dir(dir::String)
    dirs::Vector{String} = readdir(dir)
    routes::Vector{String} = []
    for directory in dirs
        if isfile("$dir/" * directory)
            push!(routes, "$dir/$directory")
        else
            if ~(directory in routes)
                newread::String = dir * "/$directory"
                newrs::Vector{String} = route_from_dir(newread)
                [push!(routes, r) for r in newrs]
            end
        end
    end
    routes::Vector{String}
end

"""
### File
dir::String
f::Function
------------------
- dir::String - The directory of a file to serve.
- f::Function - Function whose output to be written to http().
------------------
##### constructors
File(dir::String)
"""
mutable struct File
    dir::String
    f::Function
    function File(dir::String)
        f(c::Connection) = begin
            HTTP.setheader(c.http, "Content-Type" => "image/png")
            HTTP.Response(200, read(dir))
        end
        new(dir, f)
    end
end


"""
### Files
type::Symbol
directory::String
f::Function
------------------
- type::Symbol - The type of extension. There are three different selections
you can choose from. **:connection :routing :func**. A :connection extension
will be provided in Connection.extensions. A :routing function is passed a
Dict of routes as an argument. The last is a function argument, which is just a
specific function to run from the top-end to the server.
- directory::String - The directory to route the files from.
- f::Function - The function f() called with a Connection.
------------------
##### constructors
Files(dir::String)
"""
mutable struct Files <: ServerExtension
    type::Symbol
    directory::String
    f::Function
    function Files(directory::String = "public")
        f(r::Dict) = begin
            for path in route_from_dir(directory)
                push!(r, "/" * path => c::Connection -> write!(c, File(path)))
            end
        end
        new(:routing, directory, f)
    end
end
