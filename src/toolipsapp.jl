# toolips default server :)

toolips_app = route("/") do c::Connection
    write!(c, "new toolips app incoming ...")
end

default_404 = route("404") do c::Connection
    write!(c, "404")
end