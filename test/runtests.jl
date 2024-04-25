using Test
using Toolips
using Toolips.Pkg

wd = @__DIR__
module ToolipsTestServer
using Toolips
using Toolips.Components: div
using Main.Test

wd = Main.wd
logger = Toolips.Logger()
main = route("/") do c::AbstractConnection
    method = get_method(c)
    @testset "server-side response ($method)" begin
        @test (method == "GET" || method == "POST")
        if method == "GET"
            @test typeof(get_ip(c)) == String
            @test get_args(c)[:message] == "hello"
            @test contains(get_host(c), "127.0.0.1")
            write!(c, "hello back!")
        elseif method == "POST"
            pmsg = get_post(c)
            @test pmsg == "i am client"
            write!(c, pmsg)
        end
    end
end

mounted_dir = mount("/files/" => wd)
mounted_file = mount("/example" => wd * "/runtests.jl")

export main, mounted_dir, mounted_file, default_404, logger
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
Pkg.activate(wd * "/TestApp")
using TestApp
@testset "toolips servers" verbose = true begin
    @testset "server creation" begin
        @test length(Main.ToolipsTestServer.mounted_dir) > 1
        @test typeof(Main.ToolipsTestServer.mounted_file) <: AbstractRoute
        pm = start!(ToolipsTestServer, "127.0.0.1":8005)
        @test length(pm.workers) == 1
    end
    getret = Toolips.get("http://127.0.0.1:8005/?message=hello")
    ret = Toolips.post("127.0.0.1":8005, "i am client")
    @testset "client-side request" begin
        @test getret == "hello back!"
        @test ret == "i am client"
    end
    @testset "kill! deadcheck" begin
        kill!(Main.ToolipsTestServer)
        deadcheck = false
        try
            getret = Toolips.get("http://127.0.0.1:8005/?message=hello")
        catch
            deadcheck = true
        end
        @test deadcheck
    end
    threads = Threads.nthreads()
    @info "starting multi-threading tests ..."
    if threads > 1
        @testset "multithreading" verbose = true begin
            @testset "multi-threaded start" begin
                pm = start!(Main.TestApp, threads = threads - 1)
                @test length(pm.workers) == threads
            end
            @testset "multi-request" begin
                served = false
                try
                    [get("127.0.0.1":8000) for x in 1:20]
                served = true
                catch

                end
                @test served
            end
            @testset "kill! deadcheck" begin
                kill!(TestApp)
                deadcheck = false
                try
                    getret = Toolips.post("127.0.0.1":8000, "hello :)")
                catch
                    deadcheck = true
                end
                @test deadcheck
            end
        end
    else
        @info "julia started with 1 thread, skipping multi-threading tests..."
    end
end


end # Toolips tests.