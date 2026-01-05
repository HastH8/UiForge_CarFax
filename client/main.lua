local isOpen = false
local physicalPed = nil
local physicalZone = nil
local isInPhysicalZone = false
local targetSystem = nil

local function getVehicleTarget()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        local hit, entity = lib.raycast.fromCamera()
        if hit and entity and IsEntityAVehicle(entity) then
            vehicle = entity
        end
    end

    if vehicle ~= 0 then
        return vehicle, GetVehicleNumberPlateText(vehicle)
    end

    return 0, nil
end

local function getVehiclePlate()
    local _, plate = getVehicleTarget()
    return plate
end

local function getJgMileage(vehicle, plate)
    if not Config.UseJgMileage then
        return nil
    end

    local resource = Config.JgMileageResource or 'jg-vehiclemileage'
    if GetResourceState(resource) ~= 'started' then
        return nil
    end

    local mileage
    if vehicle and vehicle ~= 0 then
        mileage = exports[resource]:getMileageByEntity(vehicle)
    elseif plate then
        mileage = exports[resource]:getMileageByPlate(plate)
    end

    if mileage == false or mileage == nil then
        return nil
    end

    local value = tonumber(mileage)
    if not value then
        return nil
    end

    return math.floor(value + 0.5)
end

local function buildOptions(list)
    local options = {}

    for i = 1, #list do
        options[#options + 1] = {
            value = list[i].value,
            label = locale(list[i].label)
        }
    end

    return options
end

local function runDialog(titleKey, fields)
    local inputs = {}

    for i = 1, #fields do
        inputs[i] = fields[i].input
    end

    local result = lib.inputDialog(locale(titleKey), inputs)
    if not result then
        return nil
    end

    local payload = {}
    for i = 1, #fields do
        payload[fields[i].key] = result[i]
    end

    return payload
end

local function openServiceDialog()
    local vehicle, plate = getVehicleTarget()
    local autoMileage
    if Config.UseMileage then
        autoMileage = getJgMileage(vehicle, plate)
    end

    local fields = {{
        key = 'plate',
        input = {
            type = 'input',
            label = locale('input_plate'),
            default = plate,
            required = true
        }
    }, {
        key = 'service_type',
        input = {
            type = 'select',
            label = locale('input_service_type'),
            options = buildOptions(Config.ServiceTypes),
            required = true
        }
    }, {
        key = 'custom_label',
        input = {
            type = 'input',
            label = locale('input_service_custom')
        }
    }}

    if Config.UseMileage then
        fields[#fields + 1] = {
            key = 'mileage',
            input = {
                type = 'number',
                label = locale('input_mileage'),
                default = autoMileage
            }
        }
    end

    fields[#fields + 1] = {
        key = 'notes',
        input = {
            type = 'textarea',
            label = locale('input_notes'),
            required = true
        }
    }

    fields[#fields + 1] = {
        key = 'job_label',
        input = {
            type = 'input',
            label = locale('input_job_label')
        }
    }

    local payload = runDialog('input_service_title', fields)
    if not payload then
        return
    end

    TriggerServerEvent(Shared.ServerEvents.AddService, payload)
end

local function openIncidentDialog()
    local plate = getVehiclePlate()

    local fields = {{
        key = 'plate',
        input = {
            type = 'input',
            label = locale('input_plate'),
            default = plate,
            required = true
        }
    }, {
        key = 'incident_type',
        input = {
            type = 'select',
            label = locale('input_incident_type'),
            options = buildOptions(Config.IncidentTypes),
            required = true
        }
    }, {
        key = 'custom_label',
        input = {
            type = 'input',
            label = locale('input_incident_custom')
        }
    }, {
        key = 'notes',
        input = {
            type = 'textarea',
            label = locale('input_notes'),
            required = true
        }
    }, {
        key = 'job_label',
        input = {
            type = 'input',
            label = locale('input_job_label')
        }
    }}

    local payload = runDialog('input_incident_title', fields)
    if not payload then
        return
    end

    TriggerServerEvent(Shared.ServerEvents.AddIncident, payload)
end

