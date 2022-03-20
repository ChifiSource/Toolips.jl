# Welcome to your new Toolips server!
using Main.Toolips

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

# Routes
function make_routes()
        # Pages
        four04 = html("<h1>404, Page not found!</h1>")
        index = html("<h1>Hello world!</h1></br><p>Not so exciting, <b>is it?</b> well, it is a work in progress :p.</p>")
        # Routes
        routes = []
        homeroute = Route("/", index)
        four04route = Route("404", four04)
        push!(routes, homeroute)
        push!(routes, four04route)
        routes
end

# Routes can either route to a function or a page. Using the html() method,
#   we have avoided making a page. This can be done for anything that is a func.
#   This includes fn, as we can see when these methods are referenced in main().
suicide_fn = http -> stop!(TLSERVER)
args = http -> string(getargs(http))
function delay(http::Any)
        for character in "Hello World!"
            write(http, string(character))
            sleep(1)
        end
end
