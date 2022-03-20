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
    cp("interface/default_main.jl", src)
    mv("src/default_main.jl", "src/$name.jl")
end
function new_webapp(name::String = "ToolipsApp")
    create_serverdeps(name)
end

export new_webapp, new_webapi
# --

end
