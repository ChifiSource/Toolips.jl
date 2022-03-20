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

function getargs(http::Any)

end

function html(hypertxt::String)
    return(http -> hypertxt)
end

function fn(f::Function)
    m = first(methods(f))
    if m.nargs > 1 | m.nargs < 0
        throw(ArgumentError("Expected either 1 or 0 arguments."))
    elseif m.nargs == 1
        return(f)
    else
        return(http -> f())
    end
end

function generate(p::Page, args::String)
    p.f(args)
end
include("../server/serve.jl")
