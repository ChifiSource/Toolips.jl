# toolips default server :)

toolips_app = route("/") do c::Connection
    write!(c, "hello world!")
end

toolips_404 = route("404") do c::Connection

end