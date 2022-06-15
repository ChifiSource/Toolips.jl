<div align = "center">
  <img src = https://github.com/ChifiSource/Toolips.jl/blob/Unstable/assets/logo.svg  width = 200 height = 300/img>
</div>


###### Note: 0.0.9 is not a full release of Toolips.jl, and stable supported usage should begin with version 0.1.0

**Toolips.jl** is a **fast**, **asynchronous**, **low-memory**, **full-stack**, and **reactive** web-development framework **always** written in **pure** Julia. Here is Toolips.jl in a nutshell:
- **Fast and secure**. All routes are served through Julia, and anything that can be written must be written using a method that can only write very specific types.
- **HTTPS capable**, load balancer friendly. Can easily be deployed with SSL.
- **Extendable** servers, components, and methods, they are all extendable!
- **Modular** applications. Toolips applications are modular!
- **Regular Julia** projects.
- **Declarative**, high-level syntax.
- Extremely **low memory usage**.
- **Asynchronous**. Run multiple functions at the same time as you serve to each incoming request.
- **Versatile**. Toolips.jl can be used for all scenarios, from full-stack web-development to APIs.
```julia
using Pkg; Pkg.add(url = "https://github.com/ChifiSource/Toolips.jl")
```
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
  - [ToolipsApp.jl](https://github.com/emmettgb/ToolipsApp.jl) \
  https://toolips.app/
  - [EmsComputer.jl](https://github.com/emmettgb/EmsComputer.jl) \
  https://ems.computer/
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
  [emmac@ems-computer dev]$ julia
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.7.2 (2022-02-06)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

(@v1.7) pkg> activate dev
  Activating new project at `~/dev/dev`

(dev) pkg> add https://github.com/ChifiSource/Toolips.jl.git#Unstable
    Updating git-repo `https://github.com/ChifiSource/Toolips.jl.git`
    Updating registry at `~/.julia/registries/General.toml`
          .................
  ....
julia> using Toolips
  
  julia> Toolips.new_webapp("MyApp")
  Generating  project MyApp:
    MyApp/Project.toml
    MyApp/src/MyApp.jl
  Activating project at `~/dev/MyApp`
      ............
  ```
  This will create a project directory structure like this:
  ```julia
  shell> cd MyApp
/home/emmac/dev/MyApp

shell> tree .
.
├── dev.jl
├── logs
│   └── log.txt
├── Manifest.toml
├── prod.jl
├── Project.toml
├── public
└── src
    └── MyApp.jl

3 directories, 6 files

shell> 

  ```
Here is our resulting website in a file!
  ```julia
  function main(routes::Vector{Route})
    server = ServerTemplate(IP, PORT, routes, extensions = extensions)
    server.start()
end


hello_world = route("/") do c
    write!(c, p("hello", text = "hello world!"))
end
fourofour = route("404", p("404", text = "404, not found!"))
rs = routes(hello_world, fourofour)
main(rs)
  ```
  We can include "dev.jl" to start our development server!
## Crash Course
There are different portions of Toolips.jl that we need to be aware of in order to better understand Toolips. Firstly, there is the interface portion, which is split into two parts; Servables and Interface. The other portion of Toolips is the Server portion, which is also split into two parse: Extensions, and the Core Server. The most declarative of these is of course the Interface.
  #### Servables
  Servables are types that always have two fields: a Function called f, and a Dict{Any, Any} called properties. Servables are passed through either the route() or the write!() function in order to be written to a connection.
  ```julia
  s = divider("mydivider")
  typeof(s)
  
  Component
  
  typeof(s) <: Toolips.Servable
         
  true
  ```
  There are too many names here to reference, but it should be known that all servables can be indexed with with anything in order to set settings at whim. These are just references, anything goes, a place to store data inside of a servable. Then the servable simply has the f(c::Connection) function which uses the connection type. Servables are also bound to many connection functions, such as write!, style!, and more.
```julia
image = img("image", src = "/images/example.png")
subtitle = h("subtitle", 4, text = "This is an example")
route("/") do c::Connection
      write!(c, image)
      write!(c, subtitle)
               # We can also group servables:
     cs = components(image, subtitle)
               write!(c, cs)
end
```
  #### Interface
               The interface is where many methods for working with Servables, Connections, and Servers are defined.
  #### Core
  #### ServerExtensions
  </div>
  </details>
  
  
  <details class="details-overlay">
  <summary class="btn"><h2>Curated Extensions</h2></summary>
<div><img src = https://github.com/ChifiSource/image_dump/blob/main/toolips/Curated/logo.png></img>

  
- [ToolipsRemote](https://github.com/ChifiSource/ToolipsRemote.jl) - ServerExtension
- [ToolipsModifier](https://github.com/ChifiSource/ToolipsModifier.jl) - ServerExtension, Servables
- [ToolipsCanvas]() Servables
  </div>
  </details>
