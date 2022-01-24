abstract type Page end
mutable struct InteractPage <: Page
    ui::Any
end
mutable struct HTMLPage <: Page
    html::String
end
include("../server/serve.jl")
