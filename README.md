<div align = "center">
  <img src = https://github.com/ChifiSource/Toolips.jl/blob/Unstable/assets/logo.svg  width = 200 height = 300/img>
  <h6>v. 0.1.0</h6>
  
[![deps](https://juliahub.com/docs/Toolips/deps.svg)](https://juliahub.com/ui/Packages/Toolips/TrAr4?t=2)
[![version](https://juliahub.com/docs/Toolips/version.svg)](https://juliahub.com/ui/Packages/Toolips/TrAr4)
[![pkgeval](https://juliahub.com/docs/Toolips/pkgeval.svg)](https://juliahub.com/ui/Packages/Toolips/TrAr4)
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
  <details class="details-overlay">
  <summary class="btn"><h2>Using Toolips</h2></summary>
<div>
  
## Links
##### Documentation
  - [Documentation](https://doc.toolips.app/)
##### Examples
  - [ToolipsApp.jl](https://github.com/emmettgb/ToolipsApp.jl) - Our site - https://toolips.app/
  - [EmsComputer.jl](https://github.com/emmettgb/EmsComputer.jl) A random website - https://ems.computer/
  - [Pasta.jl](https://github.com/emmettgb/Pasta.jl) - A full-stack text-editor
  - [Prrty.jl](https://github.com/ChifiSource/Prrty.jl) - Dashboard generator
##### Curated Extensions
- [ToolipsSession](https://github.com/ChifiSource/ToolipsSession.jl) - ServerExtension, Servables, Enables fullstack interactivity.
- [ToolipsRemote](https://github.com/ChifiSource/ToolipsRemote.jl) - ServerExtension, Allows remote access via HTTP from a Julia terminal. **work in progress**
- [ToolipsBase64](https://github.com/ChifiSource/ToolipsBase64.jl) - Servables, Allows for the changing of images by Base64 encoding.
- [ToolipsUploader](https://github.com/ChifiSource/ToolipsUploader.jl) - ServerExtension, Servables, Allows the uploading of files client-side to be written server-side. **work in progress**
- [ToolipsDefaults](https://github.com/ChifiSource/ToolipsDefaults.jl) - Servables, Default styles, input components, and more for Toolips. **work in progress**
## Basics
  Toolips.jl is not like other web-development frameworks you might have used in the past. Toolips can be used as both a micro-framework and a full-stack framework, as well as everything in between. Routing with toolips is done using the route() method, which will return a route. We then put our route into a ServerTemplate, which can be started using the ServerTemplate.start() function.
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
  Alternatively, we can also create a preset Toolips.jl file-structure using the **new_app** and **new_webapp** methods respectively. new_app is used to create simple APIs, whereas new_webapp will add the dependencies and Server Extensions necessary for full-stack web-development.
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
  </div>
  </details>
