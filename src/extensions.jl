#==
map
- file interpolation
- additional connections
- logger
- mount
==#

"""
```julia
interpolate!(c::AbstractConnection, f::File{<:Any}, components::AbstractComponent ...; args ...)
```
`interpolate!` is used to mutate a `File` prior to serving. To this `Function`, we can provide an infinite list of 
`Components`. In the template, we will provide the `Component` `name` with a `\$`. Key-word arguments are named data values, 
which are named similarly in your HTML.
---
- **sample HTML**
```html
<div id="header-container">
<img src="/images/myimg.png">
</img>
\$navbar
</div>
<div id="body-contents">
<p>You are user #\$n</p>
</div>
```
- **sample accompanying server**
```julia
module InterpServer
using Toolips
f = File("pages/sample.html")
r = route("/") do c::Connection
    if ~(:clients in keys(c.data))
        c[:clients] = 0
    end
    c[:clients] += 1
    # build navbar
    navbar = div("examplenav")
    [push!(navbar, button("\$n", text = n)) for n in ("one", "two", "three")]
    interpolate!(f, navbar, n = c[:clients])
end
export r
end
```
"""
function interpolate!(c::AbstractConnection, f::File{<:Any}, components::AbstractComponent ...; args ...)
    rawfile::String = read(dir, String)
    [begin
        rawc = string(comp)
        rawfile = replace(rawfile, "\$$(comp.name)" => rawc)
    end for comp in components]
    [begin
        rawfile = replace(rawfile, "\$$(arg[1])" => arg[2])
    end for arg in args]
    write!(c, rawfile)
    nothing::Nothing
end
"""
```julia
MobileConnection <: AbstractConnection
```
- stream**::HTTP.Stream**
- data**::Dict{Symbol, Any}**
- ret**::Any**

A `MobileConnection` is used with multi-route, and will be created when an incoming `Connection` is mobile. 
This is done by simply annotating your `Function`'s `Connection` argument when calling `route`. To create one 
page for both of these routes, we then use `route` to combine them.
```julia
module ExampleServer
using Toolips
main = route("/") do c::Connection
    write!(c, "this is a desktop.")
end

mobile = route("/") do c::Toolips.MobileConnection
    write!(c, "this is mobile")
end

# multiroute (will call `mobile` if it is a `MobileConnection`)
home = route(main, mobile)

# then we simply export the multi-route
export home
end
using Toolips; Toolips.start!(ExampleServer)
```
- See also: `route`, `Connection`, `route!`, `Components`, `convert`, `convert!`

It is unlikely you will use this constructor unless you are calling 
`convert!`/`convert` in your own `route!` design.
```julia
MobileConnection(stream::HTTP.Stream, data::Dict{Symbol, Any}, routes::Vector{AbstractRoute})
```
"""
mutable struct MobileConnection <: AbstractConnection
    stream::HTTP.Stream
    data::Dict{Symbol, Any}
    routes::Vector{AbstractRoute}
end

function convert(c::Connection, routes::Routes, into::Type{MobileConnection})
    get_client_system(c)[2]::Bool
end

function convert!(c::Connection, routes::Routes, into::Type{MobileConnection})
    MobileConnection(c.stream, c.data, routes)::MobileConnection
end

"""
```julia
Logger <: Toolips.AbstractExtension
```
- `crayons`**::Vector{Crayon}**
- `prefix`**::String**
- `write`**::Bool**
- `writeat`**::Int64**
- `prefix_crayon`**::Crayon**


```julia
Logger(prefix::String = "🌷 toolips> ", crayons::Crayon ...; dir::String = "logs.txt", write::Bool = false, 
writeat::Int64, prefix_crayon::Crayon = Crayon(foreground  = :blue, bold = true))
```
###### example
```example
module ExampleServer
using Toolips
crays = (Toolips.Crayon(foreground = :red), Toolips.Crayon(foreground = :black, background = :white, bold = true))
log = Toolips.Logger("yourserver>", crays ...)

# use logger
route("/") do c::Connection
    log(c, "hello world!", 1)
end
# load to server
export log
end
using Toolips; Toolips.start!(ExampleServer)
```
- See also: `route`, `Connection`, `Extension`
"""
mutable struct Logger <: AbstractExtension
    crayons::Vector{Crayon}
    prefix::String
    write::Bool
    writeat::Int64
    prefix_crayon::Crayon
    function Logger(prefix::String = "🌷 toolips> ", crayons::Crayon ...; dir::String = "logs.txt",
        write::Bool = false, writeat::Int64 = 3, prefix_crayon = Crayon(foreground  = :blue, bold = true))
        if write && ~(isfile(dir))
            try
                touch(dir)
            catch
                throw("Logger tried to make log file \"$dir\", but could not.")
            end
        end
        if length(crayons) < 1
            crayons = [Crayon(foreground  = :light_blue, bold = true), Crayon(foreground = :yellow, bold = true), 
            Crayon(foreground = :red, bold = true)]
        end
        new([crayon for crayon in crayons], prefix, write, writeat, prefix_crayon)
    end
end

function log(l::Logger, message::String, at::Int64 = 1)
    cray = l.crayons[at]
    println(l.prefix_crayon, l.prefix, cray, message)
end

"""
```julia
log(c::Connection, message::String, at::Int64 = 1) -> ::Nothing
```
---
`log` will print the message with your `Logger` using the crayon `at`. `Logger` 
will give a lot more information on this.
#### example
```example
module MyServer
using Toolips

logger = Toolips.Logger()

home = route("/") do c::Connection
    log(c, "hello server!")
    write!(c, "hello client!")
end

export home, logger
end
```
"""
log(c::Connection, args ...) = log(c[:Logger], args ...)

"""
```julia
mount(fpair::Pair{String, String}) -> ::Route{Connection}/::Vector{Route{Connection}}
```
---
`mount` will create a route that serves a file or a all files in a directory. 
The first part of `fpair` is the target route path, e.g. `/` would be home. If 
the provided path is as directory, the Function will return a `Vector{AbstractRoute}`. For 
a single file, this will be a route.
#### example
```example
module MyServer
using Toolips

logger = Toolips.Logger()

filemount::Route{Connection} = mount("/" => "templates/home.html")

dirmount::Vector{<:AbstractRoute} = mount("/files" => "public")

export filemount, dirmount, logger
end
```
"""
function mount(fpair::Pair{String, String})
    fpath::String = fpair[2]
    target::String = fpair[1]
    if ~(isdir(fpath))
        if ~(isfile(fpath))
            throw(RouteError{String}(fpair[1], "Unable to mount $(fpair[2]) (not a valid file or directory, or access denied)"))
        end
        return(route(c::Connection -> begin
            write!(c, File(fpath))
        end, target))::AbstractRoute
    end
    if length(target) == 1
        target = ""
    elseif target[length(target)] == "/"
        target = target[1:length(target)]
    end
    [begin
        route(c::Connection -> write!(c, File(path)), target * replace(path, fpath => "")) 
    end for path in route_from_dir(fpath)]::Vector{<:AbstractRoute}
end

function route_from_dir(path::String)
    dirs::Vector{String} = readdir(path)
    routes::Vector{String} = []
    [begin
        fpath = "$path/" * directory
        if isfile(fpath)
            push!(routes, fpath)
        else
            if ~(directory in routes)
                newrs::Vector{String} = route_from_dir(fpath)
                [push!(routes, r) for r in newrs]
            end
        end
    end for directory in dirs]
    routes::Vector{String}
end