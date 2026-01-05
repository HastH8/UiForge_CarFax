local Utils = Shared.Utils
local DB = Server.DB

local rateLimits = {}

local function nowMs()
    if type(GetGameTimer) == 'function' then
        return GetGameTimer()
    end

    return os.time() * 1000
end

local function debugLog(message, ...)
    if not Config.Debug then
        return
    end

    local text = message
    if select('#', ...) > 0 then
        text = string.format(message, ...)
    end

    if lib and lib.print and lib.print.debug then
        lib.print.debug(text)
        return
    end

    print(text)
end

local function notify(source, key, notifyType)
    TriggerClientEvent('ox_lib:notify', source, {
        type = notifyType or 'inform',
        description = locale(key)
    })
end

local function isRateLimited(source, key)
    if source <= 0 then
        return false
    end

    local current = nowMs()
    local playerLimits = rateLimits[source]

    if not playerLimits then
        rateLimits[source] = {
            [key] = current
        }
        return false
    end

    local last = playerLimits[key]
    if last and current - last < Config.RateLimitMs then
        return true
    end

    playerLimits[key] = current
    return false
end

AddEventHandler('playerDropped', function()
    rateLimits[source] = nil
end)

local function isAuthorized(source, jobConfig)
    if Bridge.IsAdmin(source) then
        return true
    end

    return Bridge.HasJob(source, jobConfig)
end

local function resolveJobLabel(source, payload)
    local label = Utils.cleanText(payload.job_label, Config.TextLimits.jobLabel)
    if label then
        return label
    end

    local fromJob = Bridge.GetJobLabel(source)
    if fromJob then
        return fromJob
    end

    return locale('job_label_system')
end

local function resolveAuthorIdentifier(source, payload)
    local identifier = Utils.cleanText(payload.author_identifier, 64)
    if identifier then
        return identifier
    end

    if source and source > 0 then
        return Bridge.GetIdentifier(source)
    end

    return nil
end

local function validatePlate(payload)
    if type(payload) ~= 'table' then
        return nil, 'notify_invalid_payload'
    end

    local plate = Utils.normalizePlate(payload.plate)
    if not Utils.isValidPlate(plate) then
        return nil, 'notify_invalid_plate'
    end

    return plate
end

local function validateVin(payload)
    local vin = Utils.normalizeVin(payload.vin)
    if vin and not Utils.isValidVin(vin) then
        return nil, 'notify_invalid_vin'
    end

    return vin
end

local function validatePhysicalRequest(payload)
    if type(payload) ~= 'table' then
        return nil, 'notify_invalid_payload'
    end

    local plate = Utils.normalizePlate(payload.plate)
    if not Utils.isValidPlate(plate) then
        return nil, 'notify_invalid_plate'
    end

    local vin, vinError = validateVin(payload)
    if vinError then
        return nil, vinError
    end

    return {
        plate = plate,
        vin = vin
    }
end

local function validateServicePayload(source, payload)
    local plate, plateError = validatePlate(payload)
    if not plate then
        return nil, plateError
    end

    local vin, vinError = validateVin(payload)
    if vinError then
        return nil, vinError
    end

    local serviceType = Utils.cleanText(payload.service_type, Config.TextLimits.customLabel)
    if not serviceType then
        return nil, 'notify_invalid_type'
    end

    local typeConfig = Utils.getServiceType(serviceType)
    if not typeConfig then
        return nil, 'notify_invalid_type'
    end

    local customLabel = Utils.cleanText(payload.custom_label, Config.TextLimits.customLabel)
    if serviceType == 'custom' and not customLabel then
        return nil, 'notify_invalid_custom_label'
    end

    local notes = Utils.cleanText(payload.notes, Config.TextLimits.notes)
    if not notes then
        return nil, 'notify_invalid_notes'
    end

    local mileage
    if Config.UseMileage and payload.mileage ~= nil and payload.mileage ~= '' then
        mileage = Utils.toInteger(payload.mileage)
        if not Utils.validateMileage(mileage) then
            return nil, 'notify_invalid_mileage'
        end
    end

    return {
        plate = plate,
        vin = vin,
        service_type = serviceType,
        custom_label = customLabel,
        notes = notes,
        mileage = mileage,
        job_label = resolveJobLabel(source, payload),
        author_identifier = resolveAuthorIdentifier(source, payload)
    }
end

