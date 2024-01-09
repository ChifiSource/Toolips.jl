<div align = "center">
  <img src="https://github.com/ChifiSource/image_dump/blob/main/toolips/toolips03.png" /img>

[![deps](https://juliahub.com/docs/Toolips/deps.svg)](https://juliahub.com/ui/Packages/Toolips/TrAr4?t=2)
[![version](https://juliahub.com/docs/Toolips/version.svg)](https://juliahub.com/ui/Packages/Toolips/TrAr4)
</br>

[documentation](https://documentation.c/toolips) **|** [extensions](https://github.com/ChifiSource#toolips-extensions) **|** [examples](https://github.com/ChifiSource/OliveNotebooks.jl/tree/main/toolips)

</div>

`toolips` is a **fast**, **asynchronous**, **low-memory**, **full-stack**, and **reactive** web-development framework **always** written in **pure** Julia. Here is Toolips.jl in a nutshell:
- **HTTPS capable** Can be deployed with SSL.
- **Extensible** everything!
- **Declarative** html *and* CSS templating syntax.
- **Modular** servers. Toolips applications are **regular Julia Modules**.
- **Versatilility**. toolips can be used for all scenarios, from full-stack web-development to APIs -- all facilitated through multiple dispatch.
```julia
using Pkg; Pkg.add("Toolips")
```
```julia
julia> # Press ] to enter your Pkg REPL
julia> ]
pkg> add Toolips
```
###### map
- [get started](#get-started)
  - [overview](#overview)
  - [servers](#servers)
    - [routing](#routing)
    - [extensions](#extensions)
  - [templating](#templating)
    - [components]()
    - [style components]()
    - [files]()
  - [quick start](#quick-start)
    - [API](#api-example)
    - [Online form](#form-example)
    - [Blog](#blog-example)
    - [Animated splash](#animated-example)
  - [contributing]()
    - [guidelines]()
    - [building extensions]()
---
#### get started
`Toolips` is available in four different flavors:
- Latest (main) -- The main working version of toolips.
- LTS (#lts) -- Long term support.
- stable (#stable) -- Faster, more frequent updates, stable -- but some new features are not fully implemented.
- and Unstable (#Unstable) -- Latest updates, least stable.
```julia
using Pkg
# Latest 
Pkg.add("Toolips")
Pkg.add("Toolips", rev = "lts")
Pkg.add("Toolips", rev = "stable")
Pkg.add("Toolips", rev = "Unstable")
```
Alternatively, you can add by version or last of version using an `x` revision.
```julia
using Pkg
Pkg.add("Toolips", rev = "0.2.x")
Pkg.add("Toolips", rev = "0.3.x")
```
##### overview
The `Toolips` package offers high-level declarative templating syntax atop an extensible polymorphic server platform. With `Toolips`, a `Module` becomes a manageable routing process.

All of these parts work together to create a high-level routing and templating syntax. To get started with `Toolips`, we can weither use `Toolips.new_app(name::String)` or we can simply create a `Module`.
The `Toolips` package is comprised of three main parts:
- [Toolips](https://github.com/ChifiSource/Toolips.jl/blob/0.3/src/Toolips.jl)
    - [ServerCore](https://github.com/ChifiSource/Toolips.jl/blob/0.3/src/ServerCore.jl) -- Provides processes
    - [ToolipsServables](https://github.com/ChifiSource/ToolipsServables.jl)

##### servers
###### routing
###### extensions
##### templating
###### components
###### style components
###### files
##### quick start
###### api example
###### form example
###### blog example
###### animated splash
#### contributing
###### guidelines
