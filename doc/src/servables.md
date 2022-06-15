# servables
Servables are any non-core data-structure that is built with the objective of
being written to a stream.
```@docs
Servable
```
## components
A component is a Servable which contains markup information and can easily be
translated into elements with properties..
```@docs
Component
```
Indexing a component will yield its .properties:
```@docs
getindex(::Servable, ::Symbol)
getindex(::Servable, ::String)
setindex!(::Servable, ::Any, ::Symbol)
setindex!(::Servable, ::Any, ::Symbol)
setindex!(::Servable, ::Any, ::String)
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
img
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
We can also compose components together using push! and style them using style!
```@docs
push!(::Servable, ::Servable)
push!(::Servable, ::Vector{Servable})
push!(::Component, ::Servable ...)
properties!(::Servable, ::Servable)
push!(::Component, ::Servable)
style!
```
## style components
Style components are change the style of a **Component**
```@docs
StyleComponent
```
The main style components are Animations and Styles.



```@docs
Animation
```
Animating and property adjustment is done with indexing.
```@docs

```
## file
The file Servable, as you might expect, serves a file via a directory.
```@docs
File
```
