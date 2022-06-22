# servables
Servables are any non-core data-structure that is built with the objective of
being written to a stream.
## requests
Toolips has some bindings that pre-parse responses fro you, these are both post
and get requests.
```@docs
get
post
```
## components
A component is a Servable which contains markup information and can easily be
translated into elements with properties..
```@docs
Component
```
Indexing a component will yield its .properties:
```@docs
getindex(::Component, ::Symbol)
getindex(::Component, ::String)
setindex!(::Servable, ::Any, ::Symbol)
getindex(::Vector{Servable}, ::String)
setindex!(::Servable, ::Any, ::String)
getindex(::Servable, ::String)
```
There is a library of default components that comes with toolips. Generally,
their name coincides with a docstring. All of these take an infinite number of
key-word arguments. These arguments become the properties of a Servable.
```@docs
img
link
meta
input
a
p
h
ul
li
divider
br
i
title
span
iframe
svg
element
label
script
nav
button
form
```
We can also compose components together using push!, and work with them using the following methods:
```@docs
push!(::Component, ::Component ...)
style!
components
Toolips.has_children
Toolips.properties!
getindex(::)
```
## style components
Style components change the style of a **Component**
```@docs
StyleComponent
```
The main style components are Animations and Styles.
```@docs
Toolips.Style
```

```@docs
Animation
animate!
delete_keyframe!
```
Animating and property adjustment is done with indexing.
```@docs
setindex!(::Animation, ::Pair, ::Symbol)
setindex!(::Animation, ::Pair, ::Int64)
```
## other servables
The file Servable, as you might expect, serves a file via a directory.
```@docs
File
```
Servables are also incredibly easy to write, and part of the beauty of
toolips is just how easy it is to create these kinds of extensions in
toolips!
