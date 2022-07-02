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
# routing
Toolips Routes are structures that contain both a `Function` and a `String`. The `String` represents the URL from root that we wish to serve the `Function` at. The `Function` takes a single positional argument. The
argument can be any sort of [AbstractConnection](), unless specified otherwise by your `ServerTemplate`, this will be of type [Connection]().
```@docs
Toolips.Route
```
You can create a new route by either writing a function, or using
the `route` method. When using the latter approach, writing a function, it is important to remember that you will still need to call the `route` method after. `Route` functions and strings can be provided in any order to the `route` method.
```julia
using Toolips

function myroutef(c::Connection)
  write!(c, "hello!")
end

myroute = route("/", myroutef)
otherroute = route("/otherroute") do c::Connection
  write!(c, "goodbye!")
end
```
```@docs
Toolips.route
```
## composing routes
Routes can be composed into a `Vector{Route}` using the `routes` method. The `ServerTemplate` type, which utilizes our routes, will only take a `Vector{Route}`, so it is important that we compose routes using either the `routes` method, or by calling the `Vector{Route}` constructor.
```julia
using Toolips

function myroutef(c::Connection)
  write!(c, "hello!")
end

myroute = route("/", myroutef)
otherroute = route("/otherroute") do c::Connection
  write!(c, "goodbye!")
end

myroutes = Vector{Route}(myroute, otherroute)
myroutes = routes(myroute, otherroute)
```
## serving routes
Routes are served by the [ServerTemplate]() type. We can either provide routes to the constructor, or add them individually with `ServerTemplate.add`.
```julia
using Toolips

function myroutef(c::Connection)
  write!(c, "hello!")
end

myroute = route("/", myroutef)
otherroute = route("/otherroute") do c::Connection
  write!(c, "goodbye!")
end

myroutes = routes(myroute)

st = ServerTemplate("127.0.0.1", 8000, myroutes)
st.add(otherroute)
```
We can then begin the serving of these routes with `ServerTemplate.start`:
```julia
st.start()
```
Routes can also be removed using the `unroute!` method.
```
st = ServerTemplate("127.0.0.1", 8000, myroutes)
st.add(otherroute)
st.remove("/otherroute")
```
## changing routes
Routes can also be modified via the command-line interface while the `WebServer` is running. This can be done both inside of a `route` on a [Connection](), as well as inside of a Julia REPL on a [WebServer]()
```julia
using Toolips

function myroutef(c::Connection)
  # Change the route via setindex!:
  c["/"] = otherroute
  # Change the route via route!:
  route!(c, "/") do c::Connection
    write!(c, "goodbye!")
  end
  route!(c, otherroute)
end

function otherroute(c::Connection)
  write!(c, "goodbye!")
end

myroute = route("/", myroutef)
myroutes = routes(myroute)

st = ServerTemplate("127.0.0.1", 8000, myroutes)
```
We can also remove a route using the `unroute!` method:
```julia
function myroutef(c::Connection)
  # Change the route via setindex!:
  c["/"] = otherroute
  # Change the route via route!:
  route!(c, "/") do c::Connection
    write!(c, "goodbye!")
  end
end
```
The same technique can also be applied to a [WebServer]().
```julia
using Toolips

st = ServerTemplate("127.0.0.1", 8000, myroutes)
webserver = st.start()

route!(webserver, "/") do c::Connection
  write!(c, "I am a rerouted route!")
end
```
