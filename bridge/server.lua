Bridge = Bridge or {}

local QBCore
local ESX
local oxUsableHandlers = nil
local oxUsableHooked = false

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

local function detectInventory()
    if Config.Inventory and Config.Inventory ~= 'auto' then
        return Config.Inventory
    end

    if isResourceStarted('ox_inventory') then
        return 'ox'
    end

    if Bridge.Framework == 'qbox' then
        return 'qbox'
    end

    if Bridge.Framework == 'qb' then
        return 'qb'
    end

    if Bridge.Framework == 'esx' then
        return 'esx'
    end

    return 'standalone'
end

local function initQb()
    QBCore = exports['qb-core']:GetCoreObject()
end

local function initEsx()
    ESX = exports['es_extended']:getSharedObject()
end

Bridge.Framework = detectFramework()
Bridge.Inventory = detectInventory()

if Bridge.Framework == 'qb' then
    initQb()
elseif Bridge.Framework == 'esx' then
    initEsx()
end

local function hookOxUsableItems()
    if oxUsableHooked then
        return
    end

    oxUsableHooked = true
    oxUsableHandlers = oxUsableHandlers or {}

    AddEventHandler('ox_inventory:usedItem', function(playerId, name, slotId, metadata)
        local handler = oxUsableHandlers and oxUsableHandlers[name]
        if handler then
            handler(playerId, metadata or {}, {
                name = name,
                slot = slotId
            })
        end
    end)
end

function Bridge.GetPlayer(source)
    if Bridge.Framework == 'qb' then
        return QBCore and QBCore.Functions and QBCore.Functions.GetPlayer(source) or nil
    end

    if Bridge.Framework == 'qbox' then
        return exports['qbx_core']:GetPlayer(source)
    end

    if Bridge.Framework == 'esx' then
        return ESX and ESX.GetPlayerFromId(source) or nil
    end

    return nil
end

function Bridge.GetMoney(source, account)
    if Bridge.Framework == 'qbox' then
        return exports.qbx_core:GetMoney(source, account) or 0
    end

    if Bridge.Framework == 'qb' then
        local player = Bridge.GetPlayer(source)
        if not player or not player.PlayerData or not player.PlayerData.money then
            return 0
        end

        return player.PlayerData.money[account] or 0
    end

    if Bridge.Framework == 'esx' then
        local player = Bridge.GetPlayer(source)
        if not player then
            return 0
        end

        if account == 'cash' or account == 'money' then
            if player.getMoney then
                return player.getMoney() or 0
            end
        end

        local accountData = player.getAccount and player.getAccount(account)
        if accountData and accountData.money ~= nil then
            return accountData.money or 0
        end
    end

    return 0
end

function Bridge.AddMoney(source, account, amount, reason)
    if amount <= 0 then
        return true
    end

    if Bridge.Framework == 'qbox' then
        return exports.qbx_core:AddMoney(source, account, amount, reason)
    end

    if Bridge.Framework == 'qb' then
        local player = Bridge.GetPlayer(source)
        return player and player.Functions and player.Functions.AddMoney and player.Functions.AddMoney(account, amount, reason) or false
    end

    if Bridge.Framework == 'esx' then
        local player = Bridge.GetPlayer(source)
        if not player then
            return false
        end

        if account == 'cash' then
            account = 'money'
        end

        if account == 'money' then
            if player.addMoney then
                player.addMoney(amount, reason)
                return true
            end
        end

        if player.addAccountMoney then
            player.addAccountMoney(account, amount, reason)
            return true
        end
    end

    return false
end

function Bridge.RemoveMoney(source, account, amount, reason)
    if amount <= 0 then
        return true
    end

    if Bridge.Framework == 'qbox' then
        return exports.qbx_core:RemoveMoney(source, account, amount, reason)
    end

    if Bridge.Framework == 'qb' then
        local player = Bridge.GetPlayer(source)
        return player and player.Functions and player.Functions.RemoveMoney and player.Functions.RemoveMoney(account, amount, reason) or false
    end

    if Bridge.Framework == 'esx' then
        local player = Bridge.GetPlayer(source)
        if not player then
            return false
        end

        if account == 'cash' then
            account = 'money'
        end

        if account == 'money' then
            if player.removeMoney then
                player.removeMoney(amount, reason)
                return true
            end
        end

        if player.removeAccountMoney then
            player.removeAccountMoney(account, amount, reason)
            return true
        end
    end

    return false
end

function Bridge.CanCarryItem(source, item, count, metadata)
    if Bridge.Inventory == 'ox' then
        return exports.ox_inventory:CanCarryItem(source, item, count, metadata)
    end

    return true
end

function Bridge.AddItem(source, item, count, metadata)
    if Bridge.Inventory == 'ox' then
        return exports.ox_inventory:AddItem(source, item, count, metadata)
    end

    if Bridge.Framework == 'qbox' then
        local player = Bridge.GetPlayer(source)
        if player and player.Functions and player.Functions.AddItem then
            return player.Functions.AddItem(item, count, false, metadata)
        end
        return false
    end

    if Bridge.Framework == 'qb' then
        local player = Bridge.GetPlayer(source)
        if player and player.Functions and player.Functions.AddItem then
            return player.Functions.AddItem(item, count, false, metadata)
        end
        return false
    end

    if Bridge.Framework == 'esx' then
        local player = Bridge.GetPlayer(source)
        if not player then
            return false
        end

        if player.addInventoryItem then
            player.addInventoryItem(item, count)
            return true
        end
    end

    return false
end

function Bridge.RegisterUsableItem(itemName, cb)
    if Bridge.Inventory == 'ox' then
        hookOxUsableItems()
        oxUsableHandlers[itemName] = cb
        return true
    end

    if Bridge.Framework == 'qbox' then
        exports.qbx_core:CreateUseableItem(itemName, function(source, item)
            cb(source, item and (item.info or item.metadata) or {}, item)
        end)
        return true
    end

    if Bridge.Framework == 'qb' and QBCore and QBCore.Functions and QBCore.Functions.CreateUseableItem then
        QBCore.Functions.CreateUseableItem(itemName, function(source, item)
            cb(source, item and (item.info or item.metadata) or {}, item)
        end)
        return true
    end

    if Bridge.Framework == 'esx' and ESX and ESX.RegisterUsableItem then
        ESX.RegisterUsableItem(itemName, function(source)
            cb(source, {}, nil)
        end)
        return true
    end

    return false
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
