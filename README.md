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
###### basics
Toolips is pretty easy to grasp, especially for those who have worked with similar web-frameworks in the past. Here are the different types you might encounter while using toolips:
- Connections
- ServerExtensions
- Routes
- ToolipsServers
- Modifiers

`Connections` 
###### extensions
