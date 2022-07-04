```@raw html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Poppins&family=Roboto+Mono:wght@100&family=Rubik:wght@500&display=swap" rel="stylesheet">

<style>
body {background-color: #FDF8FF !important;}
header {background-color: #FDF8FF !important}
h1 {
  font-family: 'Poppins', sans-serif !important;
  font-family: 'Roboto Mono', monospace !important;
  font-family: 'Rubik', sans-serif !important;}

  h2 {
    font-family: 'Poppins', sans-serif !important;
    font-family: 'Roboto Mono', monospace !important;
    font-family: 'Rubik', sans-serif !important;}
    h4 { color: #03045e !important;
      font-family: 'Poppins', sans-serif !important;
      font-family: 'Roboto Mono', monospace !important;
      font-family: 'Rubik', sans-serif !important;}
article {
  border-radius: 30px !important;
  border-color: lightblue !important;
}
pre {
  border-radius: 10px !important;
  border-color: #FFE5B4 !important;
}
p {font-family: 'Poppins', sans-serif;
font-family: 'Roboto Mono', monospace;
font-family: 'Rubik', sans-serif; color: #565656;}
</style>
```
# projects
Toolips projects are normal Julia modules. The projects can often be added with
Pkg, and do not require any extra bootstrap in order to be started.
Toolips projects can be setup either using the `new_app` or the `new_webapp` method.
If you really want to, you can also avoid these two entirely and create a project
from scratch. `new_webapp` will create a new full-stack toolips app.  `new_app`
creates a minimalist application, ideal for simple APIs.
- `new_webapp` generates the directory `public`
- `new_webapp` loads the [Files](extensions/toolips_extensions/index.html#Files)
- `new_webapp` adds [ToolipsSession](extensions/toolips_session/index.html)
- `new_webapp` adds [ToolipsDefaults](extensions/toolips_defaults/index.html)
```@docs
Toolips.new_app
Toolips.new_webapp
```
These two methods both take one positional argument, and that is the name of your
project. These project names should follow the Julia convention for Modules, which
is capitalizing the first letter of each word in the name.
```julia
using Toolips
# Don't do this...
Toolips.new_webapp("myapp")
# Do this!
Toolips.new_webapp("MyApp")
```
## directory structure
Once a project has been created, the directory structure should look like that
of a typical Julia project. Let's go ahead and generate a project in order to
take a look.
```julia
using Toolips

Toolips.new_webapp("MyWebApp")
Toolips.new_app("MyApp")
```
We will start by taking a look at `MyApp`. I will use another module, [PrintFileTree](https://github.com/NHDaly/PrintFileTree.jl)
to take a look at the files within this new directory.
```julia
using PrintFileTree

cd("MyApp")
PrintFileTree.printfiletree(".")
```
```bash
.
├── Manifest.toml
├── Project.toml
├── dev.jl
├── logs
│   └── log.txt
├── prod.jl
└── src
    └── MyApp.jl

2 directories, 6 files
```
The `Project.toml` and `Manifest.toml` files are both typical of Julian `Pkg`
projects. These two files hold all of the dependency information for your project.
`dev.jl` and `prod.jl` define environmental variables for both a
production and development environment respectively.
## environments
We can access our environment by either using `Pkg.activate(".")` or by activating
from the Pkg REPL. The REPL can be entered from the Julia REPL by pressing `]`.
Once activated, we can add new dependencies with `add`, and remove dependencies with
`rm`.
```julia
using Pkg

Pkg.activate(".")
Pkg.add("ToolipsSession")
```
Our environment files, `dev.jl` and `prod.jl`, contain the information that our
server needs to be started. This includes extensions, our IP, our port, and a few
dependencies. Do **NOT** put secrets into here! Never hardcode your secrets, these
should be defined inside of Bash somewhere and brought into Julia in some other way.
```julia
#==
dev.jl is an environment file. This file loads and starts servers, and
defines environmental variables, setting the scope a lexical step higher
with modularity.
==#
using Pkg; Pkg.activate(".")
using Toolips
using Revise
using MyApp

IP = "127.0.0.1"
PORT = 8000
extensions = [Logger()]
MyAppServer = MyApp.start(IP, PORT, extensions)
```
The `dev.jl` file only differs from the `prod.jl` file in one way by default, and
that is [Revise](https://timholy.github.io/Revise.jl/stable/). Revise.jl is an awesome
project by [timholy](https://github.com/timholy) that allows us to modify modules
while they are loaded into `Main`. This is useful because it allows us to develop
websites with **zero downtime** by rerouting to new code via the command-line-interface.
The file completes by calling `MyApp.start`, a function that creates a [ServerTemplate]()
for us and starts it to return a [WebServer]().
## starting projects
In order to start our project, we have three options.
- **1:** We can include `dev.jl` with the `include` method.
- **2:** We can run `julia -L` on `dev.jl` from Bash/CMD.
- **3:** We can import our module with `using` and run the `MyApp.start` method manually.
##### 1: including dev.jl
Including `dev.jl` is probably the most straight-forward approach to starting
a toolips server.
```julia
include("dev.jl")
 Activating project at `~/dev/toolips/examples/MyApp`
[ Info: Precompiling MyApp [6e1095f5-2a16-48a3-8439-38092e9c2ced]
[2022:07:02:02:17]: 🌷 toolips> Toolips Server starting on port 8000
[2022:07:02:02:17]: 🌷 toolips> Successfully started server on port 8000
[2022:07:02:02:17]: 🌷 toolips> You may visit it now at http://127.0.0.1:8000
```
##### 2: julia -L dev.jl
Using `julia -L` is ideal if you want to deploy the project into production, as
this is a command that can be used by a supervisor to start your server. However,
it is not going to break anything to use this all the time, it makes no difference.
```julia
[emmac ems-computer MyApp]$ julia -L dev.jl
  Activating project at `~/dev/toolips/examples/MyApp`
[2022:07:02:02:19]: 🌷 toolips> Toolips Server starting on port 8000
[2022:07:02:02:19]: 🌷 toolips> Successfully started server on port 8000
[2022:07:02:02:19]: 🌷 toolips> You may visit it now at http://127.0.0.1:8000
```
##### 3: calling start
Calling `start` is ideal if you either intend for an end-user to import your
toolips project as a module, or you are calling the project from an entirely different
project above it.
```julia
include("src/MyApp.jl")
using Main.MyApp
using Toolips
MyApp.start("127.0.0.1", 8000, [Logger()])
[2022:07:02:02:22]: 🌷 toolips> Toolips Server starting on port 8000
[2022:07:02:02:22]: 🌷 toolips> Successfully started server on port 8000
[2022:07:02:02:22]: 🌷 toolips> You may visit it now at http://127.0.0.1:8000
```
## project source
The project source files are contained within the `src` directory. The default
project file looks like this:
```julia
module MyApp
using Toolips


"""
home(c::Connection) -> _
--------------------
The home function is served as a route inside of your server by default. To
    change this, view the start method below.
"""
function home(c::Connection)
    write!(c, p("helloworld", text = "hello world!"))
end

fourofour = route("404") do c
    write!(c, p("404message", text = "404, not found!"))
end

"""
start(IP::String, PORT::Integer, extensions::Vector{Any}) -> ::Toolips.WebServer
--------------------
The start function comprises routes into a Vector{Route} and then constructs
    a ServerTemplate before starting and returning the WebServer.
"""
function start(IP::String = "127.0.0.1", PORT::Integer = 8000,
    extensions::Vector = [Logger()])
    rs = routes(route("/", home), fourofour)
    server = ServerTemplate(IP, PORT, rs, extensions = extensions)
    server.start()
end

end # - module
```
In this file, we are shown the two different techniques which can be used to create
a `Route`. The first of these is the example of `home`, where a function is written, and
later passed into the `route` method. This method takes a string and a function, in either
position, and can also be called with the `do` syntax such as in the example of `fourofour`.
The `start` method is the final piece of the puzzle, which takes an IP, port, and Vector{ServerExtension}. The first line of the function calls the [routes]() method to comprise
our two routes into a `Vector{Route}`. The second line constructs a [ServerTemplate]()
using our IP, port, routes, and server-extensions as the key-word argument `extensions`.
Finally, server.start() is called, returning a [WebServer]()
## project directories
Along with our new app, the `logs` directory was created. As you might expect, this
directory contains a log of server output. The log output is provided by the [Logger](extensions/toolips_extensions/index.html#Logger) extension. One difference that our `MyWebApp` project
contains is the `public` directory, which is used by the [Files](extensions/toolips_extensions/index.html#Files) extension.
```julia
cd("MyWebApp")
using PrintFileTree

PrintFileTree.printfiletree(".")
.
├── Manifest.toml
├── Project.toml
├── dev.jl
├── logs
│   └── log.txt
├── prod.jl
├── public
└── src
    └── MyWebApp.jl

```
All of the files inside of this directory will be served into the server at the route corresponding
with their directory, where `/` is `public`.