local function validateIncidentPayload(source, payload)
    local plate, plateError = validatePlate(payload)
    if not plate then
        return nil, plateError
    end

    local vin, vinError = validateVin(payload)
    if vinError then
        return nil, vinError
    end

    local incidentType = Utils.cleanText(payload.incident_type, Config.TextLimits.customLabel)
    if not incidentType then
        return nil, 'notify_invalid_type'
    end

    local typeConfig = Utils.getIncidentType(incidentType)
    if not typeConfig then
        return nil, 'notify_invalid_type'
    end

    local customLabel = Utils.cleanText(payload.custom_label, Config.TextLimits.customLabel)
    if incidentType == 'custom' and not customLabel then
        return nil, 'notify_invalid_custom_label'
    end

    local notes = Utils.cleanText(payload.notes, Config.TextLimits.notes)
    if not notes then
        return nil, 'notify_invalid_notes'
    end

    return {
        plate = plate,
        vin = vin,
        incident_type = incidentType,
        custom_label = customLabel,
        notes = notes,
        is_private = typeConfig.private and 1 or 0,
        job_label = resolveJobLabel(source, payload),
        author_identifier = resolveAuthorIdentifier(source, payload)
    }
end

local function validateOwnerPayload(source, payload)
    local plate, plateError = validatePlate(payload)
    if not plate then
        return nil, plateError
    end

    local vin, vinError = validateVin(payload)
    if vinError then
        return nil, vinError
    end

    local status = Utils.cleanText(payload.registration_status, Config.TextLimits.customLabel)
    if not status then
        return nil, 'notify_invalid_registration'
    end

    local statusConfig = Utils.getRegistrationStatus(status)
    if not statusConfig then
        return nil, 'notify_invalid_registration'
    end

    local notes = Utils.cleanText(payload.notes, Config.TextLimits.notes)
    local ownerIdentifier = Utils.cleanText(payload.owner_identifier, 64)

    return {
        plate = plate,
        vin = vin,
        registration_status = status,
        notes = notes,
        owner_identifier = ownerIdentifier,
        author_identifier = resolveAuthorIdentifier(source, payload)
    }
end

local function buildServiceLabel(record)
    if record.service_type == 'custom' and record.custom_label then
        return record.custom_label
    end

    local entry = Utils.getServiceType(record.service_type)
    if entry and entry.label then
        return locale(entry.label)
    end

    return record.service_type
end

local function buildIncidentLabel(record)
    if record.incident_type == 'custom' and record.custom_label then
        return record.custom_label
    end

    local entry = Utils.getIncidentType(record.incident_type)
    if entry and entry.label then
        return locale(entry.label)
    end

    return record.incident_type
end

local function buildRegistrationLabel(status)
    local entry = Utils.getRegistrationStatus(status)
    if entry and entry.label then
        return locale(entry.label)
    end

    return status
end

local function sanitizeReport(report, jobName, isAdmin)
    local showIdentifiers = isAdmin or (jobName and Config.ReportVisibility.showIdentifiers[jobName]) or false
    local showPrivateIncidents = isAdmin or (jobName and Config.ReportVisibility.showPrivateIncidents[jobName]) or false
    local data = {
        generated_at = os.time(),
        vehicle = {
            plate = report.vehicle.plate,
            vin = report.vehicle.vin,
            report_id = report.vehicle.report_id,
            registration_status = report.vehicle.registration_status,
            registration_label = buildRegistrationLabel(report.vehicle.registration_status)
        },
        services = {},
        incidents = {},
        owners = {},
        visibility = {
            show_identifiers = showIdentifiers
        }
    }
    
    for i = 1, #report.services do
        local record = report.services[i]
        table.insert(data.services, {
            id = record.id,
            type = record.service_type,
            label = buildServiceLabel(record),
            notes = record.notes,
            job_label = record.job_label or locale('job_label_system'),
            author_identifier = showIdentifiers and record.author_identifier or nil,
            created_at = record.created_at,
            mileage = record.mileage
        })
    end
    
    for i = 1, #report.incidents do
        local record = report.incidents[i]
        if not (record.is_private == 1 and not showPrivateIncidents) then
            table.insert(data.incidents, {
                id = record.id,
                type = record.incident_type,
                label = buildIncidentLabel(record),
                notes = record.notes,
                job_label = record.job_label or locale('job_label_system'),
                author_identifier = showIdentifiers and record.author_identifier or nil,
                created_at = record.created_at,
                is_private = record.is_private == 1
            })
        end
    end
    
    for i = 1, #report.owners do
        local record = report.owners[i]
        table.insert(data.owners, {
            id = record.id,
            owner_index = record.owner_index,
            owner_label = locale('owner_index_label', record.owner_index),
            registration_status = record.registration_status,
            registration_label = buildRegistrationLabel(record.registration_status),
            notes = record.notes,
            created_at = record.created_at
        })
    end
    
    return data
