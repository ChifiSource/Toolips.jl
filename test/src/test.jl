using Pkg, Test
include("../../src/Toolips.jl")
using Main.Toolips

@testset "Interface" begin
    @testset "Components" begin
        c = Component("myc", "div")
        @test typeof(c) == Main.Toolips.Component
        @test c.name == "myc"
        @test length(c.properties[:children]) == 0
        c = img("myimg")
        @test c.tag == "img"
        c = link("mylnk")
        @test c.tag == "link"
        @test c.name == "mylnk"
        c = meta("met", text = "Hello world!")
        @test c[:text] == "Hello world!"
        @test c.tag == "meta"
        c = input("inp")
        @test c.name == "inp"
        @test c.tag == "input"
        c = a("mya")
        @test c.tag == "a"
        @test c.name == "mya"
        c = p("world", text = "hello")
        @test c.tag == "p"
        @test c[:text] == "hello"
        c = h("myh", 2)
        @test c.tag == "h2"
        c = h("myh", 1)
        @test c.tag == "h1"
        c = ul("myul")
        @test c.tag == "ul"
        c = li("myli")
        @test c.tag == "li"
        c = divider("mydiv", align = "center")
        @test c[:align] == "center"
        @test c.tag == "div"
        @test typeof(br()) == Component
        c = i("el")
        @test c.tag == "i"
        c = title()
        @test typeof(c) == Component
        @test c.tag == "title"
        c = span("myspan")
        @test c.name == "myspan"
        @test c.tag == "span"
        c = iframe()
        @test c.tag == "iframe"
        c = svg()
        @test c.tag == "svg"
        c = element()
        @test c.tag == "element"
        c = label()
        @test c.tag == "label"
        c = script("myscript")
        @test c.tag == "script"
        c = nav()
        @test c.tag == "nav"
        @test c.name == ""
        c = button()
        @test c.tag == "button"
        c = form()
        @test c.tag == "form"
        c = Component("myname", "mytag", Dict{Any, Any}(:text => "hi"))
        @test c.name == "myname"
        @test c.tag == "mytag"
        @test c[:text] == "hi"
    end
    @testset "StyleComponents" begin
        a = Animation("myanim")
        s = Style("mystyle")
        @test typeof(a) == Main.Toolips.Animation
        a[:from] = "opacity" => "50%"
        @test a.keyframes["from"] == "opacity: 50%; "
        animate!(s, a)
        @test s["animation-name"] == a.name
        delete_keyframe!(a, :from)
        @test ~("from" in keys(a.keyframes))
    end
    @testset "Writing" begin
        sc = Toolips.SpoofConnection()
        c = h("myh", 1, text = "welcome")
        write!(sc, c)
        @test sc.http.text == """<h1 id = myh >welcome</h1>"""
    end
    @testset "Component Methods" begin
        c = h("myh", 1, text = "welcome")
        c2 = h("myh", 2)
        properties!(c2, c)
        @test c2[:text] == "welcome"
        push!(c, c2)
        @test length(c[:children]) != 0
        @test has_children(c)
        c[:text] = "hello world!"
        @test c[:text] == "hello world!"
        st = Style("thestyle", color = "blue")
        @test st.properties[:color] == "blue"
        style!(c, st)
        @test c[:class] == st.name
        style!(c, "color" => "blue")
        @test typeof(c["style"]) == String
        style2 = Style("other")
        style!(style2, st)
        @test st.properties[:color] == "blue"
        a = Animation("myanim2")
        a[50] = "color" => "black"
        @test a.keyframes["50%"] == "color: black; "
        cnts = components(c, c2)
        @test typeof(cnts) == Vector{Servable}
    end
end
@testset "Core" begin
    r = route("/") do c::Connection

    end
    logger = Logger()
    files = Files("stuff")
    @testset "Routes" begin
        @test typeof(r) == Toolips.Route
        @test r.path == "/"
        @test typeof(routes(r)) == Vector{Route}
    end
    @testset "Extensions" begin
        @test typeof(logger) == Logger
        @test typeof(files) == Files
    end
    @testset "ServerTemplate" begin
        st = ServerTemplate("127.0.0.1", 8005, routes(r),
                            extensions = [logger, files])
        @test typeof(st) == ServerTemplate
        @test st.ip == "127.0.0.1"
    end
end

@testset "LiveApp" begin
    r = route("/") do c::Connection

    end
    logger = Logger()
    files = Files("stuff")
    st = ServerTemplate("127.0.0.1", 8005, routes(r),
                        extensions = [logger, files])
    ws = st.start()
    @test typeof(ws) == Main.Toolips.WebServer
    @testset "General Methods" begin

    end
    @testset "Connection Methods" begin

    end
    @testset "Writes" begin

    end
#    Toolips.new_app("CoolApp")
end # - App
