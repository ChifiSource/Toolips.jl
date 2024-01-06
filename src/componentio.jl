function html_properties(s::AbstractString)
    propvec::Vector{SubString} = split(s, " ")
    properties::Dict{String, Any} = Dict{String, Any}(begin
        ppair::Vector{SubString} = split(segment, "=")
        if length(ppair) < 2
            string(ppair[1]) => string(ppair[1])
        else
            string(ppair[1]) => replace(string(ppair[2]), "\"" => "")
        end
    end for segment in propvec)
    properties::Dict{String, Any}
end

function htmlcomponent(s::String, names_only::Bool = true)
    stop::Int64 = 1
    laststop::Int64 = 1
    comps::Vector{Component{<:Any}} = Vector{Component{<:Any}}()
    while true
        if stop == laststop
            println("no")
        end
        laststop = stop
        argfinish = findnext(">", s, stop)
        tagstart = findnext("<", s, stop)
        tagend = findnext(" ", s, stop)
        tagbefore = minimum(tagstart) > maximum(argfinish)
        if isnothing(argfinish) || isnothing(tagend) || isnothing(tagstart) || tagbefore
            break
        end
        tag::String = s[minimum(tagstart) + 1:minimum(tagend) - 1]
        finisher = findnext("</$tag>", s, maximum(argfinish) + 1)
        stop = maximum(argfinish) + 1
        if contains(tag, "/")
            continue
        end
        name::String = "component-$stop"
        idstart = findfirst("id=\"", s[minimum(tagstart):minimum(argfinish)])
        if isnothing(finisher)
            continue
        end
        if (isnothing(idstart) && names_only)
            continue
        end
        argstring::String = s[minimum(tagend) + 1:minimum(argfinish) - 1]
        properties::Dict{String, Any} = html_properties(argstring)
        if "id" in keys(properties)
            name = properties["id"]
            delete!(properties, "id")
        end
        text::String = ""
        try
            text = s[minimum(argfinish) + 1:minimum(finisher) - 1]
        catch
            text = s[minimum(argfinish) + 1:minimum(finisher) - 2]
        end
        push!(properties, "text" => text)
        props = Dict{Symbol, Any}(Symbol(k[1]) => k[2] for k in properties)
        push!(comps, Component{Symbol(tag)}(name, tag, props))
    end
    return(comps)
end

function htmlcomponent(s::String, readonly::Vector{String})
    if readonly[1] == "none"
        return Vector{Servable}()
    end
    Vector{Servable}(filter!(x -> ~(isnothing(x)), [begin
        element_sect = findfirst(" id=\"$compname\"", s)
        if ~(isnothing(element_sect))
            starttag = findprev("<", s, element_sect[1])[1]
            ndtag = findnext(" ", s, element_sect[1])[1]
            argfinish = findnext(">", s, ndtag)[1] + 1
            tg = s[starttag + 1:ndtag - 1]
            finisher = findnext("</$tg", s, argfinish)
            fulltxt = s[argfinish:finisher[1] - 1]
            properties = html_properties(s[ndtag:argfinish - 2])
            name::String = ""
            if "id" in keys(properties)
                name = properties["id"]
                delete!(properties, "id")
            end
            push!(properties, "text" => replace(fulltxt, "<br>" => "\n", "<div>" => "", 
            "&#36;" => "\$", "&#37;" => "%", "&#38;" => "&", "&nbsp;" => " ", "&#60;" => "<", "	&lt;" => "<", 
            "&#62;" => ">", "&gt;" => ">", "<br" => "\n", "&bsol;" => "\\", "&#63;" => "?"))
            Component(compname, string(tg), properties)
        else
        end
    end for compname in readonly]))::Vector{Component{<:Any}}
end

componenthtml(comps::Vector{<:AbstractComponent}) = begin

end

componenthtml(comps::Vector{Component{<:Any}}) = join([string(comp) for comp in comps])

componentcss(comps::Vector{<:StyleComponent}) = begin

end

function mdcomponent(s::String)

end

function componentmd(s::String)

end
