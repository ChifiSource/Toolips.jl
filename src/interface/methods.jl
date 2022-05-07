import Base: +
#==
File/system stuff
==#
"""
### write_file(URI::String, http::HTTP.Stream) -> _
------------------
Writes a file to an HTTP.Stream.

"""
function write_file(URI::String, http::HTTP.Stream)
    open(URI, "r") do i
        write(http, i)
    end
end

function route_from_dir(dir::String)
    dirs = readdir(dir)
    routes::Vector{String} = []
    for directory in dirs
        if isfile("$dir/" * directory)
            push!(routes, "$dir/$directory")
        else
            if ~(directory in routes)
                newread = dir * "/$directory"
                newrs = route_from_dir(newread)
                [push!(routes, r) for r in newrs]
            end
        end
    end
    rts::Vector{Route} = []
    for directory in routes
        if isfile("$dir/" * directory)
            push!(rts, Route("/$directory", file("$dir/" * directory)))
        end
    end
    rts
end
#==
HTTP Arguments/Requests
==#
