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
- **Declarative** and **composable** files, html, Javascript, *and* CSS templating syntax provided by [ToolipsServables](https://github.com/ChifiSource/ToolipsServables.jl).
- **Modular** servers -- toolips applications are **regular Julia Modules**.
- **Versatilility** -- toolips can be used for *all* use-cases, from full-stack web-development to simple endpoints.
- **Parallel Computing** -- *Declarative* process management provided by [parametric processes](https://github.com/ChifiSource/ParametricProcesses.jl).
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
    - [projects](#projects)
      - [routing](#routing)
      - [extensions](#extensions)
    - [responses](#responses)
      - [files](#files)
      - [components](#components)
      - [templating](#templating)
- [creating extensions](#creating-extensions)
  - [connection extensions](#connection-extensions)
  - [routing extensions](#routing-extensions)
  - [server extensions](#server-extensions)
  - [component extensions](#component-extensions)
- [multi-threading](#multi-threading)
- [built with toolips](#built-with-toolips)
- [contributing](#contributing)
---
- **toolips requires [julia](https://julialang.org/). [julia installation instructions](https://julialang.org/downloads/platform/)**
#### get started
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
###### documentation
*Awesome documentation website coming soon*
- For now, you can use `?Toolips` to see a full list of exports.
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
## projects
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
# providing IP
using HelloWorld
start!(HelloWorld, "127.0.0.1":8000)
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
### extensions
Extensions appear in `Toolips` in four main forms:
- `Connection` extensions,
- routing extensions,
- server extensions,
- and `Component` extensions.

`Connection` extensions allow us to utilize `MultiRoute` with new multiple dispatch `Connection` configurations. Routing extensions allow us to change the functionality of the `Toolips` router in different instances. Server extensions allow us to add autoloaded data, or perform actions alongside before our routes whenever a `Connection` is served. Finally, `Component` extensions give us more composable `Component` types to work with, and more high-level web-development capabilities.

`Connection` extensions are typically used through `MultiRoute`. This is done by providing multiple routes to `route`, which will call different routes depending on the incoming client `Connection`. For example, the `MobileConnection` is the quintessential `Connection` extension provided by `Toolips`.
```julia
module Sample
using Toolips

desktop = route("/") do c::Connection
    write!(c, "this page is only served to mobile users")
end

mob = route("/") do c::MobileConnection
    write!(c, "this page is only served to mobile users")
end

# make multiroute
mult_rt = route(desktop, mob)

export mult_rt, start!
end
```
- [creating connection extensions](#connection-extensions)

## responses
Like most web-development frameworks, creating websites or APIs with `Toolips` primarily revolves around creating a response. In the case of an API, this is actually pretty simple. `write!` will convert any provided type to a `String` and then write it to the incoming `Connection` stream. 
```julia
module Multiply
using Toolips

home = route("/") do c::Connection
    args = get_args(c)
    arg_keys = keys(args)
    if ~(:y in arg_keys) || ~(:x in arg_keys)
        write!(c, "you have not provided `x` or `y`.")
    end
    write!(c, string(x * y))
end
```
- Note the use of `get_args`, `get_post` *might* also be important for APIs.
```julia
module Crystals
using Toolips
import Base: getindex, in

mutable struct APIClient
    ip::String
    requests::Int64
    max::Int64
    name::String
end

getindex(apc::Vector{APIClient}, ip::String) = begin
    found_client = findfirst(c::APIClient -> c.ip == ip, apc)
    if isnothing(found_client)
        throw(KeyError(ip))
    end
    apc[found_client]
end
end

in(ip::String, apc::Vector{APIClient}) = begin
  found_client = findfirst(c::APIClient -> c.ip == ip, apc)
  ~(isnothing(found_client))
end

clients = Vector{APIClient}()

verify = route("/") do c::AbstractConnection
  nm = get_post(c)
  allnames = [client.name for client in clients]
  if length(nm) > 3 && replace(nm, " " => "") != "" && ~(nm in allnames)
     write!(c, "you are verified, $nm ! Have fun with the crystal API!"
     push!(clients, APIClient(get_ip(c), 1, 50, nm))
  end
end

crystals_api = route("/crystals") do c::AbstractConnection
    args = get_args(c)
    arg_keys = keys(args)
    if ~(get_ip(c) in clients)
        write!(c, "You are not verified! Please POST your name to our home-page to identify yourself.")
    end
end

export crystals_api
end
```
For more detailed websites, we might be building a more complicated response. `Toolips` provides the `Components` `Module`, [ToolipsServables](https://github.com/ChifiSource/ToolipsServables.jl). This `Module` includes the `File` type for easily serving parametrically files by path and `AbstractComponent` types for high-level parametric HTML and CSS templating.
#### files
Files in `Toolips` can either be built manually with the `File` constructor or can be directly mounted to a route with `mount`. `mount` takes a `Vector{Pair{String, String}}`, and will return a `Route` or a `Vector{<:AbstractRoute}` -- depending on whether or not the provided path is a file or a directory. A directory will be recursively routed, creating a route for each file in each sub-directory below it...
```julia
```
When created manually, a `File` is able to be written with `write!`, like normal. This also gives us the ability to use `interpolate!`, which will interpolate `Components` by `name` or interpolate values by using `interpolate!` in place of `write!`.
```julia
function interpolate!(c::AbstractConnection, f::File{<:Any}, components::AbstractComponent ...; args ...)
```
For example, using this `Method` to interpolate HTML with components and values...
```html
<body>
<div>
<h2>hello client</h2>
<a>your ip address is $ip</a>
<h4>would you like to name yourself?</h4>
$namebutton
</div>
```
```julia

```
```julia
```
This example interpolates HTML -- but is the *catchall*, or top-level function (binded to `File{<:Any}` -- meaning you could also write different methods to change behavior depending on file type.
```julia
function interpolate!(c::AbstractConnection, f::File{:md}, components::AbstractComponent ...; args ...)
    raw::String = string(f)
    interp_positions = findall("```", raw)
    ...
end
```
#### components
```julia
```
This package also allows us to create callbacks for these components...
```julia
```
And [ToolipsSession](https://github.com/ChifiSource/ToolipsSession.jl) expands on this by providing server-side callbacks and some pretty extreme fullstack capabilities.
```julia
```
#### templating
As demonstrated in this `README` thus far, `Toolips` has a diverse set of a capabilities when it comes to templating. Templating in `Toolips` is done by constructing and composing components into a `body` and then writing it to the `Connection`, or interpolating a file via the `interpolate!` function.
## creating extensions
###### connection extensions
A `Connection` extension creates a new `Connection` which can be used with multi-route, or otherwise with a new router. The running example of this inside `Toolips` is the `MobileConnection`.
```julia
mutable struct MobileConnection{T} <: AbstractConnection
    stream::Any
    data::Dict{Symbol, Any}
    routes::Vector{AbstractRoute}
    MobileConnection(stream::Any, data::Dict{Symbol, <:Any}, routes::Vector{<:AbstractRoute}) = begin
        new{typeof(stream)}(stream, data, routes)
    end
end
```
The `MobileConnection` is created whenever an incoming client is on mobile. This is determined by `get_client_system`. Two functions are used for this; `convert` and `convert!`. `convert` is called on the `Connection` to see if the `Connection` should convert. If it should convert, then `convert!` is called.
```julia
function convert(c::AbstractConnection, routes::Routes, into::Type{MobileConnection})
    get_client_system(c)[2]::Bool
end

function convert!(c::AbstractConnection, routes::Routes, into::Type{MobileConnection})
    MobileConnection(c.stream, c.data, routes)::MobileConnection{typeof(c.stream)}
end

# for IO Connection specifically...
function convert!(c::IOConnection, routes::Routes, into::Type{MobileConnection})
    stream = Dict{Symbol, String}(:stream => c.stream, :args => get_args(c), :post => get_post(c), 
    :ip => get_ip(c), :method => get_method(c), :target => get_target(c), :host => get_host(c))
    MobileConnection(stream, c.data, routes)::MobileConnection{Dict{Symbol, String}}
end
```
Note that the `MobileConnection` is actually a `MobileConnection{<:Any}`. We build a data dictionary in order to turn the `IOConnection` into a `MobileConnection`, whereas in the case of the `Connection` we are provided the standard `HTTP.Stream` directly. This simple system facilitates both types. Beyond this, you are free to extend other `Connection` functions to enhance your interface if they are not compatible with your current `Connection`. Not implementing this will mean that the `Connection` will not work with multi-threading.
```julia
get_ip(c::MobileConnection{Dict{Symbol, String}}) = c.stream[:ip]
get_method(c::MobileConnection{Dict{Symbol, String}}) = c.stream[:method]
get_args(c::MobileConnection{Dict{Symbol, String}}) = c.stream[:args]
get_target(c::MobileConnection{Dict{Symbol, String}}) = c.stream[:target]
get_host(c::MobileConnection{Dict{Symbol, String}}) = c.stream[:host]
write!(c::MobileConnection{Dict{Symbol, String}}, a::Any ...) = c.stream[:stream] = c.stream[:stream] * join(string(obj) for obj in a)
```
Let's implement a `PostConnection` in order to demonstrate this:
```julia
module PostConnections
using Toolips
import Toolips: AbstractConnection, convert, convert!
mutable struct PostConnection{T} <: AbstractConnection
    stream::Any
    data::Dict{Symbol, Any}
    routes::Vector{AbstractRoute}
    PostConnection(stream::Any, data::Dict{Symbol, <:Any}, routes::Vector{<:AbstractRoute}) = begin
        new{typeof(stream)}(stream, data, routes)
    end
end

function convert(c::AbstractConnection, routes::Routes, into::Type{PostConnection})
    get_method(c) == "POST"
end

function convert!(c::AbstractConnection, routes::Routes, into::Type{PostConnection})
    PostConnection(c.stream, c.data, routes)::PostConnection{typeof(c.stream)}
end

function convert!(c::IOConnection, routes::Routes, into::Type{PostConnection})
    stream = Dict{Symbol, String}(:stream => c.stream, :args => get_args(c), :post => get_post(c), 
    :ip => get_ip(c), :method => get_method(c), :target => get_target(c), :host => get_host(c))
    PostConnection(stream, c.data, routes)::PostConnection{Dict{Symbol, String}}
end
```
Now let's use it:
```julia
module PostSample
using Toolips
using Main.PostConnections
using Toolips.Components

# regular `GET`
home_main = route("/") do c::Connection
    write!(c, h2("main", text = "you landed!", align = "center"))
end

home_post = route("/") do c::PostConnection
    write!(c, "welcome to the API :)")
end

home = route(home_main, home_post)

export home_main, home_post, home
end
```
###### routing extensions
Another type of extension that can be created for toolips is the routing extension. Routing extensions are created by extending the `route!` function. This function may be extended by adding new methods for `Route` types (`<:AbstractRoute`), `Connection` types (`<:AbstractConnection`), a `Vector` with `<:AbstractRoute` as its type parameter, or extension types (`<:AbstractExtension`).
- on an incoming `Connection`, `route!` is initially called on each extension using `route!(c, ::AbstractExtension)` (only if the binding exists) before the main routing process begins -- giving extensions the first oppurtunity to `write!` to the `Connection`.
- `route!` is called twice during the routing process, first on the `Connection` and the `Vector{<:AbstractRoute}` that holds the routes. This is where the startup printout of `Toolips` comes to relevance:
```julia
julia> Toolips.start!(Sample)
🌷 toolips> loaded router type: Vector{Toolips.Route{Connection}}
🌷 toolips> server listening at http://127.0.0.1:8000

```
- `route!` is also called **again** on a `MultiRoute` if a `MultiRoute` is being used. In the binding for the quintessential `MultiRoute` type, for example, the incoming `Connection` checks for conversion into any of the dispatched functions.

All of these considered, there are a lot of ways to extend the routing of `Toolips`.
###### server extensions
###### component extensions

## multi-threading
`Toolips` includes a distributed computing implementation built atop [ParametricProcesses](https://github.com/ChifiSource/ParametricProcesses.jl). This implementation of multi-threading allows us to serve each incoming connection on a different thread simply by providing the number of threads to utilize.
```julia
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
- [ChiNS](#https://github.com/ChifiSource/ChiNS.jl) `ChiNS` is a Domain Name Server built with `Toolips`. This project provides a running example of `ToolipsUDP`, as well as a pretty nice demonstration of how to create a DNS server.
  - Using: [ToolipsUDP](https://github.com/ChifiSource/ToolipsUDP.jl)
### contributing
