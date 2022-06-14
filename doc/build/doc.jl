using Toolips, Documenter

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
                "Overview" => "overview.md"
               ]
       )
