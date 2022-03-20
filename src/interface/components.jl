mutable struct Page
    f::Function
    components::AbstractVector
    add::Function
    function Page()
        components = []
    end
    function Page(comps::Function ...)
        render = ""
        for component in comps
            render = "" * component()
        end
    end
end

function getargs()

end

function html(hypertxt::String)
    return(() -> hypertxt)
end

function fn(f::Function)
    return(f)
end

function generate(p::Page, args::String)
    p.f(args)
end
include("../server/serve.jl")
