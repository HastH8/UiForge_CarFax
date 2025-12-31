Shared = Shared or {}

Shared.Resource = GetCurrentResourceName()

Shared.Events = {
    OpenServiceInput = Shared.Resource .. ':openServiceInput',
    OpenIncidentInput = Shared.Resource .. ':openIncidentInput',
    OpenOwnerInput = Shared.Resource .. ':openOwnerInput',
    OpenReport = Shared.Resource .. ':openReport',
    OpenVinLookup = Shared.Resource .. ':openVinLookup',
    OpenPhysicalMenu = Shared.Resource .. ':openPhysicalMenu',
    Notify = Shared.Resource .. ':notify'
}

Shared.ServerEvents = {
    AddService = Shared.Resource .. ':addService',
    AddIncident = Shared.Resource .. ':addIncident',
    AddOwner = Shared.Resource .. ':addOwner',
    RequestPhysicalReport = Shared.Resource .. ':requestPhysicalReport',
    DebugSeed = Shared.Resource .. ':debugSeed'
}

Shared.Callbacks = {
    GetReport = Shared.Resource .. ':getReport',
    GetVin = Shared.Resource .. ':getVin'
}

Shared.NuiCallbacks = {
    Close = Shared.Resource .. ':close',
    Ready = Shared.Resource .. ':ready'
}
