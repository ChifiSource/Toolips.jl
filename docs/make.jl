using Toolips, Documenter
using Toolips: Servable, ServerExtension, ToolipsServer, SpoofStream
using Toolips: SpoofConnection, StyleComponent, AbstractConnection
using ToolipsSession
Documenter.makedocs(root = ".",
       source = "src",
       build = "build",
       clean = false,
       doctest = true,
       modules = [Toolips, ToolipsSession],
       repo = "https://github.com/ChifiSource/Toolips.jl",
       highlightsig = true,
       sitename = "toolips",
       expandfirst = [],
       pages = Any[
                "toolips" => "index.md",
                "basics" => Any[
                "projects" => "projects.md",
                "servables" => "interface.md",
                "core" => "core.md"
                ],
                "advanced" => Any[
                "session extension" => "toolips_session.md",
                "creating servables" => "creating_servables.md",
                "extending toolips" => "developer_api.md",
               ]
               ]
       )
