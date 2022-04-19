#==
Animations
==#
function fade_in_bottom(duration::Float64)
    anim = Animation("fade_in_bottom")
    @keyframes anim :from :opacity => 0
    @keyframes anim :to :opacity =>  1
    anim
end
#===
    For when the styling back-end is complete
ToolipsStyleSheet() = ToolipsStyleSheet = StyleSheet("Toolips")
===#
