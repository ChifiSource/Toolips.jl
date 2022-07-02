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
# connections
A `Connection` is passed as a single positional argument to every `Route`. The `Connection` contains the output stream that content is to be written to, a `Dict{Symbol, ServerExtension}` of Server Extensions, which can be accessed by indexing the `Connection` with a `Symbol`, and a `Dict{String, Function}` of routes that the server references. A different type of Connection can also be provided to a `ServerTemplate` in order to extend capabilities, but the new `AbstractConnection` must follow the consistencies of that type.
```@docs
AbstractConnection
Connection
```
## routes
Connection constructors, aside from the [SpoofConnection](developer_api/index.html#Toolips.SpoofConnection), which is meant to be used solely for development of extensions, should not be called directly. Instead, Connections should be passed as an argument into routes.
```julia
using Toolips

thisroute = route("/") do c::Connection

end
function thisroute(c::Connection)

end
```
Connections also contain the routes that are provided to your `ServerTemplate`. We can obtain all routes by using the `routes` method.
```@docs
routes(::AbstractConnection)
```
The routes can also be set, or retrieved using `setindex!` and `getindex!` with a `String` respectively.
```julia
using Toolips

function example(c::Connection)
  write!(c, "hello world!")
end
myroute = route("/") do c::Connection
  c["/helloworld"] = example
  this_function = c["/"]
end
```
```@docs
setindex!(::AbstractConnection, ::Function, ::String)
getindex(::AbstractConnection, ::String)
```
Another technique we could also use is the `route!` method.
```julia
using Toolips

function example(c::Connection)
  write!(c, "hello world!")
end
myroute = route("/") do c::Connection
  route!(c, "/helloworld") do c::Connection
    write!(c, "hello world!")
  end
end
```
## extensions
A `Connection` also carries some of the extensions loaded into a `ServerTemplate`. Note that this is not always the case, as some extensions are not loaded into the Connection to work. We can access the extensions with the `extensions` method.
```julia
using Toolips

myroute = route("/") do c::Connection
  ourextensions = extensions(c)
end
```
We can also check for a `Connection` extension by using the `has_extension` method.
```julia
using Toolips

myroute = route("/") do c::Connection
  if has_extension(c, Logger)
    c[:Logger].log("Hello world!")
  end
end
```
Extensions can be accessed by indexing a `Connection` or `WebServer` with a `Symbol`. The `ServerExtension`'s `Symbol` will be the type as a `Symbol`. We can also index with a `Type` directly.
```@docs
getindex(::AbstractConnection, ::Symbol)
getindex(::AbstractConnection, ::Type)
```
## servables basics
Servables are types that can be written to a `Connection`. This is done via the `Servable.f(::Connection)` method, which essentially becomes a `Route` inside of a `Type`. The main type of [Servable]() that comes with the toolips base is the `Component`. There are several methods that can be used to construct a `Component`, and a full list of the `Component`s that come with toolips are available [here](servables/components/index.html). For the following example, I will be using the `p` and `divider` Components. These are both equivalent to writing their tags in HTML, `<p>` and `<div>`. All Components take an infinite number of key-word arguments, which are element properties in HTML.
```julia
myroute = route("/") do c::Connection
# name - vvvvv | vvvvvvvvvvvvvv - setting text
  myp = p("myp", text = "Hello world!")
  mydiv = divider("mydiv")
end
```
## writing
All writing can be done via the `write!` method. We can write any type this way, as well as several different `Vector`s.
```@docs
write!
```
We will compose our `Component`s from before using the `push!` method, and write them to our `Connection` using this method.
```julia
myroute = route("/") do c::Connection
# name - vvvvv | vvvvvvvvvvvvvv - setting text
  myp = p("myp", text = "Hello world!")
  mydiv = divider("mydiv")
  push!(mydiv, myp)
  write!(c, mydiv)
end
```
We can then load this into a `ServerTemplate` and use `st.start()` to reveal what has been created.
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
st.start()
[2022:07:02:17:46]: 🌷 toolips> Toolips Server starting on port 8000
[2022:07:02:17:46]: 🌷 toolips> Successfully started server on port 8000
[2022:07:02:17:46]: 🌷 toolips> You may visit it now at http://127.0.0.1:8000
```
```@raw html
<img src = "../assets/screenshot_connection1.png"></img>
```
## arguments and posts
`Connection`s also hold the arguments and post bodies for a given request. GET request arguments can be obtained via the `getarg` or `getargs` methods. `getarg` will index specifically for a particular `Symbol`, whereas `getargs` will return a `Dict{Symbol, Any}` with the values parsed as `Any` by [ParseNotEval](https://github.com/ChifiSource/ParseNotEval.jl).
```@docs
getarg
getargs
```
We can also get the POST body as a `String` by calling the `getpost` method.
```@docs
getpost
```
We can restart the reading of a POST by using the startread! method.
```@docs
startread!(::AbstractConnection)
```
## controlling connections
Controlling a `Connection` is relatively straightforward, we can navigate a `Connection` to a new URL using the `navigate!` method:
```@docs
navigate!
```
We can download files using the `download!` method.
```@docs
Toolips.download!
```
Finally, we can get an incoming `Connection`'s IP-Address using the `getip` function.
```@docs
getip
```