local function openOwnerDialog()
    local _, plate = getVehicleTarget()
    if not plate then
        local platePayload = runDialog('input_owner_plate_title', {{
            key = 'plate',
            input = {
                type = 'input',
                label = locale('input_plate'),
                required = true
            }
        }})

        if not platePayload then
            return
        end

        plate = platePayload.plate
    end

    local vinDefault
    if plate then
        local response = lib.callback.await(Shared.Callbacks.GetVin, false, plate)
        if response and response.ok then
            vinDefault = response.vin
        end
    end

    local fields = {{
        key = 'plate',
        input = {
            type = 'input',
            label = locale('input_plate'),
            default = plate,
            required = true
        }
    }, {
        key = 'vin',
        input = {
            type = 'input',
            label = locale('input_vin'),
            default = vinDefault
        }
    }, {
        key = 'registration_status',
        input = {
            type = 'select',
            label = locale('input_registration'),
            options = buildOptions(Config.RegistrationStatuses),
            required = true
        }
    }, {
        key = 'notes',
        input = {
            type = 'textarea',
            label = locale('input_notes')
        }
    }, {
        key = 'owner_identifier',
        input = {
            type = 'input',
            label = locale('input_owner_identifier')
        }
    }}

    local payload = runDialog('input_owner_title', fields)
    if not payload then
        return
    end

    TriggerServerEvent(Shared.ServerEvents.AddOwner, payload)
end

local function openVinLookup()
    local plate = getVehiclePlate()
    if not plate then
        local payload = runDialog('input_vin_title', {{
            key = 'plate',
            input = {
                type = 'input',
                label = locale('input_plate'),
                required = true
            }
        }})

        if not payload then
            return
        end

        plate = payload.plate
    end

    local response = lib.callback.await(Shared.Callbacks.GetVin, false, plate)
    if not response or not response.ok then
        local reason = response and response.reason
        if reason == 'rate_limited' then
            lib.notify({
                type = 'error',
                description = locale('notify_rate_limited')
            })
        elseif reason == 'invalid_plate' then
            lib.notify({
                type = 'error',
                description = locale('notify_invalid_plate')
            })
        elseif reason == 'not_found' then
            lib.notify({
                type = 'error',
                description = locale('notify_vin_not_found')
            })
        else
            lib.notify({
                type = 'error',
                description = locale('notify_vin_unavailable')
            })
        end

        return
    end

    lib.notify({
        description = string.format(locale('notify_vin_found'), response.vin)
    })
end

