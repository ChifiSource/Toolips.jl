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
using Sockets, HTTP
include("interface/components.jl")
# Server
export Route, ServerTemplate, stop!
# Components
export Page, html, html_file, getargs, fn

function create_serverdeps(name::String)
    Pkg.generate(name)
    src = name * "/src"
    public = name * "/public"
    logs = name * "/logs"
    mkdir(public)
    mkdir(logs)
    touch(name * "/start.sh")
    # TODO Parse CLI's/Env vars
    open(src * "main.jl", "w") do f
        write(f, """
        # Welcome to your new Toolips server!\n
        # In these early versions of Toolips, prior to registration, we could
        # are not using Pkgspec, so you will need to source the environment on
        # your own.
        using Toolips\n\n
        # TODO Parse CLI's/Env vars\n
        PUBLIC = "../public" # (This cannot be accessed via routes.)\n
        IP = "127.0.0.1"\n
        PORT = 8000\n
        function main()\n
            routes = make_routes()\n
            server_template = ServerTemplate(IP, PORT, routes)\n
            # Add the suicide route to the server template.\n
            suicidePage = Route("/suicide", fn(suicide_route))\n
            global TLSERVER = server_template.start()\n
        end\n\n
        # Routes\n
        function make_roots()\n
            # Pages\n
            four04 = html("<h1>404, Page not found!</h1>")\n
            index = html_file("../public/index.html")\n
            routes = []\n
            homeroute = Route("/", index)\n
            four04route = Route("404", four04)\n
            push!(routes, homeroot)\n
            push!(four04route) = Route("404", four04)\n
            routes\n
        end
        function suicide_route()
            stop!(TLSERVER)
        end
        """)
    end

end
function new_webapp(name::String = "ToolipsApp")
    create_serverdeps(name)
end

export new_webapp, new_webapi
# --

end
