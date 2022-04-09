import Base: +

function parsetypes(data)
    x = nothing
    try
        x = parse(Int64, data)
    catch
        try
        x = parse(Bool, data)
        catch
            try
            x = parse(Float64, data)
            catch
            try
                x = parse(Array, data)
            catch
                try
                    x = parse(Dict, data)
                catch
                    x = data
                end
            end
        end
    end
end
    return(x)
end
function getargs(http::Any)
    split(http.message.target, '?')[2]
    args = split(target, '&')
    arg_dict = Dict()
    for arg in args
        keyarg = split(arg, '=')
        x = tryparse(keyarg[2])
        push!(arg_dict, Symbol(keyarg[1]) => x)
    end
    return(arg_dict)
end

function getarg(http::Any, s::Symbol)
    getargs(http)[s]
end

function getarg(http::HTTP.Stream, s::Symbol, T::Type)
    parse(getargs(http)[s], T)
end

function getpost(http::HTTP.Stream)
    http.message.body
end

function write_file(URI::String, http::HTTP.Stream)
    open(URI, "r") do i
        write(http, i)
    end
end


function lists(dct::Pair{String, String} ...)
    lists::Vector{List} = []
    for (key, value) in dct
        push!(lists, List(label = key, href = value))
    end
    lists
end


+(f::Function, f2::Function) = Page([f, f2])
+(p::Page, f::Function) = p.add(f)
+(fc::FormComponent, fc2::FormComponent) = Form(fc, fc2)
