Server = Server or {}
Server.DB = Server.DB or {}

local DB = Server.DB
local Utils = Shared.Utils

local function now()
    return os.time()
end

local function scalar(query, params)
    return MySQL.scalar.await(query, params)
end

local function query(queryText, params)
    return MySQL.query.await(queryText, params)
end

local function insert(queryText, params)
    return MySQL.insert.await(queryText, params)
end

local function update(queryText, params)
    return MySQL.update.await(queryText, params)
end

local function generateUnique(field, generator)
    for _ = 1, 5 do
        local value = generator()
        local exists = scalar(('SELECT 1 FROM carfax_vehicles WHERE %s = ? LIMIT 1'):format(field), { value })
        if not exists then
            return value
        end
    end

    return generator()
end

function DB.GetVehicleByPlate(plate)
    return MySQL.single.await('SELECT * FROM carfax_vehicles WHERE plate = ? LIMIT 1', { plate })
end

function DB.GetVehicleByVin(vin)
    return MySQL.single.await('SELECT * FROM carfax_vehicles WHERE vin = ? LIMIT 1', { vin })
end

function DB.EnsureVehicle(plate, vin, registrationStatus)
    local vehicle = DB.GetVehicleByPlate(plate)
    local currentTime = now()

    if vehicle then
        local needsUpdate = false
        local updateVin = vehicle.vin
        local updateStatus = vehicle.registration_status

        if vin and vehicle.vin ~= vin then
            updateVin = vin
            needsUpdate = true
        end

        if registrationStatus and vehicle.registration_status ~= registrationStatus then
            updateStatus = registrationStatus
            needsUpdate = true
        end

        if needsUpdate then
            update('UPDATE carfax_vehicles SET vin = ?, registration_status = ?, updated_at = ? WHERE id = ?', {
                updateVin,
                updateStatus,
                currentTime,
                vehicle.id
            })

            vehicle.vin = updateVin
            vehicle.registration_status = updateStatus
            vehicle.updated_at = currentTime
        end

        return vehicle
    end

    local resolvedVin = vin or generateUnique('vin', Utils.generateVin)
    local reportId = generateUnique('report_id', Utils.generateReportId)
    local status = registrationStatus or Config.DefaultRegistrationStatus

    local inserted = insert('INSERT INTO carfax_vehicles (plate, vin, report_id, registration_status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)', {
        plate,
        resolvedVin,
        reportId,
        status,
        currentTime,
        currentTime
    })

    if not inserted then
        return nil
    end

    return DB.GetVehicleByPlate(plate)
end

function DB.AddServiceRecord(vehicleId, data)
    return insert('INSERT INTO carfax_service_records (vehicle_id, service_type, custom_label, notes, job_label, author_identifier, created_at, mileage) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        vehicleId,
        data.service_type,
        data.custom_label,
        data.notes,
        data.job_label,
        data.author_identifier,
        data.created_at,
        data.mileage
    })
end

function DB.AddIncidentRecord(vehicleId, data)
    return insert('INSERT INTO carfax_incident_records (vehicle_id, incident_type, custom_label, notes, job_label, author_identifier, created_at, is_private) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        vehicleId,
        data.incident_type,
        data.custom_label,
        data.notes,
        data.job_label,
        data.author_identifier,
        data.created_at,
        data.is_private
    })
end

function DB.AddOwnerRecord(vehicleId, data)
    return insert('INSERT INTO carfax_ownerships (vehicle_id, owner_index, owner_identifier, author_identifier, registration_status, notes, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        vehicleId,
        data.owner_index,
        data.owner_identifier,
        data.author_identifier,
        data.registration_status,
        data.notes,
        data.created_at
    })
end

function DB.GetNextOwnerIndex(vehicleId)
    local count = scalar('SELECT COUNT(1) FROM carfax_ownerships WHERE vehicle_id = ?', { vehicleId })
    return (count or 0) + 1
end

function DB.UpdateVehicleRegistration(vehicleId, status)
    return update('UPDATE carfax_vehicles SET registration_status = ?, updated_at = ? WHERE id = ?', {
        status,
        now(),
        vehicleId
    })
end

function DB.GetReportByPlate(plate)
    local vehicle = DB.GetVehicleByPlate(plate)
    if not vehicle then
        return nil
    end

    local services = query('SELECT id, service_type, custom_label, notes, job_label, author_identifier, created_at, mileage FROM carfax_service_records WHERE vehicle_id = ? ORDER BY created_at DESC, id DESC', { vehicle.id })
    local incidents = query('SELECT id, incident_type, custom_label, notes, job_label, author_identifier, created_at, is_private FROM carfax_incident_records WHERE vehicle_id = ? ORDER BY created_at DESC, id DESC', { vehicle.id })
    local owners = query('SELECT id, owner_index, owner_identifier, author_identifier, registration_status, notes, created_at FROM carfax_ownerships WHERE vehicle_id = ? ORDER BY owner_index ASC, id ASC', { vehicle.id })

    return {
        vehicle = vehicle,
        services = services or {},
        incidents = incidents or {},
        owners = owners or {}
    }
end
