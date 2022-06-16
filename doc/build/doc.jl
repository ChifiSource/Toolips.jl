using Toolips, Documenter
import Toolips: Servable, ServerExtension, ToolipsServer
Documenter.makedocs(root = "../",
       source = "src",
       build = "build",
       clean = true,
       doctest = true,
       modules = [Toolips],
       repo = "https://github.com/ChifiSource/Toolips.jl",
       highlightsig = true,
       sitename = "toolips",
       expandfirst = [],
       pages = [
                "toolips" => "index.md",
                "projects" => "projects.md",
                "core" => "core.md",
                "servables" => "servables.md",
                "sessions" => "toolips_session.md",
                "developer api" => "developer_api.md",
               ]
       )
