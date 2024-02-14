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
- **Declarative** and **composable** html, Javascript, *and* CSS templating syntax.
- **Modular** servers -- toolips applications are **regular Julia Modules**.
- **Versatilility** -- toolips can be used for *all* use-cases, from full-stack web-development to APIs and *even* UDP -- all facilitated through multiple dispatch and Julia's extensible `Method` platform.
- **Multiple-Dispatch Routing** -- Dispatch routes based on more than just their target, using *multiple dispatch* to divert different types of connections to different functions.
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
  - [documentation](#documentation)
  - [quick start](#quick-start)
    - [projects and routes](#projects-and-routes)
    - [responses](#responses)
  - [examples](#examples)
- [issues](#issues)
  - [contributing guidelines](#contributing-guidelines)
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
###### documentation
`Toolips` documentation is built into the `Toolips` `Module` itself, which is itself a `Toolips` server we can start.
```julia
using Toolips
start!(Toolips)
```
The `Toolips` server will load 4 routes -- `default_404`, `toolips_app`, `toolips_doc`, and `default_landing`. All of these routes may also be provided as exports for your own server.
```julia
module MyServer
home = route("/") do c::Connection
    write!(c, "hello world!")
end
export toolips_app, toolips_doc, default_404
```
- `toolips_app` is an in-`Module` route-manager for `Toolips` servers.
- `toolips_doc` is a documentation browser for `Toolips` and other packages.
- `default_landing` is a simple landing page, which provides links to `toolips_doc` and `toolips_app` -- primarily designed for when `Toolips` is started directly with `start!`.
- `default_404` is a 404 page that can be used in your apps.
##### quick start
Getting started with `Toolips` starts by creating a new `Module` To get started with `Toolips`, we can we may either use `Toolips.new_app(name::String)` (*ideal to build a project*)or we can simply create a `Module` (*ideal to try things out*).
```julia
using Toolips
Toolips.new_app("ToolipsApp")
```
We may also add a `ServerTemplate` to `new_app` to construct from a specific template. `Toolips` base includes only the `WebServer`, which is also the default.
```julia
Toolips.new_app("Example", Toolips.WebServer)
```
This is primarily used for extensions, for example; [ToolipsUDP](https://github.com/ChifiSource/ToolipsUDP.jl):
```julia
using ToolipsUDP
ToolipsUDP.new_app("Example", ToolipsUDP.UDPServer)
```
#### examples

### contributing
###### contributing guidelines
