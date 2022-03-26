using Dates

mutable struct Logger
    out::String
    levels::Dict
    log::Function
    function Logger(levels::Dict; out = "logs/log.txt")
        log(level::Int64, message::String) = _log(level, message, levels, out)
        log(message::String) = _log(1, message, levels, out)
        log(http::HTTP.Stream, message::String) = _log(http, message)
        new(out, levels, log)
    end
    function Logger(; out = "logs/log.txt")
        levels = Dict(1 => Crayon(foreground = :light_cyan),
        2 => Crayon(foreground = :light_yellow),
        3 => Crayon(foreground = :yellow, bold = true),
        4 => Crayon(foreground = :red, bold = true))
        Logger(levels; out = out)
    end
end
# print(, "In red. ", Crayon(bold = true), "Red and bold")
function _log(level::Int64, message::String, levels::Dict, out::String)
    time = now()
    if level > 1
        open(out) do o
            try
                write(o, string("[", time, "]: ", message))
            catch
                try
                    touch(out)
                    write(o, string("[", time, "]: ", message))
                catch
                    throw(ArgumentError("Cannot acces logs."))
                end
            end
        end
    end
    println(Crayon(foreground = :light_gray, bold = true), "[", levels[level],
     string(time), Crayon(foreground = :light_gray, bold = true), "]: ",
     message)
end

function _log(http::HTTP.Stream, message::String)
    write(http, "<script>console.log('" * message * "');</script>")
end
