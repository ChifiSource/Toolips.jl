

abstract type AbstractMultiRoute  <: AbstractRoute end

mutable struct MultiRoute <: AbstractMultiRoute
    path::String
    routes::Vector{Route}
end

mutable struct MobileConnection <: AbstractConnection

end

function convert(c::Connection, into::Type{MobileConnection})

end

function convert(c::Type{<:AbstractConnection}, c2::{<:AbstractConnection})
    false
end

"""
"""
route!(c::AbstractConnection, r::AbstractMultiRoute) = begin
    mainroute = nothing
    ts = [begin 
        if typeof(rout) != Route{Connection} && typeof(rout) != Route 
            typeof(rout).parameters[1]
            if typeof(convert) <: AbstractConnection
                findfirst(s -> )
                return(r.routes)
            end
        else
            mainroute = rout
        end
    for rout in r]
end



function html_properties(s::AbstractString)
    propvec::Vector{SubString} = split(s, " ")
    properties::Dict{Any, Any} = Dict{Any, Any}(begin
        ppair::Vector{SubString} = split(segment, "=")
        if length(ppair) < 2
            string(ppair[1]) => string(ppair[1])
        else
            string(ppair[1]) => replace(string(ppair[2]), "\"" => "")
        end
    end for segment in propvec)
    properties::Dict{Any, Any}
end

function htmlcomponent(s::String)
    i::Int64 = 1
    while parsing
        if i == 1

        end

    end
end

function htmlcomponent(s::String, readonly::Vector{String})
    if readonly[1] == "none"
        return Vector{Servable}()
    end
    Vector{Servable}(filter!(x -> ~(isnothing(x)), [begin
        element_sect = findfirst(" id=\"$compname\"", s)
        if ~(isnothing(element_sect))
            starttag = findprev("<", s, element_sect[1])[1]
            ndtag = findnext(" ", s, element_sect[1])[1]
            argfinish = findnext(">", s, ndtag)[1] + 1
            tg = s[starttag + 1:ndtag - 1]
            finisher = findnext("</$tg", s, argfinish)
            fulltxt = s[argfinish:finisher[1] - 1]
            properties = html_properties(s[ndtag:argfinish - 2])
            name::String = ""
            if "id" in keys(properties)
                name = properties["id"]
                delete!(properties, "id")
            end
            push!(properties, "text" => replace(fulltxt, "<br>" => "\n", "<div>" => "", 
            "&#36;" => "\$", "&#37;" => "%", "&#38;" => "&", "&nbsp;" => " ", "&#60;" => "<", "	&lt;" => "<", 
            "&#62;" => ">", "&gt;" => ">", "<br" => "\n", "&bsol;" => "\\", "&#63;" => "?"))
            Component(compname, string(tg), properties)
        else
        end
    end for compname in readonly]))::Vector{Servable}
end


toolips_app = route("/") do c::Connection
    write!(c, "new toolips app incoming ...")
end

default_404 = route("404") do c::Connection
    write!(c, "404")
end
#==
"""
##### field info
- type::Symbol - The type of server extension -- in this case, Connection.
- out::String - Logfile output directory.
- log(level::Int64, message::String) - Logs the message at the provided level.
- log(message::String) - Logs the message at level 1.
- log(c::Connection, message::String) - Logs to level one and to JavaScript
console.
- levels::Dict - A {Any, Crayon} dict that contains all of the crayons for the
logger. Also contains two special crayons under the keys :time_crayon and
:message_crayon
- prefix::String - The prefix to write before the message.
- timeformat::String - A string representing DT format, must be able to be
passed through the datetime_str macro from Dates.
- writeat::Int64 - The log level to write to out at.
------------------
##### constructors
Logger(levels::Dict{level_count::Int64 => crayon::Crayons.Crayon};
                    out::String = pwd() * "logs/log.txt")
Logger(; out::String = pwd() * "/logs/log.txt")
"""
mutable struct Logger
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

"""
**Extensions**
### _log(level::Int64, message::String, levels::Dict, out::String) -> _
------------------
Binded call for the field log() inside of Logger(). See ?(Logger) for more
    details on the field log. All arguments are fields of that type. Return is a
    printout into the REPL as well as an append to the log file, provided by the
    out URI.
------------------
### example (Closure from Logger)
```
log(level::Int64, message::String) = _log(level, message, levels, out)
log(message::String) = _log(1, message, levels, out)
```
"""
function _log(level::Int64, message::String, levels::Dict, out::String,
    prefix::String, timeformat::String, writeat::Int64)
    time = Dates.format(now(), Dates.DateFormat("$timeformat"))
    if writeat > 0 && level >= writeat
        if isfile(out)
            open(out, "a") do o
                write(o, "[" * string(time) * "]: $message\n")
                touch(out)
                write(o, "[" * string(time) * "]: $message\n")
            end
            show_log(level, message, levels,
            prefix, time)
        else
            show_log(1, "$out not in current working directory.", levels,
            prefix, time)
            show_log(1, message, levels,
            prefix, time)
        end
    else
        show_log(level, message, levels,
        prefix, time)
    end
end
==#

mutable struct Logger <: AbstractExtension

end

function route!(c::AbstractConnection, e::Logger)
    println("hello")
end

on_start(mod::Module, ext::Logger) = begin
    println("HELLO")
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
    print(Crayon(foreground = :light_gray, bold = true), "[")
    print(levels[:time_crayon], string(time))
    print(Crayon(foreground = :light_gray, bold = true), "]: ")
    print(levels[:message_crayon], prefix)
    print(levels[level], message, "\n", Crayon(foreground = :blue))
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
function route_from_dir(dir::String)
    dirs::Vector{String} = readdir(dir)
    routes::Vector{String} = []
    [begin
        if isfile("$dir/" * directory)
            push!(routes, "$dir/$directory")
        else
            if ~(directory in routes)
                newread::String = dir * "/$directory"
                newrs::Vector{String} = route_from_dir(newread)
                [push!(routes, r) for r in newrs]
            end
        end
    end for directory in dirs]
    routes::Vector{String}
end

module Files
    import Toolips: on_start
    function on_start(mod::Module, ext::Extension{Files})

    end
    function load!(ext::{Files}) end
    export load!
end

"""
### Files <: ServerExtension
- type::Symbol
- directory::String
- f::Function -
Writes all files in directory to their own routes in the server.
------------------
##### field info
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
mutable struct Files
    type::Symbol
    directory::String
    f::Function
    function Files(directory::String = "public")
            l = length(directory) + 1
            for path in route_from_dir(directory)
                push!(r, Route(path[l:length(path)],
                c::Connection -> write!(c, File(path))))
            end
        new(:routing, directory, f)
    end
end
==#