end

local function addServiceRecord(source, payload, enforceAuth)
    if enforceAuth and not isAuthorized(source, Config.Commands.service.job) then
        return false, 'notify_not_authorized'
    end

    if isRateLimited(source, 'service') then
        return false, 'notify_rate_limited'
    end

    local data, errorKey = validateServicePayload(source, payload)
    if not data then
        return false, errorKey
    end

    local vehicle = DB.EnsureVehicle(data.plate, data.vin, nil)
    if not vehicle then
        return false, 'notify_report_unavailable'
    end

    local record = {
        service_type = data.service_type,
        custom_label = data.custom_label,
        notes = data.notes,
        job_label = data.job_label,
        author_identifier = data.author_identifier,
        created_at = os.time(),
        mileage = data.mileage
    }

    DB.AddServiceRecord(vehicle.id, record)

    debugLog(locale('debug_service_added', data.plate))
    return true
end

local function addIncidentRecord(source, payload, enforceAuth)
    if enforceAuth and not isAuthorized(source, Config.Commands.incident.job) then
        return false, 'notify_not_authorized'
    end

    if isRateLimited(source, 'incident') then
        return false, 'notify_rate_limited'
    end

    local data, errorKey = validateIncidentPayload(source, payload)
    if not data then
        return false, errorKey
    end

    local vehicle = DB.EnsureVehicle(data.plate, data.vin, nil)
    if not vehicle then
        return false, 'notify_report_unavailable'
    end

    local record = {
        incident_type = data.incident_type,
        custom_label = data.custom_label,
        notes = data.notes,
        job_label = data.job_label,
        author_identifier = data.author_identifier,
        created_at = os.time(),
        is_private = data.is_private
    }

    DB.AddIncidentRecord(vehicle.id, record)

    debugLog(locale('debug_incident_added', data.plate))
    return true
end

local function addOwnerRecord(source, payload, enforceAuth)
    if enforceAuth and not isAuthorized(source, Config.Commands.owneredit.job) then
        return false, 'notify_not_authorized'
    end

    if isRateLimited(source, 'owner') then
        return false, 'notify_rate_limited'
    end

    local data, errorKey = validateOwnerPayload(source, payload)
    if not data then
        return false, errorKey
    end

    local vehicle = DB.EnsureVehicle(data.plate, data.vin, data.registration_status)
    if not vehicle then
        return false, 'notify_report_unavailable'
    end

    local ownerIndex = DB.GetNextOwnerIndex(vehicle.id)

    local record = {
        owner_index = ownerIndex,
        owner_identifier = data.owner_identifier,
        author_identifier = data.author_identifier,
        registration_status = data.registration_status,
        notes = data.notes,
        created_at = os.time()
    }

    DB.AddOwnerRecord(vehicle.id, record)
    DB.UpdateVehicleRegistration(vehicle.id, data.registration_status)

    debugLog(locale('debug_owner_added', data.plate))
    return true
end

