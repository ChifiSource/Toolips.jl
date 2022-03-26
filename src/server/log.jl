using Dates

mutable struct Logger
    out::String
    levels::Dict
    log::Function
    function Logger(levels::Dict; out = "logs/log.txt")
        log(level::Int64, message::String) = _log(level, message, levels, out)
        log(message::String) = _log(1, message, levels, out)
        new(out, levels, log)
    end
    function Logger(; out = "log/log.txt")
        levels = Dict(1 => Crayon(foreground = :light_cyan),
        2 => Crayon(foreground = :light_yellow),
        3 => Crayon(foreground = :yellow),
        4 => Crayon(foreground = :red))
        Logger(levels; out = out)
    end
end
# print(, "In red. ", Crayon(bold = true), "Red and bold")
function _log(level::Int64, message::String, levels::Dict, out::String)
    time = now()
    if level > 1
        open(out) do o
            write(o, string("[", time, "]: ", message))
        end
    end
    println(Crayon(foreground = :light_gray), "[", levels[level], string(time),
     "]: ", )
end
