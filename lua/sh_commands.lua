

function RPTools.CanAdmin(ply)
    if not IsValid(ply) then return false end
    if sam then return ply:HasPermission("rptools_admin") end
    return RPTools.CanAdmin(ply)
end