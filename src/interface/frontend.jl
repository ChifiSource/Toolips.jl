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
    ul::UnorderedList
    function Navbar()

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
    function Columns(n::Int64, comparrays::AbstractArray ...)
        if length(comparrays) != n
            throw(DimensionMismatch("Component arrays must be length of n columns!"))
        end

    end
end
