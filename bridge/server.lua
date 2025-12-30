Bridge = Bridge or {}

local QBCore
local ESX

local function isResourceStarted(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

local function detectFramework()
    if Config.Framework ~= 'auto' then
        return Config.Framework
    end

    if isResourceStarted('qbx_core') then
        return 'qbox'
    end

    if isResourceStarted('qb-core') then
        return 'qb'
    end

    if isResourceStarted('es_extended') then
        return 'esx'
    end

    return 'standalone'
end

local function initQb()
    local ok, core = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)

    if ok then
        QBCore = core
    end
end


local function initEsx()
    local ok, core = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)

    if ok then
        ESX = core
    end
end

Bridge.Framework = detectFramework()

if Bridge.Framework == 'qb' then
    initQb()
elseif Bridge.Framework == 'esx' then
    initEsx()
end

function Bridge.GetPlayer(source)
    if Bridge.Framework == 'qb' then
        return QBCore and QBCore.Functions and QBCore.Functions.GetPlayer(source) or nil
    end

    if Bridge.Framework == 'qbox' then
        local ok, player = pcall(function()
            return exports['qbx_core']:GetPlayer(source)
        end)

        if ok then
            return player
        end

        return nil
    end

    if Bridge.Framework == 'esx' then
        return ESX and ESX.GetPlayerFromId(source) or nil
    end

    return nil
end

function Bridge.GetIdentifier(source)
    local player = Bridge.GetPlayer(source)
    if not player then
        return nil
    end

    if Bridge.Framework == 'esx' then
        if player.getIdentifier then
            return player.getIdentifier()
        end

        return player.identifier
    end

    if player.PlayerData then
        return player.PlayerData.citizenid or player.PlayerData.identifier
    end

    return nil
end

function Bridge.GetJob(source)
    local player = Bridge.GetPlayer(source)
    if not player then
        return nil
    end

    if Bridge.Framework == 'esx' then
        local job = player.getJob and player.getJob() or player.job
        if not job then
            return nil
        end

        return {
            name = job.name,
            label = job.label or job.name,
            grade = job.grade or 0
        }
    end

    local job = player.PlayerData and player.PlayerData.job or nil
    if not job then
        return nil
    end

    return {
        name = job.name,
        label = job.label or job.name,
        grade = (job.grade and job.grade.level) or job.grade or 0
    }
end

function Bridge.HasJob(source, required)
    if not required then
        return true
    end

    local job = Bridge.GetJob(source)
    if not job then
        return false
    end

    local minGrade = required[job.name]
    if minGrade == nil then
        return false
    end

    return job.grade >= minGrade
end

function Bridge.IsAdmin(source)
    if Config.AdminAce and IsPlayerAceAllowed(source, Config.AdminAce) then
        return true
    end

    local player = Bridge.GetPlayer(source)
    if not player then
        return false
    end

    local group

    if Bridge.Framework == 'esx' then
        group = player.getGroup and player.getGroup() or player.group
    elseif player.PlayerData then
        group = player.PlayerData.permission or player.PlayerData.group
    end

    if not group then
        return false
    end

    for i = 1, #Config.AdminGroups do
        if group == Config.AdminGroups[i] then
            return true
        end
    end

    return false
end

function Bridge.GetJobLabel(source)
    local job = Bridge.GetJob(source)
    if not job then
        return nil
    end

    local label = Shared.Utils.getJobLabel(job.name)
    return label or job.label or job.name
end
