using Test
using Toolips

module ToolipsTestServer
using Toolips
using Test

wd = @__DIR__
@info wd

main = route("/") do c::Connection
    @testset "server-side response" begin
        @test getargs(c)[:message] == "hello!"
        write!(c, "hello, client")
    end
end

mounted_dir = mount("/files/" => wd)
mounted_file = mount("/example" => wd * "/runtests.jl")

@testset "routes" begin
    @test length(mounted_dir) == < 3
    @test typeof(mounted_dir) <: AbstractVector
end
export main, mounted_dir, mounted_file, multrte, default_404
end

@testset "Toolips" verbose = true begin

@testset "identifiers, reference generation" begin
    ip1 = IP4("127.0.0.1", 8000)
    @test typeof(ip1) <: Toolips.Identifier
    ip2 = "127.0.0.1":8000
    @test string(ip1) == string(ip2)
    ip3 = "google.com":0
    @test ~(contains(string(ip3), ":"))
    @test length(Toolips.gen_ref(5)) == 5
end

using Main.ToolipsTestServer

@testset "client-side request" verbose = true begin
    @testset "server creation" begin

    end
end

end # Toolips tests.