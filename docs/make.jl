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
                "basics" => Any[
                "toolips?" => "index.md",
                "creating projects" => "projects.md",
                "routing" => "routing.md",
                "connections" => "connections.md",
                "command-line interface" => "cli.md",
                "requests" => "requests.md",
                "composing websites" => "composing_websites.md",
                "deploying projects" => "deploying_projects.md"
                ],
                "servables" => Any[
                "components" => "servables/components.md",
                "styles" => "servables/styles.md",
                "animations" => "servables/animations.md",
                "creating servables" => "servables/creating_servables.md",
                ],
                "server extensions" => Any[
                "default extensions" => "extensions/toolips_extensions.md",
                "toolips session" => "extensions/toolips_session.md",
                "toolips defaults" => "extensions/toolips_defaults.md",
                "toolips markdown" => "extensions/toolips_markdown.md",
                "toolips memwrite" => "extensions/toolips_memwrite.md",
                "toolips base64" => "extensions/toolips_base64.md",
                "toolips remote" => "extensions/toolips_remote.md",
                "toolips uploader" => "extensions/toolips_uploader.md",
                "toolips canvas" => "extensions/toolips_canvas.md",
                "toolips auth" => "extensions/toolips_auth.md",
                "creating extensions" => "extensions/creating_extensions.md",
                ],
                "examples" => Any[
                "simple website" => "examples/simple_website.md",
                "blog" => "examples/blog.md",
                "text editor" => "examples/text_editor.md",
                "sound sharing platform" => "examples/sound_share.md",
                "file explorer" => "examples/file_explorer.md",
                "interactive dashboard" => "examples/interactive_dash.md",
                ],
                "developer API" => "developer_api.md",
               ]
       )
