using Test
using Toolips


module ToolipsTestServer
using Toolips
using Toolips.Components: div
using Test

wd = @__DIR__
@info wd
logger = Toolips.Logger()
main = route("/") do c::Connection
    @testset "server-side response" begin
        method = get_method(c)
        @test (method == "GET" || method == "POST")
        if method == "GET"
            @test typeof(get_ip(c)) == String
            @test get_args(c)[:message] == "hello"
            @test contains(get_host(c), "127.0.0.1")
            proxy_pass!(c, "http://127.0.0.1:8000/second")
        elseif method == "POST"
            pmsg = get_post(c)
            write!(c, pmsg)
        end
    end
end
second = route("/second") do c::Connection
    write!(c, div("sample", text = "hello back!"))
end

mounted_dir = mount("/files/" => wd)
mounted_file = mount("/example" => wd * "/runtests.jl")

export main, mounted_dir, mounted_file, multrte, default_404, logger
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

@testset "toolips servers" verbose = true begin
    @testset "server creation" begin
        @test length(Main.ToolipsTestServer.mounted_dir) > 1
        @test typeof(Main.ToolipsTestServer.mounted_file) <: AbstractRoute
        pm = start!(ToolipsTestServer, "127.0.0.1":8005)
        @test length(pm.workers) == 1
    end
    @testset "client-side request" begin

    end
end

end # Toolips tests.