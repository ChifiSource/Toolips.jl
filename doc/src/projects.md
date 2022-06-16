# projects
Projects in Toolips are easy to start. You can either choose to create a project
directory structure, or optionally; you can create an entire server inside of
your REPL!
## creating a project
Toolips projects are created using the new_app and new_webapp methods
respectively. new_app will create a simple project and new_webapp will create a
full-stack web-app.
```@docs
Toolips.new_app
```

```@docs
Toolips.new_webapp
```
## a repl crash course

## project walkthrough
Toolips projects  work just like any other Julia project. There is no random
silliness going on here -- no need to source anything with Bash, merely call
Julia. After running new_app or new_webapp, you should be greeted with a new
directory named after your project name.

```julia
using Pkg; Pkg.add("Toolips")
using Toolips
Toolips.new_webapp("ToolipsTutorial")
```

```bash
cd ToolipsTutorial
~/dev/ToolipsTutorial

tree .
[.]
├── dev.jl
├── prod.jl
├── Manifest.toml
├── Project.toml
├── [logs]
│   └── log.txt
├── [public]
└── [src]
    └── ToolipsTutorial.jl

3 directories, 6 files

```

The directory structure is that of a typical Julia project -- albeit with a few
extra little files and folders. The source code that creates our websites is
contained within the **src** directory. A Logger comes loaded as a default
extension, although we could remove it if we really wanted to, or likewise --
create our own Logger and load it as an extension -- which is pretty much what
makes toolips great. The Logger by default will log to the **logs** directory.
The **public** directory contains any files we want to be served automatically
by the Files ServerExtension. This directory will be missing if you decide to
utilize the new_app method. The other two things that are not Julia defaults are
the files **dev.jl** and **prod.jl**. These are environment files, they store
environmental variables to be sourced above the module in Main. Let's take a
look:
### dev.jl

```julia
#==
dev.jl is an environment file. This file loads and starts servers, and
defines environmental variables, setting the scope a lexical step higher
with modularity.
==#
using Pkg; Pkg.activate(".")
using Toolips
using Revise
using ToolipsModifier
using ToolipsTutorial

IP = "127.0.0.1"
PORT = 8000
#==
Extension description
:logger -> Logs messages into both a file folder and the terminal.
:public -> Routes the files from the public directory.
:mod -> ToolipsModifier; allows us to make Servables reactive. See ?(on)
==#
extensions = Dict(:logger => Logger(), :public => Files("public"),
:mod => Modifier())
ToolipsTutorialServer = ToolipsTutorial.start(IP, PORT, extensions)
```

Firstly, dev.jl activates the project environment with Pkg.
Next, we load all of the dependencies. The first one is the most obvious; you
are reading the documentation for it. The second one is Revise. Revise.jl allows
us to update our modules **while** they are loaded into main. This just makes
rerouting easier, as you can modify the text file, save it, update the routes,
and then your new website is up with no downtime. No worries, I will be showing
how this is done in no time. First though, we will also consider the extensions
section. I have been kind enough to leave a little note here,

```
Extension description
:logger -> Logs messages into both a file folder and the terminal.
:public -> Routes the files from the public directory.
:mod -> ToolipsModifier; allows us to make Servables reactive. See ?(on)
```

This describes what each extension does. Of course, all the effort it takes
to add more is merely adding them via Pkg and adding them to this dictionary.
We are going to include this file in order to start the server. We would include
**prod.jl** if we wanted to start a production server, which is a very similar
file in content, jut missing the Revise.jl First, let us take a look at the source file.
### src.jl

```julia
module ToolipsTutorial
using Toolips
using ToolipsModifier

function home(c::Connection)
    write!(c, p("helloworld", text = "hello world!"))
end

fourofour = route("404") do c
    write!(c, p("404message", text = "404, not found!"))
end

"""
start()
"""
function start(IP::String = "127.0.0.1", PORT::Integer = 8000,
    extensions::Dict = Dict(:logger => Logger()))
    rs = routes(route("/", home), fourofour)
    server = ServerTemplate(IP, PORT, rs, extensions = extensions)
    server.start()
end

end # - module
```
##### start
This file will likely look a bit different in the future, with a bit more
documentation, and maybe a more illustrious default project, but do not fret --
the names will all be the same and the file similar enough! The **start**
function is probably the most important here. This function constructs our
Routes, makes a ServerTemplate and then runs ServerTemplate.start(), returning a
WebServer. Back up in **dev.jl** we see that this is aptly named
"projectnameServer"

