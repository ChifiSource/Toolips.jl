module Toolips
#==
Toolips.jl, a module created for light-weight interaction with Javascript via
bursts of HTML and Javascript working in tandem. There might be entirely new
intentions for this design, and dramatic changes. There are numerous features
coming to spruce up this code base to better facilitate things like
authentication.
~ TODO LIST ~ If you want to help out, you can try implementing the following:
- TODO Secret keys.
- TODO Authentication.
- TODO Parsing envvariables and CLI from main in the generated file (this file,
create_serverdeps(name::String)
- TODO Logging
- TODO Production vs dev environments
- TODO Front-end call-back tie-ins. Not sure how this is going to be implemented
but I am sure it will not be too bad! (That's a joke.)
==#
using Sockets, HTTP, Pkg
include("interface/components.jl")
# Server
export Route, ServerTemplate, stop!
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
    rm(src * "/$name.jl")
    touch(src * "/$name.jl")
    open(src * "/$name.jl", "w") do io
        write(io, """
# Welcome to your new Toolips server!\n
using Main.Toolips\n
\n
PUBLIC = "../public"\n
IP = "127.0.0.1"\n
PORT = 8000\n
\n
function main()\n
        # Essentials\n
    routes = make_routes()\n
    server_template = ServerTemplate(IP, PORT, routes)\n
        # Fun stuff (examples !, you should probably delete these.)\n
    delayed = Route("/delay", fn(delay))\n
    suicide = Route("/suicide", fn(suicide_fn))\n
    arguments = Route("/args", fn(args))\n
    server_template.add(delayed)\n
    server_template.add(suicide)\n
    server_template.add(arguments)\n
    global TLSERVER = server_template.start()\n
    return(TLSERVER)\n
end\n
\n
# Routes\n
function make_routes()\n
        # Pages\n
    four04 = html("<h1>404, Page not found!</h1>")\n
    index = html("<h1>Hello world!</h1></br><p>Not so exciting, <b>is it?</b>
     well, it is a work in progress :p.</p>")\n
        # Routes\n
    routes = []\n
    homeroute = Route("/", index)\n
    four04route = Route("404", four04)\n
    push!(routes, homeroute)\n
    push!(routes, four04route)\n
    routes\n
end\n
\n
# Routes can either route to a function or a page. Using the html() method,\n
#   we have avoided making a page. This can be done for anything that is a
func.\n
#   This includes fn, as we can see when these methods are referenced in
 main().\n
suicide_fn = http -> stop!(TLSERVER)\n
args = http -> string(getargs(http))\n
function delay(http::Any)\n
        for character in "Hello World!"\n
            write(http, string(character))\n
            sleep(1)\n
        end\n
end\n

        """)
    end
end
function new_webapp(name::String = "ToolipsApp")
    create_serverdeps(name)
end

export new_webapp, new_webapi
# --

end
