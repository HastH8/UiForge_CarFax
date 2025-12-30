Shared = Shared or {}
Shared.Utils = Shared.Utils or {}

local Utils = Shared.Utils

local seeded = false
local patternMap = {
    ['1'] = '0123456789',
    ['A'] = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    ['a'] = 'abcdefghijklmnopqrstuvwxyz',
    ['.'] = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
}

local function seedRandom()
    if seeded then
        return
    end

    local seed = os.time()
    if type(GetGameTimer) == 'function' then
        seed = seed + GetGameTimer()
    end

    math.randomseed(seed)
    seeded = true
end

function Utils.trim(value)
    if type(value) ~= 'string' then
        return nil
    end

    local trimmed = value:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed == '' then
        return nil
    end

    return trimmed
end

function Utils.cleanText(value, maxLength)
    local trimmed = Utils.trim(value)
    if not trimmed then
        return nil
    end

    local cleaned = trimmed:gsub('[%c]', '')
    cleaned = cleaned:gsub('%s+', ' ')

    if maxLength and #cleaned > maxLength then
        cleaned = cleaned:sub(1, maxLength)
    end

    return cleaned
end

function Utils.normalizePlate(plate)
    local cleaned = Utils.cleanText(plate, Config.PlateMaxLength)
    if not cleaned then
        return nil
    end

    cleaned = cleaned:gsub('%s+', '')
    return cleaned:upper()
end

function Utils.normalizeVin(vin)
    local cleaned = Utils.cleanText(vin, Config.VinLength)
    if not cleaned then
        return nil
    end

    cleaned = cleaned:gsub('%s+', '')
    return cleaned:upper()
end

function Utils.isValidPlate(plate)
    return plate and #plate >= 1 and #plate <= Config.PlateMaxLength
end

function Utils.isValidVin(vin)
    return vin and #vin == Config.VinLength
end

function Utils.toInteger(value)
    local num = tonumber(value)
    if not num then
        return nil
    end

    return math.floor(num)
end

function Utils.validateMileage(mileage)
    if mileage == nil then
        return true
    end

    local value = Utils.toInteger(mileage)
    if not value then
        return false
    end

    return value >= 0
end

function Utils.randomFromPattern(pattern)
    if lib and lib.string and lib.string.random then
        return lib.string.random(pattern)
    end

    seedRandom()

    local out = {}
    local i = 1

    while i <= #pattern do
        local ch = pattern:sub(i, i)
        if ch == '^' then
            i = i + 1
            table.insert(out, pattern:sub(i, i))
        else
            local chars = patternMap[ch]
            if chars then
                local idx = math.random(1, #chars)
                table.insert(out, chars:sub(idx, idx))
            else
                table.insert(out, ch)
            end
        end

        i = i + 1
    end

    return table.concat(out)
end

function Utils.generateReportId()
    return Utils.randomFromPattern(Config.ReportIdPattern)
end

function Utils.generateVin()
    return Utils.randomFromPattern(Config.VinPattern)
end

function Utils.getConfigEntry(list, value)
    if type(list) ~= 'table' then
        return nil
    end

    for i = 1, #list do
        if list[i].value == value then
            return list[i]
        end
    end

    return nil
end

function Utils.getServiceType(value)
    return Utils.getConfigEntry(Config.ServiceTypes, value)
end

function Utils.getIncidentType(value)
    return Utils.getConfigEntry(Config.IncidentTypes, value)
end

function Utils.getRegistrationStatus(value)
    return Utils.getConfigEntry(Config.RegistrationStatuses, value)
end

function Utils.getJobLabel(jobName)
    if not jobName then
        return nil
    end

    local key = Config.JobLabels[jobName]
    if key then
        return locale(key)
    end

    return jobName
end