local function isResourceStarted(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

local function detectTargetSystem()
    if targetSystem then
        return targetSystem
    end

    local configured = Config.Target or 'auto'
    if configured ~= 'auto' then
        targetSystem = configured
        return targetSystem
    end

    if isResourceStarted('ox_target') then
        targetSystem = 'ox'
        return targetSystem
    end

    if isResourceStarted('qb-target') then
        targetSystem = 'qb'
        return targetSystem
    end

    targetSystem = 'none'
    return targetSystem
end

local function spawnPhysicalPed()
    if physicalPed and DoesEntityExist(physicalPed) then
        return physicalPed
    end

    local config = Config.PhysicalReport and Config.PhysicalReport.ped
    if not config or not config.coords or not config.model then
        return nil
    end

    local modelHash = type(config.model) == 'number' and config.model or joaat(config.model)
    lib.requestModel(modelHash)

    physicalPed = CreatePed(0, modelHash, config.coords.x, config.coords.y, config.coords.z, config.heading or 0.0, false, true)
    SetModelAsNoLongerNeeded(modelHash)
    SetEntityInvincible(physicalPed, true)
    FreezeEntityPosition(physicalPed, true)
    SetBlockingOfNonTemporaryEvents(physicalPed, true)

    if config.scenario then
        TaskStartScenarioInPlace(physicalPed, config.scenario, 0, true)
    end

    return physicalPed
end

local function createPhysicalZone()
    if physicalZone then
        return physicalZone
    end

    local zoneConfig = Config.PhysicalReport and Config.PhysicalReport.zone
    if not zoneConfig then
        return nil
    end

    local common = {
        debug = zoneConfig.debug or false,
        onEnter = function()
            isInPhysicalZone = true
        end,
        onExit = function()
            isInPhysicalZone = false
        end
    }

    if zoneConfig.type == 'sphere' then
        physicalZone = lib.zones.sphere({
            coords = zoneConfig.coords,
            radius = zoneConfig.radius or 2.0,
            debug = common.debug,
            onEnter = common.onEnter,
            onExit = common.onExit
        })
        return physicalZone
    end

    if zoneConfig.type == 'poly' then
        physicalZone = lib.zones.poly({
            points = zoneConfig.points or {},
            thickness = zoneConfig.thickness or 4.0,
            debug = common.debug,
            onEnter = common.onEnter,
            onExit = common.onExit
        })
        return physicalZone
    end

    physicalZone = lib.zones.box({
        coords = zoneConfig.coords,
        size = zoneConfig.size or vec3(2.0, 2.0, 2.0),
        rotation = zoneConfig.rotation or 0.0,
        debug = common.debug,
        onEnter = common.onEnter,
        onExit = common.onExit
    })

    return physicalZone
end

local function getVehicleLabel(vehicle)
    local model = GetEntityModel(vehicle)
    local display = GetDisplayNameFromVehicleModel(model)
    local label = GetLabelText(display)
    if not label or label == 'NULL' then
        return display
    end
    return label
end

local function getNearbyZoneVehicles()
    local config = Config.PhysicalReport
    if not config then
        return {}
    end

    local zoneConfig = config.zone or {}
    local anchor = zoneConfig.coords or (config.ped and config.ped.coords)
    if not anchor then
        return {}
    end

    local radius = config.searchRadius or 12.0
    local nearby = lib.getNearbyVehicles(anchor, radius, true)
    local vehicles = {}
    local seen = {}

    for i = 1, #nearby do
        local vehicle = nearby[i].vehicle
        local coords = nearby[i].coords

        if not (physicalZone and physicalZone.contains and not physicalZone:contains(coords)) then
            local plate = GetVehicleNumberPlateText(vehicle)
            plate = Shared.Utils.normalizePlate(plate) or plate
            if plate and plate ~= '' and not seen[plate] then
                seen[plate] = true
                vehicles[#vehicles + 1] = {
                    plate = plate,
                    label = getVehicleLabel(vehicle)
                }
            end
        end
    end

    table.sort(vehicles, function(a, b)
        return a.plate < b.plate
    end)

    return vehicles
end

local function openPhysicalMenu()
    if not Config.PhysicalReport or not Config.PhysicalReport.enabled then
        return
    end

    if not isInPhysicalZone then
        lib.notify({
            type = 'error',
            description = locale('notify_not_in_zone')
        })
        return
    end

    local vehicles = getNearbyZoneVehicles()
    if #vehicles == 0 then
        lib.notify({
            type = 'error',
            description = locale('notify_no_vehicles')
        })
        return
    end

    local price = tonumber(Config.PhysicalReport.price) or 0
    local options = {}

    for i = 1, #vehicles do
        local entry = vehicles[i]
        options[#options + 1] = {
            title = string.format(locale('menu_vehicle_entry'), entry.label, entry.plate),
            description = price > 0 and locale('menu_vehicle_price', price) or locale('menu_vehicle_free'),
            icon = 'fa-solid fa-car',
            onSelect = function()
                TriggerServerEvent(Shared.ServerEvents.RequestPhysicalReport, {
                    plate = entry.plate
                })
            end
        }
    end

    lib.registerContext({
        id = 'uiforge_carfax_physical',
        title = locale('menu_physical_title'),
        options = options
    })

    lib.showContext('uiforge_carfax_physical')
end

local function setupPhysicalStation()
    if not Config.PhysicalReport or not Config.PhysicalReport.enabled then
        return
    end

    createPhysicalZone()

    local ped = spawnPhysicalPed()
    if not ped then
        return
    end

    local targetConfig = Config.PhysicalReport.target or {}
    local label = locale(targetConfig.label or 'target_carfax_request')
    local icon = targetConfig.icon or 'fa-solid fa-file-lines'
    local distance = targetConfig.distance or 2.0

    local system = detectTargetSystem()
    if system == 'ox' then
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'carfax_physical',
                label = label,
                icon = icon,
                distance = distance,
                canInteract = function()
                    return isInPhysicalZone
                end,
                onSelect = function()
                    openPhysicalMenu()
                end
            }
        })
    elseif system == 'qb' then
        exports['qb-target']:AddTargetEntity(ped, {
            options = {
                {
                    icon = icon,
                    label = label,
                    action = function()
                        openPhysicalMenu()
                    end,
                    canInteract = function()
                        return isInPhysicalZone
                    end
                }
            },
            distance = distance
        })
    end
