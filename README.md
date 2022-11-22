<div align = "center">
  <img src = https://github.com/ChifiSource/image_dump/blob/main/toolips/toolips.svg  width = 200 height = 300/img>
  
[![deps](https://juliahub.com/docs/Toolips/deps.svg)](https://juliahub.com/ui/Packages/Toolips/TrAr4?t=2)
[![version](https://juliahub.com/docs/Toolips/version.svg)](https://juliahub.com/ui/Packages/Toolips/TrAr4)
</br>

**|**    [toolips app](https://toolips.app/)   **|**  [documentation](https://doc.toolips.app) **|**   [examples](https://toolips.app/?page=examples)    **|**    [extensions](https://toolips.app/?page=extensions)    **|**

</div>

**Toolips.jl** is a **fast**, **asynchronous**, **low-memory**, **full-stack**, and **reactive** web-development framework **always** written in **pure** Julia. Here is Toolips.jl in a nutshell:
- **Fast and secure**. All routes are served through Julia, and anything that can be written must be written using a method that can only write very specific types.
- **HTTPS capable**, load balancer friendly. Can easily be deployed with SSL.
- **Extendable** servers, components, and methods, they are all extendable!
- **Modular** applications. Toolips applications are regular Julia modules.
- **Regular Julia** projects.
- **Declarative**, high-level syntax.
- Extremely **low memory usage**.
- **Asynchronous**. Run multiple functions at the same time as you serve to each incoming request.
- **Versatile**. Toolips.jl can be used for all scenarios, from full-stack web-development to APIs.
```julia
using Pkg; Pkg.add("Toolips")
```
```julia
julia> # Press ] to enter your Pkg REPL
julia> ]
pkg> add Toolips
```
##### projects
Here are some projects created using Toolips to both inspire and demonstrate!
<div align = "center">
  <img src = https://github.com/ChifiSource/image_dump/blob/main/toolips/olive/olivelogo.png  width = 200 /img>
  </div>
 
[Olive](https://github.com/ChifiSource/Olive.jl) is a mission to create a cell-based IDE, rather tthan cell-based notebook environment, inside of Julia using only Julia. This is somewhat similar to Pluto.jl, however is also a lot more feature-rich, extensible, and built differently.

<div align = "center">
  <img src = https://github.com/ChifiSource/image_dump/blob/main/toolips/toolipsapp.png  width = 200 /img>
  </div>

[ToolipsApp](https://github.com/ChifiSource/ToolipsApp.jl) was originally conceived in order to demonstrate the first version of toolips, and has continued to see development throughout the development of toolips itself.

<div align = "center">
  <img src = https://github.com/emmettgb/EmsComputer.jl/blob/main/public/images/animated.gif  width = 200 /img>
  </div>
  
[EmsComputer](https://github.com/emmettgb/EmsComputer.jl) is a blog and project website.
##### basics
Toolips is pretty easy to grasp, especially for those who have worked with similar web-frameworks in the past. If you prefer video, [here is a toolips tutorial playlist](https://www.youtube.com/playlist?list=PLCXbkShHt01s3kd2ZA62KoKhWBFfKXNTd). To get started, you may create a new project with `Toolips.new_app` or `Toolips.new_webapp`
```julia

```
- **Here are the different types you might encounter while using toolips**:
- Connections
- ServerExtensions
- Routes
- ToolipsServers
- Modifiers
- Servables

`Connections` are passed through our route functions. ServerExtensions are loaded by the server on startup and extend the capabilities of the framework. Routes are where the functions that write our pages go and tell the browser what to do with our client. `ToolipsServers` hold routes and extensions and create a server to serve said routes. While Connections facilitate incoming clients, client callbacks are left to `Modifiers`. These can be used for anything from changing properties of elements to changing incoming GET requests. Finally, there is the Servable; which is essentially anything with a `name` field which can be written to a `Connection` with `write!`. Let's write our first route! We will do so with the `route` method.
```julia
using Toolips

newroute = route("/") do c::Connection

end
```
We will use `write!` to write a `String` to our `Connection`:
```julia
using Toolips

newroute = route("/") do c::Connection
    write!(c, "Hello world!")
end
```
Next, we need to make our server. For this we just provide our route in a `Vector`:
```julia
using Toolips

newroute = route("/") do c::Connection
    write!(c, "Hello world!")
end

server = WebServer(routes = [newroute])
server.start()
```
It really is **that easy!**. As a final introduction, we will briefly review Components. Components can be constructed with basically whatever `String` Pairs or key-word arguments we want. These are HTML properties given to our elements. That being said, Component functions are simply HTML element names.
```julia
using Toolips

newroute = route("/") do c::Connection
    mydiv = div("mydiv")
    myb = b("label", text = "hello world!")
    push!(mydiv, myb)
    write!(c, mydiv)
end

server = WebServer(routes = [newroute])
server.start()
```
