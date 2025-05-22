<div align = "center">
  <img src="https://github.com/ChifiSource/image_dump/blob/main/toolips/toolips03.png" /img>

[![deps](https://juliahub.com/docs/Toolips/deps.svg)](https://juliahub.com/ui/Packages/Toolips/TrAr4?t=2)
[![version](https://juliahub.com/docs/Toolips/version.svg)](https://juliahub.com/ui/Packages/Toolips/TrAr4)
[![pkgeval](https://juliahub.com/docs/General/Toolips/stable/pkgeval.svg)](https://juliahub.com/ui/Packages/General/Toolips)
</br>

[documentation](https://chifidocs.com/toolips) **|** [extensions](https://github.com/ChifiSource#toolips-extensions) **|** [examples](https://github.com/ChifiSource/OliveNotebooks.jl/tree/main/toolips)

</div>

`Toolips` is an extensible web and server-development framework for the Julia programming language.
- **HTTPS capable** Can be deployed with SSL.
- **Extensible** server platform.
- **Hyper-Dynamic Multiple-Dispatch Routing** -- The `Toolips` router can be completely reworked with extensions to offer completely new and exceedingly versatile functionality.
- **Declarative** and **composable** -- files, html, Javascript, *and* CSS templating syntax provided by [ToolipsServables](https://github.com/ChifiSource/ToolipsServables.jl).
- **Modular** servers -- toolips applications are **regular Julia Modules**, making them easier to migrate and deploy.
- **Versatilility** -- toolips can be used for *all* use-cases, from full-stack web-development to simple endpoints.
- **Parallel Computing** -- *Declarative* process management provided by [parametric processes](https://github.com/ChifiSource/ParametricProcesses.jl).
- **Optionally Asynchronous** -- the `Toolips.start!` function provides several different modes to start the server in, including asynchronous, single-threaded, and multi-threaded.
- **Multi-Threaded** -- `Toolips` has support for high-level multi-threading through the `ParametricProcesses` `Module`
###### Toolips is able to create ...
- Endpoints
- File servers
- Interactive fullstack web applications (using the [ToolipSession](https://github.com/ChifiSource/ToolipsSession.jl) extension)
- Other HTTP/HTTPS servers (e.g. Proxy server, data-base cursor)
- UDP servers and services (e.g. Systems servers, DNS servers)
---
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
  - [quick start](#get-started)
    - [projects](#projects)
    - [routing](#routing)
    - [templating](#templating)
    - [extensions](#extensions)    
- (**read before**) [multi-threading](#multi-threading)
- [built with toolips](#built-with-toolips)
- [contributing](#contributing)
---
- **toolips requires [julia](https://julialang.org/). [julia installation instructions](https://julialang.org/downloads/platform/)**
# get started
`Toolips` is available in *three* different version flavors:
- Latest (main) -- The main working version of toolips.
- stable (#stable) -- Faster, more frequent updates than main; stable... but some new features are not fully implemented.
- and Unstable (#Unstable) -- Latest updates, packages could be temporarily broken in different ways from time to time.
```julia
using Pkg
# Latest 
Pkg.add("Toolips")
Pkg.add("Toolips", rev = "stable")
Pkg.add("Toolips", rev = "Unstable")
```
Alternatively, you can add the latest of each breaking version using an `x` revision.
```julia
using Pkg
Pkg.add("Toolips", rev = "0.1.x")
Pkg.add("Toolips", rev = "0.2.x")
Pkg.add("Toolips", rev = "0.3.x")
```
- toolips primarily targets **full-stack web-development**, but does so through extensions -- the intention being to use `Toolips` for both simple APIs and complex web-apps. This being considered, it is important to look into [toolips extensions](https://github.com/ChifiSource#toolips-extensions) to realize the full capabilities of this package! [ToolipsSession](https://github.com/ChifiSource/ToolipsSession.jl) provides `Toolips` with full-stack callbacks, for example.
- Check out [our toolips projects](#built-with-toolips) and [examples](#examples) for some examples of use-cases for the framework.
- Check out [creating-extensions](#creating-extensions) for more information on building extensions.
### documentation
- **REPL Documentation**: use `?(Toolips)` for a full list of exports.
- **Documentation Routes**: `Toolips.make_docroute` allows us to quickly make a docstring browser for **any** Julia Module. this includes `Toolips` and `ToolipsServables`. Simply add two new routes to a server and export them.
```julia
module DocServer
using Toolips

base_docs = Toolips.make_docroute(Base)
toolips_docs = Toolips.make_docroute(Toolips)
components_docs = Toolips.make_docroute(Toolips.Components)

export base_docs, toolips_docs, components_docs, start!
end

using Main.DocServer; start!(Main.DocServer)
```
The documentation will then be available at `/docs/(modname)` -- e.g. `/docs/toolipsservables` `/docs/toolips`.
- **Chifi Docs**: [toolips](https://chifidocs.com/toolips/Toolips) [ecosystem](https://chifidocs.com/toolips) [source](https://github.com/ChifiSource/ChifiDocs.jl)
- **Creator**: [OliveCreator](https://github.com/ChifiSource/OliveCreator.jl) will eventually offer interactive `Toolips` notebooks that help to explain and demonstrate concepts more effectively. This also *has yet to materialize*, but is in the pipeline and will be available some time after `ChifiDocs`.
## projects
In `Toolips`, projects are modules which **export** `Toolips` types. These special types are
- Any sub-type of `AbstractRoute`.
- Any sub-type of `Extension`.
- or a `Vector{<:AbstractRoute}`

Here is a simple " hello world" project. 
```julia
module HelloWorld
using Toolips
# hello world in toolips
home = route("/") do c::Connection
    write!(c, "hello world")
end

export start!, home
end
```
Here we use `route` to create a `Route{Connection}`, `home`. `home` is then exported, along with `start!` -- which is used to start our server.
```julia
# starts our server:
using HelloWorld; start!(HelloWorld)
# providing IP
using HelloWorld
start!(HelloWorld, "127.0.0.1":8000)
```
We can quickly create an entire `Toolips` project to start from by using `Toolips.new_app(::String)`. This will generate a project for the provided name. This will also generate a `dev.jl` file to automatically start your server:
```julia
using Toolips;  Toolips.new_app("MyServer")

cd("MyServer")
# starts your server, with `Revise` for development.
include("dev.jl")
```
When running from `dev.jl`, simply use `using MyServer` (or your server name) to reload new changes without need for a server restart.
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
respond!(c::AbstractConnection, args ...)
```
Routes can be exported as any `Vector{<:AbstractRoute}` or `AbstractRoute`. Only routes which are exported will be loaded, exporting names which do not actually exist in the project will break the server. The following functions/methods may be used to create new routes with base `Toolips`:
```julia
# creates a regular route
route(::Function, ::String) -> ::Route{<:AbstractConnection}
# creates a `multi-route`
route(::Route ...) -> ::MultiRoute
# mounts the file or directory in the value to the path in the key.
mount(::Pair{String, String}) -> ::Route{AbstractConnection}
```
```julia
module ServerSample
  route()
end
```
Files in `Toolips` can either be built manually with the `File` constructor or can be directly mounted to a route with `mount`. `mount` takes a `Vector{Pair{String, String}}`, and will return a `Route` or a `Vector{<:AbstractRoute}` -- depending on whether or not the provided path is a file or a directory. A directory will be recursively routed, creating a route for each file in each sub-directory below it...

When created manually, a `File` is able to be written with `write!`, like normal. This also gives us the ability to use `interpolate!`, which will interpolate `Components` by `name` or interpolate values by using `interpolate!` in place of `write!`.
```julia
interpolate!(c::AbstractConnection, f::File{<:Any}, components::AbstractComponent ...; args ...)
```
### templating
For more detailed websites, we might be building a more complicated response. `Toolips` provides the `Components` `Module`, [ToolipsServables](https://github.com/ChifiSource/ToolipsServables.jl). This `Module` includes the `File` type for easily serving parametrically files by path and `AbstractComponent` types for high-level parametric HTML and CSS templating. This templating framework also binds easily to `ToolipsSession`, the full-stack extension for `Toolips`. These components may then be written with `write!` or turned into a `String` with `string`. For more information, visit
- [ToolipsServables](https://github.com/ChifiSource/ToolipsServables.jl)
- [ToolipsSession](https://github.com/ChifiSource/ToolipsSession.jl) (adds more callback actions **and** full-stack callbacks)
### extensions
Extensions appear in `Toolips` in four main forms:
- `Connection` extensions,
- routing extensions,
- server extensions,
- start! extensions,
- and `Component` extensions.

Server extensions are loaded by exporting a constructed server extension within your `Module`. For example, the `ToolipsSession` extension provides full-stack interactivity.
```julia
module FullstackServer
using Toolips
using Toolips.Components
using ToolipsSession

home = route("/") do c::AbstractConnection
  new_button = button("popupbttn", text = "show popup")
style!(new_button, "position" => "absolute", "padding" => 5px, "left" => 30percent, "top" => 25percent)
  on(c, new_button, "click") do cm::ComponentModifier
    dialog = div("dialog", text = "hello world!")
    style!(dialog, "width" => 10percent, "left" => 45percent, "top" => 20percent, "position" => "absolute",
"padding" => 13px, "border" => 13px * " solid #1e1e1e")
    append!(cm, "mainbody", dialog)
    remove!(cm, new_button)
  end
  body("mainbody", children = [new_button])
end
 # construct extension:
SESSION = ToolipsSession.Session()

export start!, home, SESSION
end
```
There are many other ways to load and use extensions, and extensions do a lot more than extend the servers themselves.
## multi-threading
`Toolips` includes a distributed computing implementation built atop [ParametricProcesses](https://github.com/ChifiSource/ParametricProcesses.jl). This implementation of multi-threading allows us to serve each incoming connection on a different thread simply by providing the number of threads to utilize. Providing `threads` will simply add additional workers to our `ProcessManager`. These workers can then be used with `distribute!` and `assign!` or `assign_open!` -- all functions extended to work with the `Connection` from `ParametricProcesses`. By default, the number of `router_threads` will be `-2`, 3 responses from the base thread, and then however many threaded workers are provided. But of course, if we provided -- say `1:1` then we would only get the threads in the `ProcessManager`.
```julia
start!(mod::Module = Main, ip::IP4 = ip4_cli(Main.ARGS);
    threads::Int64 = 1, router_threads::UnitRange{Int64} = -2:threads)
```
```julia
module MySampleServer
using Toolips
home = route("/") do c::Connection
    write!(c, "hello")
end

export home, start!
end

using MySampleServer; start!(MySampleServer, router_threads
```
For the most part, this is straightforward -- but there are some things to be aware of...
- When a server is multi-threaded, its routes will be passed an `IOConnection` -- not a regular `Connection`. Routes will need to be annotated as an `AbstractConnection` (to work with single or multiple threads,) an `IOConnection` (to work with multi-threaded servers only,) or an `AbstractConnection` to work with multi-threaded servers.
- A multi-threaded server **must be a project**. The `Module` cannot be defined below `Main`, it must have its own `Project.toml` file. This is because your `Module` needs to be used across multiple threads from the same environment; `ParametricProcesses` will not be able to serialize your entire server and send it over to all of your threads. Instead, it is used via the environment. An environment compatible with this is of course set up for you when `new_app` is used.
- Finally, only certain objects will be serialized across threads. This means that we must be weary of what is in our `IOConnection.data`, or we might run into problems serializing across threads. This will primarily happen with functions. For example, consider the following `Session` callback:
```julia
module ThreadedSampleServer
using Toolips
using Toolips.Components
using ToolipsSession

session = Session(["/"]) # <- active route "/"

main = route("/") do c::Connection
    mainbody = body("mainbod")
    clickable = h3("sample", text = "hello")
    style!(h3, "transition" => 2seconds)
    push!(mainbody, clickable)
    on(c, clickable, "click") do cm::ComponentModifier
        alert!(cm, "goodbye!")
        style!(cm, "sample", "opacity" => 0percent)
    end
    write!(c, mainbody)
end

function load_alert(cm::ComponentModifier)
  
end

export session, main

end
```
This is not multi-threading compatible for two different reasons; our `c` is annotated to `Connection`, and our `Session` callback has a `Function` inside of it we will need to serialize. To  avoid this with `Function` callbacks, we simply need to define the `Function` in our `Module`, as it is already loaded to our threads.
```julia
module ThreadedSampleServer
using Toolips
using Toolips.Components
using ToolipsSession

session = Session(["/"]) # <- active route "/"

main = route("/") do c::Toolips.AbstractConnection
    mainbody = body("mainbod")
    clickable = h3("sample", text = "hello")
    style!(h3, "transition" => 2seconds)
    push!(mainbody, clickable)
    on(load_alert, c, clickable, "click")
    write!(c, mainbody)
end

function load_alert(cm::ComponentModifier)
  alert!(cm, "goodbye!")
  style!(cm, "sample", "opacity" => 0percent)
end

export session, main

end
```
From here, we simply provide the `threads` key-word argument to `start!`
```julia
julia> using ThreadedSampleServer; ThreadedSampleServer.start!(ThreadedSampleServer, "192.168.1.15":8000, threads = 4)
[ Info: Precompiling ThreadedSampleServer [307046d4-7f21-496b-9a80-f3bfb096e574]
🌷 toolips> loaded router type: Vector{Toolips.Route{Toolips.AbstractConnection}}
🌷 toolips> server listening at http://192.168.1.15:8000
      Active manifest files: 9 found
      Active artifact files: 3 found
      Active scratchspaces: 0 found
     Deleted no artifacts, repos, packages or scratchspaces
🌷 toolips> adding 4 threaded workers ...
🌷 toolips> spawned threaded workers: 2|3|4|5
[ Info: Listening on: 192.168.1.15:8000, thread id: 4
   pid                 process type                        name active
  –––– –––––––––––––––––––––––––––– ––––––––––––––––––––––––––– ––––––
  2080    ParametricProcesses.Async ThreadedSampleServer router   true
     2 ParametricProcesses.Threaded                           1  false
     3 ParametricProcesses.Threaded                           2  false
     4 ParametricProcesses.Threaded                           3  false
     5 ParametricProcesses.Threaded                           4  false
```
###### built with toolips
Because `Tooips` was built primarily to drive other [chifi](https://github.com/ChifiSource) software, `ChifiSource` has created a number of projects with `Toolips`. Here is a list of large projects we have created based on `Toolips`, along with their repository links. 
- [Olive](https://github.com/ChifiSource/Olive.jl) `Olive` is *the* reason that `Toolips` was created in the first place. `Olive` is a parametric extensible notebook editor for Julia. This is a great example to demonstrate a full-scale project.
  - Using: `Toolips`, [ToolipsServables](https://github.com/ChifiSource/ToolipsServables.jl), [ToolipsSession](https://github.com/ChifiSource/ToolipsSession.jl)
- [Gattino](https://github.com/ChifiSource/Gattino.jl) `Gattino` is `Toolips`-based, or rather `ToolipsServables`-based SVG data visualizations for Julia. A look into this project may give insight on how `ToolipsServables` and `Toolips` might be used without a `WebServer`.
  - Using: [ToolipsServables](https://github.com/ChifiSource/ToolipsServables.jl)
- [JLChat](https://github.com/emmaccode/JLChat.jl) `JLChat` is emma's `Toolips`-built chatroom demonstration. This example is great for demonstrating how to create a small application in `Toolips`, along with using [ToolipsSession](https://github.com/ChifiSource/ToolipsSession.jl) and its RPC feature.
  - Using: `Toolips`, [ToolipsServables](https://github.com/ChifiSource/ToolipsServables.jl), [ToolipsSession](https://github.com/ChifiSource/ToolipsSession.jl)
- [ChiProxy](https://github.com/ChifiSource/ChiProxy.jl) `ChiProxy` is a `Toolips`-bound proxy server for Julia. This proxy server demonstrates replacing the `Toolips` router by extending functions, allowing for routes to be routed by host rather than just `target` -- as well as a plethora of other special capabilities.
  - Using: `Toolips`
- [ChiNS](https://github.com/ChifiSource/ChiNS.jl) `ChiNS` is a Domain Name Server built with `Toolips`. This project provides a running example of `ToolipsUDP`, as well as a pretty nice demonstration of how to create a DNS server.
  - Using: [ToolipsUDP](https://github.com/ChifiSource/ToolipsUDP.jl)
- [EmsComputer](https://github.com/ChifiSource/EmsComputer.jl) `EmsComputer` is a full-stack web-app that emulates an operating system with several applications inside of a website. 
  - Using: `Toolips`, `ToolipsServables`, `ToolipsSession`

- **want your project here?**

If you would like to share your project as a `Toolips` example, please open an issue!
### contributing
`Toolips` is a *totally* awesome project, and with more contributors becomes even better even better. You may contribute to this project by...
- using Toolips in your own project 🌷
- creating extensions for the toolips ecosystem 💐
- forking this project [contributing guidelines](#guidelines)
- submitting issues
- contributing to other [chifi](https://github.com/ChifiSource) projects
- supporting chifi creators

I thank you for all of your help with our project, or just for considering contributing! I want to stress further that we are not picky -- allowing us all to express ourselves in different ways is part of the key methodology behind the entire [chifi](https://github.com/ChifiSource) ecosystem. Feel free to contribute, we would **love** to see your art! Issues marked with `good first issue` might be a great place to start!
#### guidelines
When submitting issues or pull-requests for `Toolips`, it is important to make sure of a few things. We are not super strict, but making sure of these few things will be helpful for maintainers!
1. You have replicated the issue on **Unstable**
2. The issue does not currently exist... or does not have a planned implementation different to your own. In these cases, please collaborate on the issue, express your idea and we will select the best choice.
3. **Pull Request TO UNSTABLE**
4. Be **specific** about your issue -- if you are experiencing multiple issues, open multiple issues. It is better to have a high quantity of issues that specifically describe things than a low quantity of issues that describe multiple things.
5. If you have a new issue, **open a new issue**. It is not best to comment your issue under an unrelated issue; even a case where you are experiencing that issue, if you want to mention **another issue**, open a **new issue**.
6. Questions are fine, but **not** questions answered inside of this `README`.
