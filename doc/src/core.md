# core
Below is a runthrough of all of the documentation pertaining to running a
Toolips server.
## requests
Toolips has some bindings that pre-parse responses fro you, these are both post
and get requests.
```@docs
get
post
```
## connections
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
write!(::Connection, ::Any)
write!(::Connection, ::String)
write!(::Connection, ::Servable ...)
write!(::Connection, ::Vector{Servable})
write!(::Connection, ::Servable)
```
Or push any data response into a body and startread the body.
```@docs
push!(::Connection, ::Any)
startread!(::Connection, ::Any)
```
The connection type can be indexed with Symbols, Strings, and Types. Symbols and
Types will index the extensions. Strings will index the routes. The same goes
for setting the indexes.
```@docs
getindex(::Connection, ::Symbol)
getindex(::Connection, ::Type)
getindex(::Connection, ::String)
```
We also use the Connection in order to get arguments, download files, and
pretty much anything else pertaining to a person's connection.
```@docs
getarg
getargs
getip
postarg
getpost
postargs
download!
navigate!
```
We can also check if an extension is present by type.
```@docs
has_extension(::Connection, ::Type)
```
## routing
When routing, many methods involve the **Connection** type we just spoke of. In
toolips, routes are handled by the Route type.
```@docs
Route
```
The Route's constructors are not typically called directly, instead it is
probably better to use these methods. Using route! as opposed to route! will
modify the routes of a Connection or ToolipsServer
```@docs
route
route!
unroute!
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
```
We can also call some methods on a **WebServer** in order to change our routes
## server extensions
All server extensions have the following consistencies:
```@docs
ServerExtension
```
There are also a few default extensions included with toolips. These can be used
by passing them in a Symbol-labeled dictionary as the extensions key-word
argument on a **ServerTemplate** These are Logger and Files.
```@docs
Logger
Files
```
