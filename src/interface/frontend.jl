mutable struct Header
    name::String
    f::Function
    html::String
    components::AbstractArray
    align::Symbol
end

mutable struct Navbar
    name::String
    f::Function
    comps::AbstractArray
    function Navbar(content::Pair{String, Any} ...)
        comps = []
        for comp in content
            if typeof(comp[2]) == Array
                # Need to figure out some good way to provide
                #    all of the data that is needed here.
            else

            end
        end
    end
end

mutable struct Body
    name::String
    f::Function
    align::Symbol
end

mutable struct Columns
    name::String
    f::Function
    html::String
    components::AbstractArray{AbstractArray}
    add::Function
    function Columns(name::String, n::Integer, comparrays::AbstractArray ...;
        width = .5)
        percentage = .5 * 100
        perc_txt = "%$percentage"
        col_rowcss = """.newspaper {
  column-width: 100px;
}
.column {
  float: left;
  width: $perc_txt;
}
    .row:after {
    content: "";
    display: table;
    clear: both;
}"""
        if length(comparrays) != n
            throw(DimensionMismatch("Component arrays must be length of n columns!"))
        end
        html = ""
        f(http) = begin
            open = "<style>$col_rowcss</style><div class='row'>"
            for i in 1:n
                open = open * """<div class="column">"""
                try
                    open = open * join([l.f(http) for l in comparrays[i]])
                catch
                    open = open * join([w(http) for w in comparrays[i]])
                end
                open = open * "</div>"
            end
            open * "</div>"
        end
    end
end
