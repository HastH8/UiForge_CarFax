# UiForge_CarFax

UiForge_CarFax is a CarFax-style vehicle history system for FiveM. It stores long-term vehicle service, incident, and ownership records and renders them as a print-ready report inside a document-style NUI.

## Features
- Service records with shop label, notes, optional mileage, and timestamps
- Incident records with privacy support for restricted entries
- Ownership history with registration status changes
- Persistent VIN, plate, and report ID per vehicle
- Clean, document-style multi-page NUI report
- Fully localized with ox_lib locale files
- Multi-framework bridge for QBox, QBCore, and ESX
- Server-side validation and rate limiting

## Dependencies
- ox_lib (required)
- oxmysql (required)
- QBox, QBCore, or ESX (one)

## Installation
1. Copy `UiForge_CarFax` into your server resources folder.
2. Import `sql/uiforge_carfax.sql` into your database.
3. Add to your server.cfg:

```
ensure ox_lib
ensure oxmysql
ensure UiForge_CarFax
```

4. Configure `config.lua` for jobs, labels, and report settings.

## Commands
- `/servicecar` (mechanic jobs)
- `/incident` (police jobs)
- `/owneredit` (dmv jobs)
- `/carfax` (everyone)
- `/vin` (everyone)

## Exports

### AddService

```lua
local ok, err = exports['UiForge_CarFax']:AddService('ABC123', {
    service_type = 'oil_change',
    notes = 'Oil and filter replaced.',
    job_label = 'Hayes Autos',
    mileage = 41250,
    vin = '1A2B3C4D5E6F7G8H9'
})
```

### AddIncident

```lua
local ok, err = exports['UiForge_CarFax']:AddIncident('ABC123', {
    incident_type = 'impound',
    notes = 'Vehicle held for evidence.',
    job_label = 'Vespucci PD'
})
```

### AddOwnerChange

```lua
local ok, err = exports['UiForge_CarFax']:AddOwnerChange('ABC123', {
    registration_status = 'valid',
    notes = 'Title transferred and registration renewed.'
})
```

### GetReport

```lua
local report = exports['UiForge_CarFax']:GetReport('ABC123')
if report then
    print(report.vehicle.vin)
end
```

Exports return `true` on success or `false, errorKey` when validation fails.

## Localization
All user-facing text is stored in `locales/en.json`. Add additional locales under `locales/` and set `setr ox:locale <code>` in your server.cfg.

## Debug
Enable verbose logs by setting `Config.Debug = true` in `config.lua`.

## Screenshots
![Screenshot placeholder](screenshots/placeholder.png)

## License
MIT. See `LICENSE`.
