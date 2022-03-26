module Toolips
#==
Toolips.jl, a module created for light-weight interaction with Javascript via
bursts of HTML and Javascript working in tandem. There might be entirely new
intentions for this design, and dramatic changes. There are numerous features
coming to spruce up this code base to better facilitate things like
authentication.
~ TODO LIST ~ If you want to help out, you can try implementing the following:
=========================
- TODO Secret keys.
- TODO Authentication.
- TODO Parsing envvariables and CLI from main in the generated file (this file,
create_serverdeps(name::String)
- TODO Production vs dev environments
- TODO Front-end call-back tie-ins. Not sure how this is going to be implemented
==#
using Crayons
using Sockets, HTTP, Pkg
include("interface/servables.jl")
# Server
export Route, ServerTemplate, Logger, stop!
# Components
export Page, html, html_file, getargs, fn

function create_serverdeps(name::String)
    Pkg.generate(name)
    dir = pwd() * "/"
    src = dir * name * "/src"
    public = dir * name * "/public"
    logs = dir * name * "/logs"
    mkdir(public)
    mkdir(logs)
    touch(name * "/start.sh")
    touch(logs * "/log.txt")
    rm(src * "/$name.jl")
    touch(src * "/$name.jl")
    open(src * "/$name.jl", "w") do io
        write(io, """
# Welcome to your new Toolips server!
using Main.Toolips\n
PUBLIC = "../public"
IP = "127.0.0.1"
PORT = 8000
function main()
        # Essentials
    routes = make_routes()
    server_template = ServerTemplate(IP, PORT, routes)
        # Fun stuff (examples !, you should probably delete these.)
    delayed = Route("/delay", fn(delay))
    suicide = Route("/suicide", fn(suicide_fn))
    arguments = Route("/args", fn(args))
    server_template.add(delayed)
    server_template.add(suicide)
    server_template.add(arguments)
    global TLSERVER = server_template.start()
    return(TLSERVER)
end
\n
# Routes
function make_routes()
        # Pages
    four04 = html("<h1>404, Page not found!</h1>")
    index = html("<h1>Hello world!</h1></br><p>Not so exciting, <b>is it?</b>
     well, it is a work in progress :p.</p>")
        # Routes
    routes = []
    homeroute = Route("/", index)
    four04route = Route("404", four04)
    push!(routes, homeroute)
    push!(routes, four04route)
    routes
end
\n
suicide_fn = http -> stop!(TLSERVER)

args = http -> string(getargs(http))

function delay(http::Any)
        for character in "Hello World!"
            write(http, string(character))
            sleep(1)
        end
end\n
main()
        """)
    end
end
function new_webapp(name::String = "ToolipsApp")
    create_serverdeps(name)
end

export new_webapp
# --

end
