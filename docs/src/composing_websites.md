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
## creating Components
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
## composing Components
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
mybody = body("mybody")
push!(bodydiv, hello)
push!(headerdiv, headerimage, nameheading)
push!(mybody, headerdiv, bodydiv)
# ====
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
As with composing `Component`s, composing websites usually consists of pushing
different Components together to create a page. Let's create a new route function:
```julia
function myroute(c::Connection)

end
```
It is important that we make a very strong distinction between what is inside of
this function and outside of it. Everything contained outside of the function
**will be ran once.** A function, however is ran each time that the server is
routed. In the following example, our new element is pushed each time that the
function is called:
```julia
using Toolips

mydiv = divider("mydiv", align = "center")

function myroute(c::Connection)
  push!(mydiv, a("hello", text = "hello!"))
end
```
In this example, because `mydiv` is defined globally, all mutations made to this
type will be global. Therefore, every single visitor will get this same exact
instance of mydiv, along with all of the a's that are pushed to it. In some
instances, something global like this might be what you want, however, this is
definitely not always going to be the case, so you'll want to pay attention to
the difference between things that are ran on routes and off routes in order to
keep the scope limited to or not to a particular visitor's Connection.
```julia
using Toolips

function myroute(c::Connection)
  mydiv = divider("mydiv", align = "center")
  push!(mydiv, a("hello", text = "hello!"))
end
```
This example would have a new `mydiv` generated with new values pushed for each
incoming Connection. Now that we have a firm understanding of how the scope
will change our website, let's compose a website. I am going to start with our
`mydiv` from before.
```julia
function myroute(c::Connection)
  mydiv = divider("mydiv", align = "center")
  push!(mydiv, a("hello", text = "hello!"))
end
```
As far as styling our new div, we can either use a [Style]() type, or we can use
the method `style!`. I will be using the former for our div, applying a universal
style to all divs by naming our style `"div"`, and I will use style! for our text.
```julia
function myroute(c::Connection)
  divstyle = Style("div")
  mydiv = divider("mydiv", align = "center")
  ourtext = a("hello", text = "this is an example")
  push!(mydiv, ourtext)
end
```
#### div style
Styles can created both with arguments and indexing. We set the index of a given
property to a String, like so:
```julia
divstyle = Style("div")
divstyle["border-width"] = "10px"
divstyle["border-radius"] = "20px"
divstyle["border-color"] = "lightblue"
```
#### a style
When using the `style!` method, we provide the Component we wish to style as the
first positional argument, followed by an infinite number of pairs to style it with.
```julia
ourtext = a("hello", text = "this is an example")
style!(ourtext, "color" => "gray", "font-size" => "17pt")
```
For a final result on our route that looks like this:
```julia
function myroute(c::Connection)
  divstyle = Style("div")
  divstyle["border-width"] = "10px"
  divstyle["border-radius"] = "20px"
  divstyle["border-color"] = "lightblue"
  mydiv = divider("mydiv", align = "center")
  ourtext = a("hello", text = "this is an example")
  style!(ourtext, "color" => "gray", "font-size" => "17pt")
  push!(mydiv, ourtext)
end
```
If the div style were to actually be named, we would need to use `style!` again
to style the div:
```julia
function myroute(c::Connection)
  divstyle = Style("div")
  divstyle["border-width"] = "10px"
  divstyle["border-radius"] = "20px"
  divstyle["border-color"] = "lightblue"
  mydiv = divider("mydiv", align = "center")
  style!(mydiv, divstyle)
  ourtext = a("hello", text = "this is an example")
  style!(ourtext, "color" => "gray", "font-size" => "17pt")
  push!(mydiv, ourtext)
end
```
However, because our style is named div, this will now become the default style
for all divs, so we only need to write the style in order for it to be applied.
When composing web-pages, it is also a pretty good idea to `push!` all of your
`Component`s together universally under one `body` tag.
```julia
using Toolips

function myroute(c::Connection)
  divstyle = Style("div")
  divstyle["border-width"] = "10px"
  divstyle["border-radius"] = "20px"
  divstyle["border-color"] = "lightblue"
  mydiv = divider("mydiv", align = "center")
  write!(c, divstyle)
  ourtext = a("hello", text = "this is an example")
  style!(ourtext, "color" => "gray", "font-size" => "17pt")
  push!(mydiv, ourtext)

  mybody = body("mybody")
  style!(mybody, "background-color" => "aqua")
  push!(mybody, mydiv)
  write!(c, mybody)
end

st = ServerTemplate()
st.add(route("/", myroute))
st.start()
```
```@raw html
<img src = "../assets/screenshot_composing2.png"></img>
```
Let's modify these styles a little bid, making a divider now white, and set the border
style and padding. I am also going to add a top margin in order to give us more
space from the top.
```julia
divstyle["background-color"] = "white"
divstyle["border-style"] = "solid"
divstyle["padding"] = "50px"
divstyle["margin-top"] = "30px"
```
Let's also add a bit more content here. In order to do this very quickly and
effectively, I will use the `tmd` `Component` from the [ToolipsMarkdown]()
extension. This allows us to turn markdown into toolips components.
```julia
using Toolips
using ToolipsMarkdown: @tmd_str

greetmessage = tmd"""# Welcome to our sample site!
This is a sample site created for [The toolips documentation](https://doc.toolips.app/).
  It shows the basic workings of a website!
#### Packages used
- [Toolips](https://github.com/ChifiSource/Toolips.jl)
- [ToolipsMarkdown](https://github.com/ChifiSource/ToolipsMarkdown.jl)
"""
function myroute(c::Connection)
  divstyle = Style("div")
  divstyle["border-width"] = "10px"
  divstyle["border-radius"] = "20px"
  divstyle["border-color"] = "lightblue"
  divstyle["background-color"] = "white"
  divstyle["border-style"] = "solid"
  divstyle["padding"] = "50px"
  divstyle["margin-top"] = "30px"
  mydiv = divider("mydiv", align = "center")
  write!(c, divstyle)
  ourtext = a("hello", text = "this is an example")
  style!(ourtext, "color" => "gray", "font-size" => "17pt")
  push!(mydiv, ourtext, greetmessage)
  mybody = body("mybody")
  style!(mybody, "background-color" => "aqua")
  push!(mybody, mydiv)
  write!(c, mybody)
end

st = ServerTemplate()
st.add(route("/", myroute))
st.start()
```
```@raw html
<img src = "../assets/screenshot_composing3.png"></img>
```
## Adding Session
