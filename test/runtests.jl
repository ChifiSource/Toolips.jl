using Test
using Toolips


@testset "Toolips" verbose = true begin

@testset "identifiers, reference generation" begin
    ip1 = IP4("127.0.0.1", 8000)
    @test typeof(ip1) <: Toolips.Identifier
    ip2 = "127.0.0.1":8000
    @test string(ip1) == string(ip2)
    ip3 = "google.com":0
    @test ~(contains(string(ip3), ":"))
    @test length(gen_ref(5)) == 5
end

module ToolipsTestServer
using Toolips
using Test

wd = @__DIR__
@info wd

main = route("/") do c::Connection

end

mounted_dir = mount("/files/" => wd)
mounted_file = mount("/example" => wd * "/runtests.jl")

export main, mounted_dir, mounted_file, multrte, default_404
end

using ToolipsTestServer

@testset "toolips servers" verbose = true begin
    @testset "server creation" begin

    end
end

end # Toolips tests.