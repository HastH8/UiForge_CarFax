local isOpen = false

local function getVehiclePlate()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        local hit, entity = lib.raycast.fromCamera()
        if hit and entity and IsEntityAVehicle(entity) then
            vehicle = entity
        end
    end

    if vehicle ~= 0 then
        return GetVehicleNumberPlateText(vehicle)
    end

    return nil
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
    local plate = getVehiclePlate()

    local fields = {
        {
            key = 'plate',
            input = {
                type = 'input',
                label = locale('input_plate'),
                default = plate,
                required = true
            }
        },
        {
            key = 'service_type',
            input = {
                type = 'select',
                label = locale('input_service_type'),
                options = buildOptions(Config.ServiceTypes),
                required = true
            }
        },
        {
            key = 'custom_label',
            input = {
                type = 'input',
                label = locale('input_service_custom')
            }
        }
    }

    if Config.UseMileage then
        fields[#fields + 1] = {
            key = 'mileage',
            input = {
                type = 'number',
                label = locale('input_mileage')
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

    local fields = {
        {
            key = 'plate',
            input = {
                type = 'input',
                label = locale('input_plate'),
                default = plate,
                required = true
            }
        },
        {
            key = 'incident_type',
            input = {
                type = 'select',
                label = locale('input_incident_type'),
                options = buildOptions(Config.IncidentTypes),
                required = true
            }
        },
        {
            key = 'custom_label',
            input = {
                type = 'input',
                label = locale('input_incident_custom')
            }
        },
        {
            key = 'notes',
            input = {
                type = 'textarea',
                label = locale('input_notes'),
                required = true
            }
        },
        {
            key = 'job_label',
            input = {
                type = 'input',
                label = locale('input_job_label')
            }
        }
    }

    local payload = runDialog('input_incident_title', fields)
    if not payload then
        return
    end

    TriggerServerEvent(Shared.ServerEvents.AddIncident, payload)
end

local function openOwnerDialog()
    local plate = getVehiclePlate()

    local fields = {
        {
            key = 'plate',
            input = {
                type = 'input',
                label = locale('input_plate'),
                default = plate,
                required = true
            }
        },
        {
            key = 'vin',
            input = {
                type = 'input',
                label = locale('input_vin')
            }
        },
        {
            key = 'registration_status',
            input = {
                type = 'select',
                label = locale('input_registration'),
                options = buildOptions(Config.RegistrationStatuses),
                required = true
            }
        },
        {
            key = 'notes',
            input = {
                type = 'textarea',
                label = locale('input_notes')
            }
        },
        {
            key = 'owner_identifier',
            input = {
                type = 'input',
                label = locale('input_owner_identifier')
            }
        }
    }

    local payload = runDialog('input_owner_title', fields)
    if not payload then
        return
    end

    TriggerServerEvent(Shared.ServerEvents.AddOwner, payload)
end

local function openVinLookup()
    local plate = getVehiclePlate()
    if not plate then
        local payload = runDialog('input_vin_title', {
            {
                key = 'plate',
                input = {
                    type = 'input',
                    label = locale('input_plate'),
                    required = true
                }
            }
        })

        if not payload then
            return
        end

        plate = payload.plate
    end

    local response = lib.callback.await(Shared.Callbacks.GetVin, false, plate)
    if not response or not response.ok then
        local reason = response and response.reason
        if reason == 'rate_limited' then
            lib.notify({ type = 'error', description = locale('notify_rate_limited') })
        elseif reason == 'invalid_plate' then
            lib.notify({ type = 'error', description = locale('notify_invalid_plate') })
        elseif reason == 'not_found' then
            lib.notify({ type = 'error', description = locale('notify_vin_not_found') })
        else
            lib.notify({ type = 'error', description = locale('notify_vin_unavailable') })
        end

        return
    end

    lib.notify({
        description = string.format(locale('notify_vin_found'), response.vin)
    })
end

local function buildUiLocale()
    return {
        app_title = locale('app_title'),
        app_subtitle = locale('app_subtitle'),
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
        ui_page = locale('ui_page')
    }
end

local function openReport()
    if isOpen then
        return
    end

    local plate = getVehiclePlate()
    if not plate then
        local payload = runDialog('input_report_title', {
            {
                key = 'plate',
                input = {
                    type = 'input',
                    label = locale('input_plate'),
                    required = true
                }
            }
        })

        if not payload then
            return
        end

        plate = payload.plate
    end

    lib.notify({ description = locale('report_loading') })

    local response = lib.callback.await(Shared.Callbacks.GetReport, false, plate)
    if not response or not response.ok then
        local reason = response and response.reason
        if reason == 'rate_limited' then
            lib.notify({ type = 'error', description = locale('notify_rate_limited') })
        elseif reason == 'invalid_plate' then
            lib.notify({ type = 'error', description = locale('notify_invalid_plate') })
        elseif reason == 'not_found' then
            lib.notify({ type = 'error', description = locale('report_not_found') })
        else
            lib.notify({ type = 'error', description = locale('notify_report_unavailable') })
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

    SendNUIMessage({ type = 'close' })
    SetNuiFocus(false, false)
    isOpen = false
end

RegisterNUICallback(Shared.NuiCallbacks.Close, function(_, cb)
    closeReport()
    cb({ ok = true })
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

RegisterNetEvent(Shared.Events.OpenReport, function()
    openReport()
end)

RegisterNetEvent(Shared.Events.OpenVinLookup, function()
    openVinLookup()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    closeReport()
end)
