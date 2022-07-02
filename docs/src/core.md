# core
Below is a runthrough of all of the documentation pertaining to running a
Toolips server.

## connection
```@docs
Connection
```
Connections are served as an argument to incoming routes. Functions are written
anticipating a connection return. Here we will write a new route using the
route(::Function, ::String) method.
```@eval
using Toolips
r = route("/") do c::Connection
    write!(c, "Hello!")
end
```
We also use the write!() method on our Connection. We can use this on the types
::Any, ::Vector{Servable}, and ::Servable.
```@docs
write!
```
Or push any data response into a body and startread the body.
```@docs
push!(::AbstractConnection, ::Any)
Toolips.startread!(::AbstractConnection)
Toolips.extensions(::Connection)
routes(::AbstractConnection)
has_extension(::AbstractConnection, ::Type)
```
The connection type can be indexed with Symbols, Strings, and Types. Symbols and
Types will index the extensions. Strings will index the routes. The same goes
for setting the indexes.
```@docs
setindex!(::AbstractConnection, ::Function, ::String)
getindex(::AbstractConnection, ::Symbol)
getindex(::AbstractConnection, ::Type)
getindex(::AbstractConnection, ::String)
```
We also use the Connection in order to get arguments, download files, and
pretty much anything else pertaining to a person's connection.
```@docs
getarg
getargs
getip
getpost
Toolips.download!
navigate!
```
We can also check if an extension is present by type.
```@docs
has_extension(::Connection, ::Type)
```
## servers
ToolipsServers are created by ServerTemplates. Here is a look at how to make a
ServerTemplate:
```@docs
ServerTemplate
```
The ServerTemplate.start() function returns a sub-type of ToolipsServer.
```@docs
ToolipsServer
WebServer
getindex(::WebServer, ::Symbol)
Toolips.routes(::WebServer)
Toolips.extensions(::WebServer)
```
## server extensions
Server extensions are provided to the ServerTemplate type. You may read more about them in the developer api.
There are also a few default extensions included with toolips. These can be used
by passing them in a Symbol-labeled dictionary as the extensions key-word
argument on a **ServerTemplate** These are Logger and Files.
```@docs
Logger
Files
```
