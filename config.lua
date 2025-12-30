Config = {}

Config.Framework = 'auto' -- auto | qb | qbox | esx
Config.Debug = false -- Enable debug logging
Config.RateLimitMs = 1500 -- Rate limit for CarFax requests per player

Config.UseMileage = true -- Enable mileage tracking
Config.PlateMaxLength = 12 -- Maximum length for vehicle plates
Config.VinLength = 17 -- Length for vehicle VINs
Config.DefaultRegistrationStatus = 'valid' -- Default registration status for vehicles
Config.ReportIdPattern = 'CARFAX-AAAA-111111' -- Pattern for report IDs (A=letter, 1=number)
Config.VinPattern = 'AAAAAAAAA111111111' -- Pattern for VINs (A=letter, 1=number)

Config.AdminGroups = {'admin', 'god'} -- Admin groups for accessing all reports
Config.AdminAce = 'uiforge.carfax' -- Admin ACE permission 

Config.Commands = { -- Command configurations
    service = {
        name = 'servicecar', -- Command name
        job = {
            mechanic = 0
        }, -- Job restrictions (job name = min grade)
        description = 'command_service_description' -- Description key for localization
    },
    incident = {
        name = 'incident',
        job = {
            police = 0
        },
        description = 'command_incident_description'
    },
    owneredit = {
        name = 'owneredit',
        job = {
            dmv = 0
        },
        description = 'command_owner_description'
    },
    carfax = {
        name = 'carfax',
        job = nil,
        description = 'command_carfax_description'
    }
}

Config.JobLabels = { -- Job label localization keys
    mechanic = 'job_label_mechanic',
    police = 'job_label_police',
    dmv = 'job_label_dmv'
}

Config.ServiceTypes = { -- Service type options
{
    value = 'oil_change',
    label = 'service_type_oil_change'
}, {
    value = 'engine_repair',
    label = 'service_type_engine_repair'
}, {
    value = 'body_repair',
    label = 'service_type_body_repair'
}, {
    value = 'full_inspection',
    label = 'service_type_full_inspection'
}, {
    value = 'custom',
    label = 'service_type_custom'
}}

Config.IncidentTypes = { -- Incident type options
{
    value = 'insurance_claim',
    label = 'incident_type_insurance_claim',
    private = false
}, {
    value = 'impound',
    label = 'incident_type_impound',
    private = false
}, {
    value = 'total_loss',
    label = 'incident_type_total_loss',
    private = false
}, {
    value = 'police_seizure',
    label = 'incident_type_police_seizure',
    private = false
}, {
    value = 'stolen_report',
    label = 'incident_type_stolen_report',
    private = true
}}

Config.RegistrationStatuses = { -- Registration status options
{
    value = 'valid',
    label = 'registration_valid'
}, {
    value = 'expired',
    label = 'registration_expired'
}, {
    value = 'suspended',
    label = 'registration_suspended'
}, {
    value = 'revoked',
    label = 'registration_revoked'
}}

Config.ReportVisibility = { -- Report visibility settings
    showIdentifiers = {
        mechanic = true,
        police = true,
        dmv = true
    },
    showPrivateIncidents = {
        police = true,
        dmv = true
    }
}

Config.TextLimits = { -- Text field character limits
    notes = 240,
    customLabel = 48,
    jobLabel = 48
}
