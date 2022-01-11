module RoseBuds

abstract type Component end
include("templates/components.jl")
export Route, RoseBud, @route
include("core/npmloader.jl")
export NPMInstall
try
    NPMStart()
catch
    throw("NPM Could not be initialized. Ensure Node Package Manager is installed.")
end

# --

end
