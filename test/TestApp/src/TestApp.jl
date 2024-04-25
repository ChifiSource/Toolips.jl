module TestApp
using Toolips
# using Toolips.Components

# extensions
logger = Toolips.Logger()

mainf(c::AbstractConnection) = begin
    if ~(:clients in c)
        c[:clients] = 0
    end
    c[:clients] += 1
    client_number = string(c[:clients])
    log(logger, "served client " * client_number)
    write!(c, "hello client #" * client_number)
end
main = route(mainf, "/")
# make sure to export!
export main, default_404, logger
end # - module TestApp <3