local function seedDebugData(source, plate)
    if not Bridge.IsAdmin(source) then
        return false, 'notify_not_authorized'
    end

    if isRateLimited(source, 'debug') then
        return false, 'notify_rate_limited'
    end

    local vehicle = DB.EnsureVehicle(plate, nil, nil)
    if not vehicle then
        return false, 'notify_report_unavailable'
    end

    local now = os.time()
    local jobLabel = Bridge.GetJobLabel(source) or locale('job_label_system')
    local author = Bridge.GetIdentifier(source)
    local mileageBase = 12000

    local services = {{
        type = 'oil_change',
        notes = 'Oil and filter replaced.'
    }, {
        type = 'engine_repair',
        notes = 'Belts and coolant replaced.'
    }, {
        type = 'body_repair',
        notes = 'Minor panel repair and paint match.'
    }, {
        type = 'full_inspection',
        notes = 'Full inspection completed.'
    }, {
        type = 'custom',
        custom_label = 'Detailing',
        notes = 'Interior detailing and polish.'
    }, {
        type = 'oil_change',
        notes = 'Routine oil change logged.'
    }}

    for i = 1, #services do
        local entry = services[i]
        DB.AddServiceRecord(vehicle.id, {
            service_type = entry.type,
            custom_label = entry.custom_label,
            notes = entry.notes,
            job_label = jobLabel,
            author_identifier = author,
            created_at = now - (86400 * i),
            mileage = Config.UseMileage and (mileageBase + (i * 350)) or nil
        })
    end

    local incidents = {{
        type = 'insurance_claim',
        notes = 'Minor collision claim recorded.'
    }, {
        type = 'impound',
        notes = 'Vehicle impounded for violations.'
    }, {
        type = 'police_seizure',
        notes = 'Held for investigation.'
    }, {
        type = 'stolen_report',
        notes = 'Reported stolen and later recovered.'
    }}

    for i = 1, #incidents do
        local entry = incidents[i]
        local typeConfig = Utils.getIncidentType(entry.type)
        DB.AddIncidentRecord(vehicle.id, {
            incident_type = entry.type,
            custom_label = nil,
            notes = entry.notes,
            job_label = jobLabel,
            author_identifier = author,
            created_at = now - (86400 * (i + 2)),
            is_private = typeConfig and typeConfig.private or false
        })
    end

    local ownerStatuses = {'valid', 'expired', 'valid'}
    local ownerStart = DB.GetNextOwnerIndex(vehicle.id)

    for i = 1, #ownerStatuses do
        DB.AddOwnerRecord(vehicle.id, {
            owner_index = ownerStart + (i - 1),
            owner_identifier = ('owner-%s'):format(ownerStart + (i - 1)),
            author_identifier = author,
            registration_status = ownerStatuses[i],
            notes = 'Ownership transfer recorded.',
            created_at = now - (86400 * (i + 4))
        })
    end

    DB.UpdateVehicleRegistration(vehicle.id, ownerStatuses[#ownerStatuses])
    return true
end

lib.callback.register(Shared.Callbacks.GetReport, function(source, plate)
    if isRateLimited(source, 'report') then
        return {
            ok = false,
            reason = 'rate_limited'
        }
    end

    local normalized = Utils.normalizePlate(plate)
    if not Utils.isValidPlate(normalized) then
        return {
            ok = false,
            reason = 'invalid_plate'
        }
    end

    local report = DB.GetReportByPlate(normalized)
    if not report then
        return {
            ok = false,
            reason = 'not_found'
        }
    end

    local job = Bridge.GetJob(source)
    local jobName = job and job.name or nil
    local sanitized = sanitizeReport(report, jobName, Bridge.IsAdmin(source))

    return {
        ok = true,
        data = sanitized
    }
end)

lib.callback.register(Shared.Callbacks.GetVin, function(source, plate)
    if isRateLimited(source, 'vin') then
        return {
            ok = false,
            reason = 'rate_limited'
        }
    end

    local normalized = Utils.normalizePlate(plate)
    if not Utils.isValidPlate(normalized) then
        return {
            ok = false,
            reason = 'invalid_plate'
        }
    end

    local vehicle = DB.EnsureVehicle(normalized, nil, nil)
    if not vehicle then
        return {
            ok = false,
            reason = 'not_found'
        }
    end

    return {
        ok = true,
        vin = vehicle.vin
    }
end)

RegisterNetEvent(Shared.ServerEvents.RequestPhysicalReport, function(payload)
    local source = source

    if not Config.PhysicalReport or not Config.PhysicalReport.enabled then
        notify(source, 'notify_report_unavailable', 'error')
        return
    end

    if isRateLimited(source, 'physical') then
        notify(source, 'notify_rate_limited', 'error')
        return
    end

    local data, errorKey = validatePhysicalRequest(payload)
    if not data then
        notify(source, errorKey or 'notify_invalid_payload', 'error')
        return
    end

    local vehicle = DB.EnsureVehicle(data.plate, data.vin, nil)
    if not vehicle then
        notify(source, 'notify_report_unavailable', 'error')
        return
    end

    local metadata = {
        plate = vehicle.plate,
        vin = vehicle.vin,
        report_id = vehicle.report_id,
        label = locale('item_carfax_label'),
        description = locale('item_carfax_description', vehicle.plate)
    }

    if not Bridge.CanCarryItem(source, Config.PhysicalReport.item, 1, metadata) then
        notify(source, 'notify_inventory_full', 'error')
        return
    end

    local price = tonumber(Config.PhysicalReport.price) or 0
    local account = Config.PhysicalReport.moneyType or 'cash'

    if price > 0 and Bridge.GetMoney(source, account) < price then
        notify(source, 'notify_insufficient_funds', 'error')
        return
    end

    if price > 0 and not Bridge.RemoveMoney(source, account, price, 'carfax_report') then
        notify(source, 'notify_insufficient_funds', 'error')
        return
    end

    local added = Bridge.AddItem(source, Config.PhysicalReport.item, 1, metadata)
    if not added then
        if price > 0 then
            Bridge.AddMoney(source, account, price, 'carfax_refund')
        end
        notify(source, 'notify_inventory_full', 'error')
        return
    end

    notify(source, 'notify_physical_report_issued', 'success')
end)

RegisterNetEvent(Shared.ServerEvents.AddService, function(payload)
    local source = source
    local ok, errorKey = addServiceRecord(source, payload, true)
    if not ok then
        notify(source, errorKey or 'notify_report_unavailable', 'error')
        return
    end

    notify(source, 'notify_service_added', 'success')
end)

RegisterNetEvent(Shared.ServerEvents.AddIncident, function(payload)
    local source = source
    local ok, errorKey = addIncidentRecord(source, payload, true)
    if not ok then
        notify(source, errorKey or 'notify_report_unavailable', 'error')
        return
    end

    notify(source, 'notify_incident_added', 'success')
end)

RegisterNetEvent(Shared.ServerEvents.AddOwner, function(payload)
    local source = source
    local ok, errorKey = addOwnerRecord(source, payload, true)
    if not ok then
        notify(source, errorKey or 'notify_report_unavailable', 'error')
        return
    end

    notify(source, 'notify_owner_added', 'success')
end)

RegisterNetEvent(Shared.ServerEvents.DebugSeed, function(payload)
    local source = source
    local plate, plateError = validatePlate(payload)
    if not plate then
        notify(source, plateError or 'notify_invalid_plate', 'error')
        return
    end

    local ok, errorKey = seedDebugData(source, plate)
    if not ok then
        notify(source, errorKey or 'notify_report_unavailable', 'error')
        return
    end

    notify(source, 'notify_debug_seeded', 'success')
end)

local function registerCommand(commandConfig, eventName)
    if not commandConfig or not commandConfig.name then
        return
    end

    lib.addCommand(commandConfig.name, {
        help = locale(commandConfig.description),
        restricted = false
    }, function(source)
        if source == 0 then
            return
        end

        if commandConfig.adminOnly then
            if not Bridge.IsAdmin(source) then
                notify(source, 'notify_not_authorized', 'error')
                return
            end
        elseif commandConfig.job and not isAuthorized(source, commandConfig.job) then
            notify(source, 'notify_not_authorized', 'error')
            return
        end

        TriggerClientEvent(eventName, source)
    end)
end

registerCommand(Config.Commands.service, Shared.Events.OpenServiceInput)
registerCommand(Config.Commands.incident, Shared.Events.OpenIncidentInput)
registerCommand(Config.Commands.owneredit, Shared.Events.OpenOwnerInput)
registerCommand(Config.Commands.carfax, Shared.Events.OpenReport)
registerCommand(Config.Commands.vin, Shared.Events.OpenVinLookup)

exports('AddService', function(plate, data)
    return addServiceRecord(0, {
        plate = plate,
        service_type = data and data.service_type,
        custom_label = data and data.custom_label,
        notes = data and data.notes,
        job_label = data and data.job_label,
        author_identifier = data and data.author_identifier,
        mileage = data and data.mileage,
        vin = data and data.vin
    }, false)
end)

exports('AddIncident', function(plate, data)
    return addIncidentRecord(0, {
        plate = plate,
        incident_type = data and data.incident_type,
        custom_label = data and data.custom_label,
        notes = data and data.notes,
        job_label = data and data.job_label,
        author_identifier = data and data.author_identifier,
        vin = data and data.vin
    }, false)
end)

exports('AddOwnerChange', function(plate, data)
    return addOwnerRecord(0, {
        plate = plate,
        registration_status = data and data.registration_status,
        notes = data and data.notes,
        owner_identifier = data and data.owner_identifier,
        author_identifier = data and data.author_identifier,
        vin = data and data.vin
    }, false)
end)

exports('GetReport', function(plate)
    local normalized = Utils.normalizePlate(plate)
    if not Utils.isValidPlate(normalized) then
        return nil
    end

    local report = DB.GetReportByPlate(normalized)
    if not report then
        return nil
    end

    return sanitizeReport(report, nil, true)
end)

local function handleReportItemUse(source, metadata)
    if type(metadata) ~= 'table' or not metadata.plate then
        notify(source, 'notify_invalid_report_item', 'error')
        return
    end

    TriggerClientEvent(Shared.Events.OpenReport, source, metadata.plate)
end

if Config.PhysicalReport and Config.PhysicalReport.enabled and Config.PhysicalReport.item then
    Bridge.RegisterUsableItem(Config.PhysicalReport.item, function(source, metadata)
        handleReportItemUse(source, metadata)
    end)
end
