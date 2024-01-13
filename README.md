<div align = "center">
  <img src="https://github.com/ChifiSource/image_dump/blob/main/toolips/toolips03.png" /img>

[![deps](https://juliahub.com/docs/Toolips/deps.svg)](https://juliahub.com/ui/Packages/Toolips/TrAr4?t=2)
[![version](https://juliahub.com/docs/Toolips/version.svg)](https://juliahub.com/ui/Packages/Toolips/TrAr4)
</br>

[documentation](https://documentation.c/toolips) **|** [extensions](https://github.com/ChifiSource#toolips-extensions) **|** [examples](https://github.com/ChifiSource/OliveNotebooks.jl/tree/main/toolips)

</div>

`toolips` is an **asynchronous**, **low-overhead** web-development framework for Julia. Toolips.jl in a nutshell:
- **HTTPS capable** Can be deployed with SSL.
- **Extensible** server platform.
- **Declarative** and **composable** html *and* CSS templating syntax.
- **Modular** servers -- toolips applications are **regular Julia Modules**.
- **Versatilility** -- toolips can be used for all scenarios, from full-stack web-development to APIs -- all facilitated through multiple dispatch.
- **Multiple-Dispatch Routing** -- Dispatch routes based on more than just their target.
- **Multi-threaded** -- *Declarative* [parametric processes](https://github.com/ChifiSource/ParametricProcesses.jl) using a [Distributed]()-based worker management system.
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
  - [quick start](#quick-start)
    - [documentation](#documentation)
    - [overview](#overview)
  - [examples](#examples)
    - [API](#api-example)
    - [Online form](#form-example)
    - [Blog](#blog-example)
    - [Animated splash](#animated-example)
  - [contributing]()
    - [guidelines]()
    - [building extensions]()
---
- **toolips requires [julia](https://julialang.org/). [julia installation instructions](https://julialang.org/downloads/platform/)**
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
##### quick start
Getting started with `Toolips` starts by creating a new `Module` To get started with `Toolips`, we can we may either use `Toolips.new_app(name::String)` (*ideal to build a project*)or we can simply create a `Module` (*ideal to try things out*).
```julia
using Toolips
Toolips.new_app("ToolipsApp")
```
We may also add a `ServerTemplate` to `new_app` to construct from a specific template. `Toolips` base includes `WebServer` and `ThreadedWebServer{N}`. The `WebServer` project is designed to give a moderate understanding of using `Toolips` in a single-threaded context, the `ThreadedWebServer` project is designed to familiarize you will utilizing threads in `Toolips` (as well as explain more about the [ParametricProcesses](https://github.com/ChifiSource/ParametricProcesses.jl) distributed computing platform.
```julia

```
###### documentation
`Toolips` documentation is built into the `Toolips` `Module` itself. We can **export** the route `Toolips.toolips_doc` to load the `Toolips` documentation into our server, which we may then visit at `/doc` or use `start!(Toolips)` to view it.
```julia
using Toolips
start!(Toolips)
```
The `Toolips` server will load 4 routes -- `default_404`, `toolips_app`, `toolips_doc`, and `default_landing`. We may *also* provide these as exports to our own server in order to load those routes.
```julia
module MyServer
home = route("/") do c::Connection
    write!(c, "hello world!")
end
```
###### overview


    


#### examples
###### blog example
###### animated splash
#### contributing
###### guidelines
