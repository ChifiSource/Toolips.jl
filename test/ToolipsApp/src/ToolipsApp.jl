function main(routes::Vector{Route})
    server = ServerTemplate(IP, PORT, routes, extensions = [logger])
    TLSERVER = server.start()
    return(TLSERVER)
end


                   #      vvv ?(Connection)
hello_world = route("/") do c
    write!(c, P("hello", text = "hello world!"))
end

fourofour = route("404", P("404", text = "404, not found!"))
rs = routes(hello_world, fourofour)
main(rs)
        