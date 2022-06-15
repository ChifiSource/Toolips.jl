"""
### Logger
out::String
levels::Dict
log::Function \
A Logger logs information with different levels. Holds the function log(),
connected to the function _log(). Methods:
- log(level::Int64, message::String)
- log(::String) - logs level 1
- log(::HTTP.Stream, ::String)
##### example
```
logger = Logger()
st = ServerTemplate(extensions = Dict(:logger => logger))
r = route("/") do c::Connection
    write!(c, "hello world!")
    c[:logger].log("Hello world delivered, mission accomplished.")
end
st.add(r)
st.start()
```
------------------
##### field info
- out::String - Logfile output directory.
- log::Function - Writes to HTML console, and also logs to out above level 1.
- levels::Dict
------------------
##### constructors
Logger(levels::Dict{level_count::Int64 => crayon::Crayons.Crayon};
                    out::String = pwd() * "logs/log.txt")
Logger(; out::String = pwd() * "/logs/log.txt")
"""
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
        log(c::Connection, message::String) = _log(c.http, message)
        # These bindings are left open-ended for extending via
                                            # import Toolips._log
        log(level::Int64, a::Any) = _log(level, a, levels, out, prefix,
                                            timeformat)
        log(level::Int64, a::Any, other::Any) = _log(level, a, other, levels,
                                        out, prefix, timeformat, writeat)
        new(:connection, out::String, levels::Dict, log::Function,
                    prefix::String, timeformat::String, writeat::Int64)::Logger
    end
end

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
function _log(level::Int64, message::String, levels::Dict, out::String, prefix::String,
    timeformat::String, writeat::Int64)
    time = Dates.format(now(), Dates.DateFormat("$timeformat"))
    if level > writeat
        if isfile(out)
            open(out, "a") do o
                write(o, "[" * string(time) * "]: $message\n")
                touch(out)
                write(o, "[" * string(time) * "]: $message\n")
            end
        else
            show_log(1, "$out not in current working directory.", levels,
            prefix, time)
        end
    end
    show_log(level, "$out not in current working directory.", levels,
    prefix, time)
end
function show_log(level::Int64, message::String, levels::Dict{Any, Crayon},
    prefix::String, time::Any)

    print(Crayon(foreground = :light_gray, bold = true), "[")
    print(levels[:time_crayon], string(time))
    print(Crayon(foreground = :light_gray, bold = true), "]: ")
    print(levels[:message_crayon], prefix)
    print(levels[level], message, "\n", Crayon(foreground = :blue))
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
### File <: Servable
dir::String
f::Function
------------------
##### field info
- dir::String - The directory of a file to serve.
- f::Function - Function whose output to be written to http().
------------------
##### constructors
File(dir::String)
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
write!(c::Connection, f::File) = f.f(c)

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
        f(r::Dict, e::Dict) = begin
            l = length(directory) + 1
            for path in route_from_dir(directory)
                push!(r, path[l:length(path)] => c::Connection -> write!(c, File(path)))
            end
        end
        new(:routing, directory, f)
    end
end
