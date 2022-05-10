using Pkg, Test
Pkg.activate("../../.")
include("../../src/Toolips.jl")
using Main: Toolips
Toolips.new_webapp()

@testset "Interface" begin

    @testset "text/html functions" begin
        @testset "html" begin
            htm = html("<h1>Test</h1>")
            @test typeof(htm) == Function

        end
    end

    @testset "indexing/iter" begin

    end

    @testset "style interface" begin

    end

    @testset "serving/routing" begin

    end

    @testset "requests" begin

    end

end # - Interface

@testset "Server" begin

    @testset "extensions" begin

    end

    @testset "core" begin

    end
end # - Server

@testset "App" begin

end # - App
