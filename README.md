<div align = "center">
  <img src = https://github.com/ChifiSource/Toolips.jl/blob/Unstable/assets/logo.svg  width = 200 height = 300/img>
</div>

**Toolips.jl** is a **fast**, multi-paradigm web-development framework built around closure pipelines, high-level syntax, servables, and [HTTP.jl](https://github.com/JuliaWeb/HTTP.jl). This is Julia's first true **full-stack** web-development framework. Toolips.jl wraps the process of creating front-ends, back-ends into one simple and reproducable return. Toolips.jl has a core focus on extendability, security, and versatility.includes methods for extending the server, which has a multitude of capabilities, extending servables, pretty much everything in here can be extended very easily.
- Extendable, robust servers with dynamic routing, and mutable data structures provided to closures as arguments.
- Closure-based function pipeline which can be edited, for a great hardware analogy, all of this means we can " hotswap" routes.
- Extendable Servables -- You can return compositions of servables very easily.
- Abstraction -- the code for Toolips.jl is very minimalist and extracted, making it much easier to extend.
- Speed -- Toolips.jl has a central focus on having a few really fast functions be the main calls which are recycled throughout.
- Speed of use -- Build websites in minutes that are both beautiful and act as expected. No weird quirks or non-sense, just pure and simple web-development.
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
  
