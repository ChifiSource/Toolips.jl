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
provide
## composing elements

## composing websites
