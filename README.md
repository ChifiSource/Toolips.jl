<div align = "center">
  <img src = https://github.com/ChifiSource/Toolips.jl/blob/Unstable/assets/logo.svg  width = 200 height = 300/img>
</div>

**Toolips.jl** is a **fast**, **asynchronous**, **low-memory**, **full-stack**, and **reactive** web-development framework written in Julia. Here is Toolips.jl in a nutshell:
- Fast and secure.
- HTTPS capable, load balancer friendly.
- Extendable servers, components, and modules.
- Modular server environments.
- Server introspection and live server maintenance/development.
- Declarative, high-level syntax.
- An ever-expanding library of extensions.
- Easy animation and interaction tools.
- Extremely low memory usage.
- Asynchronisoty.
- Front-end development.
- 100% Julia websites.
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
   Resolving package versions...
    Updating `~/dev/dev/Project.toml`
  [a47e2ad8] + Toolips v0.0.7 `https://github.com/ChifiSource/Toolips.jl.git#Unstable`
    Updating `~/dev/dev/Manifest.toml`
  [a8cc5b0e] + Crayons v4.1.1
  [cd3eb016] + HTTP v0.9.17
  ....


julia> using Toolips
  
  julia> Toolips.new_webapp("MyApp")
  Generating  project MyApp:
    MyApp/Project.toml
    MyApp/src/MyApp.jl
  Activating project at `~/dev/MyApp`
    Updating git-repo `https://github.com/ChifiSource/Toolips.jl.git`
   Resolving package versions...
    Updating `~/dev/MyApp/Project.toml`
  [a47e2ad8] + Toolips v0.0.6 `https://github.com/ChifiSource/Toolips.jl.git#main`
    Updating `~/dev/MyApp/Manifest.toml`
  [a8cc5b0e] + Crayons v4.1.1
  [cd3eb016] + HTTP v0.9.17
  [83e8ac13] + IniFile v0.5.1
  [739be429] + MbedTLS v1.0.3
  [a47e2ad8] + Toolips v0.0.6 `https://github.com/ChifiSource/Toolips.jl.git#main`
  [5c2747f8] + URIs v1.3.0
  [0dad84c5] + ArgTools
  [56f22d72] + Artifacts
  [2a0f44e3] + Base64
  [ade2ca70] + Dates
  [f43a241f] + Downloads
  [b77e0a4c] + InteractiveUtils
  [b27032c2] + LibCURL
  [76f85450] + LibGit2
  [8f399da3] + Libdl
  [56ddb016] + Logging
  [d6f4376e] + Markdown
  [ca575930] + NetworkOptions
  [44cfe95a] + Pkg
  [de0858da] + Printf
  [3fa0cd96] + REPL
  [9a3f8284] + Random
  [ea8e919c] + SHA
  [9e88b42a] + Serialization
  [6462fe0b] + Sockets
  [fa267f1f] + TOML
  [a4e569a6] + Tar
  [cf7118a7] + UUIDs
  [4ec0a83e] + Unicode
  [deac9b47] + LibCURL_jll
  [29816b5a] + LibSSH2_jll
  [c8ffd9c3] + MbedTLS_jll
  [14a3606d] + MozillaCACerts_jll
  [83775a58] + Zlib_jll
  [8e850ede] + nghttp2_jll
  [3f19e933] + p7zip_jll
Precompiling project...
  1 dependency successfully precompiled in 1 seconds (9 already precompiled)
"/home/emmac/dev/MyApp/public"
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
