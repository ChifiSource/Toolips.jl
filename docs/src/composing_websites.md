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
# composing websites
Composing websites in toolips typically involves adding children to a main
`Component`, and then writing it to the `Connection`. We can add children to a
given `Component` using the `push!(::Component, ::Component)` method. Properties
are added via `setindex`. In this regard, routes become pages, and Components become
the contents of those pages.
```julia
using Toolips

function myroute(c::Connection)
  component = divider("hello_world!")
  write!(c, component)
end
```
## creating elements
Elements can be created using any of the `Component` methods found in
[the Components section]("servables/components/index.html"). For example, we can
create a `p`:
```julia
hello = p("myp")
```
The first, and only, positional argument to provide here is a `String`, which will
be the name of our `Component`. The name is important because different ServerExtensions
can use the Component's name in order to refer to the Component. After this, we can
provide an infinite list of key-word arguments to fill out different properties of
each element.
```julia
hello = p("myp", align = "center", text = "hello!")
```
For properties that contain a dash, which could happen in HTML, we will need to
use `setindex!`.
```julia
hello["my-property"] = 5
```
A full list of element properties, which can also be **anything** is available
[here](servables/component_attributes/index.html)
## composing elements
We can add children to an element using the `push!` method. Composing pages typically
involves pushing elements together. Consider the following example:
```julia
headerimage = img("headerimage", src = "images/logo.png")
nameheading = h("nameheading", 1, text = "emmy's site !")
hello = p("myp", text = "hello!")
headerdiv = divider("headerdiv", align = "center")
bodydiv = divider("bodydiv")

push!(headerdiv, headerimage, nameheading)
push!(bodydiv, hello)
```
We could further compose these new components into a body tag, as well.
```julia
headerimage = img("headerimage", src = "images/logo.png")
nameheading = h("nameheading", 1, text = "emmy's site !")
hello = p("myp", text = "hello!")
headerdiv = divider("headerdiv", align = "center")
bodydiv = divider("bodydiv")

push!(headerdiv, headerimage, nameheading)
push!(bodydiv, hello)
# ====
mybody = body("mybody")
push!(mybody, headerdiv, bodydiv)
```
Note that everything that is pushed will be served **in the order it is pushed**.
```julia
using Toolips
headerimage = img("headerimage", src = "images/logo.png")
nameheading = h("nameheading", 1, text = "emmy's site !")
hello = p("myp", text = "hello!")
headerdiv = divider("headerdiv", align = "center")
bodydiv = divider("bodydiv")

push!(headerdiv, headerimage, nameheading)
push!(bodydiv, hello)
# ====
mybody = body("mybody")
push!(mybody, headerdiv, bodydiv)

function myroute(c::Connection)
  write!(c, mybody)
end

st = ServerTemplate()
st.add(route("/", myroute))
st.start()
```
```@raw html
<img src = "../assets/screenshot_composing1.png"></img>
```
## composing websites
