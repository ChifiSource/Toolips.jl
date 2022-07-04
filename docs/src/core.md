```@raw html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Poppins&family=Roboto+Mono:wght@100&family=Rubik:wght@500&display=swap" rel="stylesheet">

<style>
body {background-color: #FDF8FF !important;}
header {background-color: #FDF8FF !important}
h1 {
  font-family: 'Poppins', sans-serif !important;
  font-family: 'Roboto Mono', monospace !important;
  font-family: 'Rubik', sans-serif !important;}

  h2 {
    font-family: 'Poppins', sans-serif !important;
    font-family: 'Roboto Mono', monospace !important;
    font-family: 'Rubik', sans-serif !important;}
    h4 { color: #03045e !important;
      font-family: 'Poppins', sans-serif !important;
      font-family: 'Roboto Mono', monospace !important;
      font-family: 'Rubik', sans-serif !important;}
article {
  border-radius: 30px !important;
  border-color: lightblue !important;
}
pre {
  border-radius: 10px !important;
  border-color: #FFE5B4 !important;
}
p {font-family: 'Poppins', sans-serif;
font-family: 'Roboto Mono', monospace;
font-family: 'Rubik', sans-serif; color: #565656;}
</style>
```
# servers
`ToolipsServer`s are created by `ServerTemplate`s. The main type of `ToolipsServer` is the `WebServer`, which is provided as a return from the `ServerTemplate.start()` function.
## server templates
```@docs
ServerTemplate
```
## toolips servers
The `ServerTemplate.start()` function returns a sub-type of `ToolipsServer`, usually a `WebServer`.
```@docs
ToolipsServer
```
The WebServer type is similar to a `Connection` in that it can be routed, and holds the Connection extensions. This type is useful for when we want to control our server from a command-line interface in our Julia REPL.
```julia
using Toolips

myroute = route("/") do c::Connection
  myp = p("myp", text = "Hello world!")
  mydiv = divider("mydiv")
  push!(mydiv, myp)
  write!(c, mydiv)
end

st = ServerTemplate()
st.add(myroute)
ourwebserver = st.start()
```
```@docs
WebServer
```
We can call the `routes` and `extensions` methods on a `WebServer`, just like a `Connection`
```@docs
Toolips.routes(::WebServer)
Toolips.extensions(::WebServer)
```
Similarly, we can index our `WebServer` with a `Symbol`, or use the `route!` method in the same manor as we would a `Connection`.
```julia
using Toolips

myroute = route("/") do c::Connection
  myp = p("myp", text = "Hello world!")
  mydiv = divider("mydiv")
  push!(mydiv, myp)
  write!(c, mydiv)
end

st = ServerTemplate()
st.add(myroute)
ourwebserver = st.start()

ourwebserver[:Logger].log("Hello!")
route!(ourwebserver, "/") do c::Connection
  write!(c, p("myp", text = "our new route"))
end
function newr(c::Connection)
  write!(c, "hello")
end
route!(ourwebserver, "/", newr)
```
```@docs
getindex(::WebServer, ::Symbol)
```
## server extensions
A [ServerExtension] is an abstract type that can be used to add new capabilities
to a `ToolipsServer`. These extensions are provided in a Vector{ServerExtension}
to the `ServerTemplate`. We can create this Vector by simply putting a list of
extensions together.
```julia
using Toolips

extensions = [Logger(), Files()]
```
Toolips includes two extensions by default, the [Files]() extension and the
[Logger]() extensions. This `Vector` is provided as a key-word argument to
the `ServerTemplate` constructor.
```julia
using Toolips

extensions = [Logger(), Files()]

st = ServerTemplate(extensions = extensions)
st.start()
```