end

local function buildUiLocale()
    return {
        app_title = locale('app_title'),
        app_subtitle = locale('app_subtitle'),
        brand_label = locale('brand_label'),
        header_vin = locale('header_vin'),
        header_plate = locale('header_plate'),
        header_report_id = locale('header_report_id'),
        header_registration = locale('header_registration'),
        header_generated = locale('header_generated'),
        section_service = locale('section_service'),
        section_incident = locale('section_incident'),
        section_ownership = locale('section_ownership'),
        table_type = locale('table_type'),
        table_date = locale('table_date'),
        table_mileage = locale('table_mileage'),
        table_shop = locale('table_shop'),
        table_notes = locale('table_notes'),
        table_recorded_by = locale('table_recorded_by'),
        table_owner = locale('table_owner'),
        table_registration = locale('table_registration'),
        table_agency = locale('table_agency'),
        table_transfer_date = locale('table_transfer_date'),
        table_visibility = locale('table_visibility'),
        empty_service = locale('empty_service'),
        empty_incident = locale('empty_incident'),
        empty_ownership = locale('empty_ownership'),
        private_record = locale('private_record'),
        status_private = locale('status_private'),
        status_public = locale('status_public'),
        ui_close = locale('ui_close'),
        ui_page = locale('ui_page'),
        ui_prev_page = locale('ui_prev_page'),
        ui_next_page = locale('ui_next_page')
    }
end

local function openReport(forcedPlate)
    if isOpen then
        return
    end

    local plate = forcedPlate
    if not plate or plate == '' then
        plate = getVehiclePlate()
    end

    if not plate then
        local payload = runDialog('input_report_title', {{
            key = 'plate',
            input = {
                type = 'input',
                label = locale('input_plate'),
                required = true
            }
        }})

        if not payload then
            return
        end

        plate = payload.plate
    end

    lib.notify({
        description = locale('report_loading')
    })

    local response = lib.callback.await(Shared.Callbacks.GetReport, false, plate)
    if not response or not response.ok then
        local reason = response and response.reason
        if reason == 'rate_limited' then
            lib.notify({
                type = 'error',
                description = locale('notify_rate_limited')
            })
        elseif reason == 'invalid_plate' then
            lib.notify({
                type = 'error',
                description = locale('notify_invalid_plate')
            })
        elseif reason == 'not_found' then
            lib.notify({
                type = 'error',
                description = locale('report_not_found')
            })
        else
            lib.notify({
                type = 'error',
                description = locale('notify_report_unavailable')
            })
        end

        return
    end

    SendNUIMessage({
        type = 'open',
        locale = buildUiLocale(),
        report = response.data
    })

    SetNuiFocus(true, true)
    isOpen = true
end

local function closeReport()
    if not isOpen then
        return
    end

    SendNUIMessage({
        type = 'close'
    })
    SetNuiFocus(false, false)
    isOpen = false
end

RegisterNUICallback(Shared.NuiCallbacks.Close, function(_, cb)
    closeReport()
    cb({
        ok = true
    })
end)

RegisterNetEvent(Shared.Events.OpenServiceInput, function()
    openServiceDialog()
end)

RegisterNetEvent(Shared.Events.OpenIncidentInput, function()
    openIncidentDialog()
end)

RegisterNetEvent(Shared.Events.OpenOwnerInput, function()
    openOwnerDialog()
end)

RegisterNetEvent(Shared.Events.OpenReport, function(plate)
    openReport(plate)
end)

RegisterNetEvent(Shared.Events.OpenVinLookup, function()
    openVinLookup()
end)

RegisterNetEvent(Shared.Events.OpenPhysicalMenu, function()
    openPhysicalMenu()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    closeReport()

    if physicalPed and DoesEntityExist(physicalPed) then
        DeleteEntity(physicalPed)
        physicalPed = nil
    end

    if physicalZone and physicalZone.remove then
        physicalZone:remove()
        physicalZone = nil
    end
end)

CreateThread(function()
    setupPhysicalStation()
end)
