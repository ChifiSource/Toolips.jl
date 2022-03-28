using Pkg, Test
Pkg.activate("../../.")
include("../../src/Toolips.jl")
using Main.Toolips

function test()

    new_webapp("TESTAPP")
end

test()
