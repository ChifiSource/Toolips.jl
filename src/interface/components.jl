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
    split(http.message.target, '?')[2]
end

function html(hypertxt::String)
    return(http -> hypertxt)
end

function html_file(hypertxt::String)

end

function fn(f::Function)
    m = first(methods(f))
    if m.nargs > 2 | m.nargs < 1
        throw(ArgumentError("Expected either 1 or 2 arguments."))
    elseif m.nargs == 2
        http -> f(http)
    else
        http -> f()
    end
end
include("../server/serve.jl")
