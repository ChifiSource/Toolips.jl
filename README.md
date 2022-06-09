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
  
## Links
  **Documentation**
  - [Interactive Documentation]()
  - [Juliahub Documentation]() \
  **Examples**
  - [ToolipsApp.jl](https://github.com/emmettgb/ToolipsApp.jl)
  - [EmsComputer.jl](https://github.com/emmettgb/EmsComputer.jl)
  - [ChifiSource.jl](https://github.com/ChifiSource/ChifiSource.jl)
## Basics
  Toolips.jl is not like other web-development frameworks you might have used in the past. Toolips can be used as both a micro-framework and a full-stack framework, as well as everything in between. Servers are created with the ServerTemplate type.
```julia
  using Toolips
  using JLD2
  IP = "127.0.0.1"
PORT = 8000
  
  r = route("/") do c
    write!(c, "Hello world!")
  end
  
  model = @load "mymodel.jld2"
  
  model = route("/model") do c
    x = getarg(:x)
    write!(c, model.predict([x]))
  end
  
  rts = routes(model, r)
  
  servertemp = ServerTemplate(IP, PORT, rts)
  server = servertemp.start()
  
  ```
  Alternatively, we can also create a preset Toolips.jl file-structure using the **new_app** and **new_webapp** methods respectively.
  ```julia
  
  ```
  
