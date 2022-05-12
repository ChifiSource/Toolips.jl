<div align = "center">
  <img src = https://github.com/ChifiSource/Toolips.jl/blob/Unstable/assets/logo.svg  width = 200 height = 300/img>
</div>

**Toolips.jl** is a multi-paradigm web-development framework built around function calls and [HTTP.jl](https://github.com/JuliaWeb/HTTP.jl). This is Julia's first true **full-stack** web-development framework, and it is likely that by a stable release you will be able to do just about anything you may elsewhere with Toolips.jl. **Here are some of the features that the framework includes:**
##### Extendability
A core value of the Toolips.jl project is to be as modular as possible. Keeping components small and simple keeps larger systems from breaking. That being said, extendability is incredibly important to the project. The module includes methods for extending the server, which has a multitude of capabilities, extending servables, pretty much everything in here can be extended very easily.
##### High-level
In some cases, the Toolips syntax can actually be easier than it is inside of markup, things are simple, functional, and easy to understand.
- Extendable components.
- A library of servables.
- A high-level routing interface.
- A simple library of request methods.
- Dynamic Routing.
```julia
julia> # Press ] to enter your Pkg REPL
julia> ]
pkg> add https://github.com/ChifiSource/Toolips.jl
```
  <details class="details-overlay">
  <summary class="btn"><h2>Using Toolips</h2></summary>
<div>
 Currently, there is no documentation really put together for Toolips.jl. The package is still relatively new, and I am still trying to get a decent enough candadite for release, although I am most definitely getting close! If you would like to learn how to use the package without the docs, I would suggest referencing this sample application:
  https://github.com/emmettgb/ToolipsApp.jl
  
