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
      - [routing](#routing)
      - [extensions](#extensions)
    - [responses](#responses)
      - [files](#files)
      - [components](#components)
  - [examples](#examples)
    - [user api](#user-api)
    - [NAS server](#nas-server)
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
The quickest way to access `Toolips` documentation is to use the server built into `Toolips` itself. For this, simply run `start!(Toolips)`:
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
exporthome, toolips_doc, default_404
end
```
- `toolips_app` is an in-`Module` route-manager for `Toolips` servers.
- `toolips_doc` is a documentation browser for `Toolips` and other packages.
- `default_landing` is a simple landing page, which provides links to `toolips_doc` and `toolips_app` -- primarily designed for when `Toolips` is started directly with `start!`.
- `default_404` is a 404 page that can be used in your apps.

There is also the [Toolips web documentation](), which is a far more robust and complete website which might be ideal for beginners, but also requires an internet connection. This `README` also serves as a great introduction to `Toolips`, which is not too complicated outside beyond the general scope of this `README`. It might also be valuable to learn more about templating if you are creating frontend applications, for this you will want to check out [`ToolipsServables`](#https://github.com/ChifiSource/ToolipsServables.jl).
#### quick start
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
## projects and routes
In `Toolips`, projects are modules which **export** `Toolips` types. These special types are
- Any sub-type of `AbstractRoute`.
- Any sub-type of `Extension`.
- or a `Vector{<:AbstractRoute}`

To quickly create a project from a template, you may use `new_app(::String)`, but the code to create a server is also pretty easy to do quickly if needed.
```julia
module HelloWorld
using Toolips

home = route("/") do c::Connection
    write!(c, "hello world")
end

export start!, home
end
```
```julia
# starts our server:
using HelloWorld; start!(HelloWorld)
```
### routing
```julia
home = route("/") do c::Connection
    write!(c, "hello world!")
end
```
To create a `Route`, we provide the `route` `Function` with a **target**, a `String` path starting at `/` to mount the website's base URL and a `Function` passed through **do**. The general `Toolips` process on a route is creating data and then writing it to the `Connection` with `write!`. The `Function` we provide will take a `<:` of an `AbstractConnection`. We are able to annotate this argument in our `route` call to change our route's functionality based on the dispatch. This creates what is effectively *multiple dispatch routing*, consider the example below:
```julia
module HelloWorld
using Toolips

desktop_home = route("/") do c::Connection
    write!(c, "hello world")
end

mobile_home = route("/") do c::MobileConnection
    write!(c, "hello world")
end

# multi-routing our home
home = route(mobile_home, desktop_home)
export start!, home
end
```
In the case above, mobile clients will be redirected to the latter `Function`, as their `Connection` will convert into a `MobileConnection`.

Routes are stored in the `Connection` under `Connection.routes`. We can dynamically change our `routes` by mutating this `Vector{<:AbstractRoute}`.
```julia
module ToolipsServer
using Toolips
using Toolips.Components

home = route("/") do c::Connection
    new_route = route("/newpage") do c::Connection
        write!(c, "second page")
    end
    push!(c.routes, new_route)
    # creating a quick page to link to our route
    lnk = a("othersite", text = "visit new route", align = "center", href = "/newpage")
    style!(lnk, "margin-top" => 10percent)
    write!(c, lnk)
end

export default_404, home
end
```
Data can also be stored in the `Connection`, and this includes some extensions.
```julia
```
There are several "getter" methods associated with the `Connection`, here is a comprehensive list:
```julia
get_args
get_heading
get_ip
get_post
get_method
get_post
get_parent
get_client_system
```
All of these take a `Connection` and are pretty self explanatory with the exception of `get_client_system`. This will provide the system of the client, but also whether or not the client is on a mobile system. Note that the operating system is given as the request header gives it, of course.
```julia
client_operating_system_name, ismobile = get_client_system(c)
```
There's also
```julia
proxy_pass!(c::Connection, url::String)
startread!(c::AbstractConnection)
download!(c::AbstractConnection, uri::String)
```
### extensions
## responses
#### examples
###### user API
###### NAS server
### contributing
###### contributing guidelines
