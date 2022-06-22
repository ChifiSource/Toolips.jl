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
After a server is running, Toolips has an interactive level that allows you to
introspect and modify server attributes via the WebServer type. If you start a
project with new web-app or new-app, then your WebServer type on your new server
will automatically become (project-name)Server. For example, a ToolipsTutorial
WebServer would be named ToolipsTutorialServer by default. Let's create a new
project and get started with the toolips command-line interface.
```julia
using Toolips
Toolips.new_app("MyApp")

julia> Toolips.new_app("MyApp")
  Generating  project MyApp:
    MyApp/Project.toml
    MyApp/src/MyApp.jl
....
```
Now we will cd into our new project directory, and activate dev.jl.
```julia
shell> cd MyApp
/home/emmac/dev/toolips/MyApp
julia> include("dev.jl")
  Activating project at `~/dev/toolips/MyApp`
[2022:06:19:15:37]: 🌷 toolips> Toolips Server starting on port 8000
[2022:06:19:15:37]: 🌷 toolips> Successfully started server on port 8000
[2022:06:19:15:37]: 🌷 toolips> You may visit it now at http://127.0.0.1:8000
```
Activating this will give us the new variable MyAppServer. To start,
we can view our routes and extensions by using the methods under those
same names:
```julia
?(routes(ws::WebServer))

julia> routes(MyAppServer)
Dict{String, Function} with 2 entries:
  "404" => #1
  "/"   => home

  julia> Toolips.extensions(MyAppServer)
 Dict{Symbol, Logger} with 1 entry:
   :Logger => Logger(:connection, "/home/emmac/dev/toolips/MyApp/logs/log.txt", Dict{Any, Crayons.Crayon}(4=>\e[31;1m, 2=>\e[93m, :message_crayon=>\e[94;1m, 3=>\e[33;1m, 1=>\e[96m, :time_crayon=>
```
We can also reroute the server's routes with the route! method:
```
route!(MyAppServer, "/") do c::Connection
    c[:Logger].log("Wow!")
end
```
We can index extensions with a Symbol, and index routes with a String.
```
c["/"]
    home
c[:Logger]
    Logger( .....  )
```
Lastly, we can kill the server using kill!
```
kill!(MyAppServer)
```
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
overview got you both familiar with Toolips projects, as well as reactivity. If
you would like to try this project out for yourself,
[here is a link to the source.](https://github.com/ChifiSource/ToolipTutorial.jl)
## deploying a toolips server
Toolips projects can very easily be deployed with SSL. This overview
will demonstrate an example of deploying a non-containerized
Toolips.jl project with NGINX. This is because this is likely the
most interpretable overview to carry into deploying any project. We
will be deploying toolips app with SSL on my server.
##### tech stack
- Julia **1.7.2**
- Toolips.jl **0.1.0**
- NGINX **nginx/1.18.0 (Ubuntu)**
- Ubuntu **22.04 LTS (GNU/Linux 5.15.0-37-generic x86_64)**
- Supervisord **4.2.1**
##### proxy pass
The first thing we are going to need to do is create our server
configuration for nginx. This will involve listening on port 80 and
    then forwarding any incoming connections to the port of our server.
This also assumes that your domain or IP has already been routed to your DNS and under normal circumstances your domain or IP would be servable. We will go ahead and ssh into our server:
```bash
ssh emmac@xx.xxx.xxx
```
If you do not have nginx, we are going to need it.
```bash
sudo apt install nginx
```
Now we need to make our nginx server configuration. This is done by creating a new configuration file at the path `/etc/nginx/conf.d`
```bash
cd /etc/nginx/conf.d
nano toolipsapp.conf
```
Now we will add a new server, and create a proxy pass.
```
server {
    server_name toolips.app;

    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```
Next, reload your configuration
```bash
nginx -s reload
```
I proxy pass this to http://127.0.0.1:8001. Now lets get our project files setup. We have the choice with toolips to use the project as both a module and a file path. In most cases, when deploying you are probably going to want to have access to the local files of a toolips application, so we are going to do the latter. In order to do so, the first step is to clone the module to our machine with git or scp it over. I like to put mine into the directory `/var/www` , but this is a matter of personal preference. Now that we have our project in its folder at /var/www, we can create a supervisor configuration. Supervisor allows us to run the application without actually being behind the terminal. However, it is also a pretty good idea to go ahead and test the server before starting your supervisor. So cd to your directory and include dev.jl. Try and visit your domain, and if it is not serving then you know something is likely wrong with either your DNS or nginx configuration. When you are ready to configure your supervisor, the configuration files are in `/etc/supervisor/conf.d`
```bash
cd /etc/supervisor/conf.d
nano
```
You'll want to use the -L argument to start Julia with, this will automatically load the file and begin a new Julia session.
```
[program:toolipsapp]
directory=/var/www/ToolipsApp.jl
command=/opt/julia-1.7.3/bin/julia -L prod.jl
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
```
Finally, we need to reload supervisor.
```bash
service supervisor reload
```
And if all is well, your server should be up and ready to go!
