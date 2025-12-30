Shared = Shared or {}

Shared.Resource = GetCurrentResourceName()

Shared.Events = {
    OpenServiceInput = Shared.Resource .. ':openServiceInput',
    OpenIncidentInput = Shared.Resource .. ':openIncidentInput',
    OpenOwnerInput = Shared.Resource .. ':openOwnerInput',
    OpenReport = Shared.Resource .. ':openReport',
    Notify = Shared.Resource .. ':notify'
}

Shared.ServerEvents = {
    AddService = Shared.Resource .. ':addService',
    AddIncident = Shared.Resource .. ':addIncident',
    AddOwner = Shared.Resource .. ':addOwner'
}

Shared.Callbacks = {
    GetReport = Shared.Resource .. ':getReport'
}

Shared.NuiCallbacks = {
    Close = Shared.Resource .. ':close',
    Ready = Shared.Resource .. ':ready'
}
