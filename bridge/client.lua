Bridge = Bridge or {}

local function isResourceStarted(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

if Config.Framework == 'auto' then
    if isResourceStarted('qbx_core') then
        Bridge.Framework = 'qbox'
    elseif isResourceStarted('qb-core') then
        Bridge.Framework = 'qb'
    elseif isResourceStarted('es_extended') then
        Bridge.Framework = 'esx'
    else
        Bridge.Framework = 'standalone'
    end
else
    Bridge.Framework = Config.Framework
end