```julia
extensions = Dict(:logger => Logger(), :public => Files("public"),
:mod => Modifier())
ToolipsTutorialServer = ToolipsTutorial.start(IP, PORT, extensions)
```
##### home
```julia
function home(c::Connection)
    write!(c, p("helloworld", text = "hello world!"))
end
```
The home function is a function built to be routed to. We can tell this is the ]
case because it takes a Connection as its only argument. This is one method of
making a route. Inside the function, c is written to using the write! method.
Keep this method in mind, as we will be using it a lot; it is the primary
output for toolips. There is also a component constructed via the p() method.
This just creates a p. The id of the p will be its name, "helloworld", and the
text; which modifies the inner text of a given element. The other special key
is :children, which is of type Vector{Servable}. This will be any children to
write to the stream inside of this tag. Children are usually added via the
**push!(::Servable, ::Servable)** method.
##### fourofour
```julia
fourofour = route("404") do c
    write!(c, p("404message", text = "404, not found!"))
end
```
The fourofour is made as a global variable of type Route, rather than as a
function.
### command line interface
We have a few different options when it comes to starting the server. These
options of course come with all toolips servers. The first of which is to load
a server as a module. Most modular servers will use the Module.start() method,
just like our project ToolipsTutorial does above. This is ideal if
- You want to try someone else's Toolips Application.
- The module you are working with is an Application.
- The module you are working with is an extension; then the module is used
inside of another project, just to be clear.

```julia
using Pkg
Pkg.add(url = "https://github.com/ChifiSource/ToolipsApp.jl")
using ToolipsApp
ToolipsAppServer = ToolipsApp.start()
```

Alternatively, we can always git clone the repository, or with a project we
started serve our project. This is ideal if
- You want to put the server into production.
- You want to develop the project. \
We can start the server in this way by utilizing the environment files discussed
before. This is done either via the include("") method in the REPL, or via the
-L parameter in Bash.

```julia
pwd()
"~/dev/ToolipsTutorial"
include("dev.jl")
#==
[ Info: Precompiling ToolipsTutorial [9dd80660-3bd1-4940-be1d-3a5faeb076a0]
[2022-06-14T18:50:45.970]: Toolips Server starting on port 8000
[2022-06-14T18:50:46.521]: Successfully started server on port 8000
[2022-06-14T18:50:46.966]: You may visit it now at http://127.0.0.1:8000
==#
```

```bash
julia -L dev.jl
[ Info: Precompiling ToolipsTutorial [9dd80660-3bd1-4940-be1d-3a5faeb076a0]
[2022-06-14T18:50:45.970]: Toolips Server starting on port 8000
[2022-06-14T18:50:46.521]: Successfully started server on port 8000
[2022-06-14T18:50:46.966]: You may visit it now at http://127.0.0.1:8000
```

Wow now you can see the exact date and time at which I did that, cool. Anyway,
with our new toolips server running, we can introspect its routes:
```julia
ToolipsTutorialServer.routes
Dict{String, Function} with 3 entries:
  "404"              => #1
  "/"                => home
  "/modifier/linker" => document_linker
  julia> typeof(ToolipsTutorialServer)
  WebServer
```
The /modifier/linker route is provided to us by our Modifier extension. We also
see that the type of this new variable is WebServer. Viewing the server in
the web-browser yields us a small p with a label "hello world!". We can also
route the server using the route! method, or access extensions and routes by
indexing. This is the same way we would use the route() function as is done in
our source file. We access Connection extensions by indexing a Connection with
a Symbol. We can also access and change routes by indexing with a String. This
same methodology is also applied to the WebServer, so we can index it in the
same way, as well.
```julia
route!(ToolipsTutorialServer, "/cupcakes") do c::Connection
    write!(c, "emmy LOVES CUPCAAAKES")
    c[:logger].log(1, "hello")
end

[2022-06-14T19:29:32.180]: hello
"emmy LOVES CUPCAAAKES"
```
Let's develop our emmy loves cupcakes app a bit further, by instead making it
our project route function. Don't close up the REPL, though! we will still be
using it!
### making applications
Lets return to our project source file,
```julia
function home(c::Connection)
    redclass = Style("redtxt", color = "red")
    blueclass = Style("bluetxt", color = "lightblue")
    heading = h("cupkakes", 1, text = "Cupcakes")
    write!(c, p("clicktod",
    text = "click to make the heading change color; double click to send to red."))
    write!(c, components(redclass, blueclass))
    on(c, heading, "click") do cm::ComponentModifier
        style!(cm, heading, blueclass)
    end
    on(c, heading, "dblclick") do cm::ComponentModifier
        style!(cm, heading, redclass)
    end
    write!(c, heading)
end
```
Here I added an on() method call. This method call allows us to modify
components on events. In this example, clicking will make the heading invisible.
It is incredibly easy, but incredibly possible! The last step is going to be
running the route! method on our WebServer.
```julia
route!(ToolipsTutorialServer, "/", ToolipsTutorial.home)
```
Now, we can finally visit; and click to change the color! Hopefully this little
overview got you both familiar with Toolips projects, as well as reactivity!
## deploying a toolips server
