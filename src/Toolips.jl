module Toolips
#==
Toolips.jl, a module created for light-weight interaction with Javascript via
bursts of HTML and Javascript working in tandem. There might be entirely new
intentions for this design, and dramatic changes. There are numerous features
coming to spruce up this code base to better facilitate things like
authentication.
~ TODO LIST ~ If you want to help out, you can try implementing the following:
=========================
- TODO Incoming user information would be nice.
- TODO Secret keys.
- TODO Authentication. (UUID's would be nice)
- TODO Parsing envvariables and CLI from main in the generated file (this file,
create_serverdeps(name::String)
- TODO improve default project files a tad.
- TODO Load environment in default files
- TODO Setup the Pkg environment with the given loaded files
- TODO Add data-bases (via ODdb.jl, soon after a 0.1.0 release of it)
- TODO Simple internal calls for get() and post requests.
- TODO PUBLIC ROUTES STILL BROKEN
- RIP
- TODO Implement some kind of classes structure for CSS styling to be easier.
      Might end up making some CSS Julia equivalent types.
- TODO Add more properties for servables
==#
using Crayons
using Sockets, HTTP, Pkg
include("interface/servables.jl")
# Core Server
export Route, ServerTemplate, Logger, stop!
# Components
export html, html_file, file, css, css_file, js, js_file, fn
export Button, Form, TextArea, TextBox, RadioSet, Slider
export Canvas
export List, UnorderedList, A, DropDown
# Structure servables (frontend)
export Header, Page
# High-level api
export route, serve, anim!, style!, set!
# Style Servables


# Methods
export getargs, getarg, getpost, write_file, lists

function create_serverdeps(name::String)
    Pkg.generate(name)
    dir = pwd() * "/"
    src = dir * name * "/src"
    public = dir * name * "/public"
    logs = dir * name * "/logs"
    mkdir(public)
    mkdir(logs)
    touch(name * "/dev.jl")
    touch(name * "/prod.jl")
    touch(logs * "/log.txt")
    rm(src * "/$name.jl")
    touch(src * "/$name.jl")
    open(src * "/$name.jl", "w") do io
        write(io, """
# Welcome to your new Toolips server!
using Main.Toolips\n
function main()
        # Essentials
    global LOGGER = Logger()
    routes = make_routes()
    server_template = ServerTemplate(IP, PORT, routes)
    global TLSERVER = server_template.start()
    return(TLSERVER)
end
\n
# Routes
function make_routes()
        # Pages
    four04 = html("<h1>404, Page not found!</h1>")
    index = html("<h1>Hello world!</h1>")
        # Routes
    routes = []
    homeroute = Route("/", index)
    four04route = Route("404", four04)
    push!(routes, homeroute)
    push!(routes, four04route)
    routes
end
\n
main()
        """)
    end
    open(name * "/dev.jl", "w") do io
        write(io, """
        IP = "127.0.0.1"
        PORT = 8000
        PUBLIC = "../public"
        include("src/$name.jl")
        """)
    end
    open(name * "/prod.jl", "w") do io
        write(io, """
        IP = "127.0.0.1"
        PORT = 8000
        PUBLIC = "../public"
        include("src/$name.jl")
        """)
    end
end
function new_webapp(name::String = "ToolipsApp")
    create_serverdeps(name)
end

export new_webapp
# --

end
