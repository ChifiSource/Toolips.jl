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
# command-line interface
Toolips has a rather robust, but easy to understand command-line interface that is used via the [WebServer]() type. Extensions can be accessed by indexing a `WebServer` with a `Symbol` or the `extensions(::WebServer)` method, and routes can be accessed by doing `routes(::WebServer)`.
```julia
using Toolips

st = ServerTemplate()
r = route("/") do c::Connection
  write!(c, "my return")
end
st.add(r)

webserver = st.start()

println(extensions(webserver))

println(routes(webserver))
```
```julia
1-element Dict{Symbol, ServerExtension}
:Logger => Toolips.Logger(...)

1-element Dict{String, Function}
"/" => #5
```
We can also use the `WebServer` with the `route!` function with the following methods:
```@docs
route!(::WebServer, ::String, ::Function)
route!(::Function, ::WebServer, ::String)
route!(::WebServer, ::Route)
```
