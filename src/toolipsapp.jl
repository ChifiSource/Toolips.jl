# toolips default server :)

toolips_app = route("/") do c::Connection
    write!(c, "new toolips app incoming ...")
end

toolips_404 = route("404") do c::Connection

end