# UiForge_CarFax

![Screenshot placeholder](https://r2.fivemanage.com/BCQqhoUGE4iJJtYTuUBTA/Group7.png)

UiForge_CarFax is a CarFax-style vehicle history system for FiveM. It stores long-term vehicle service, incident, and ownership records and renders them as a print-ready report inside a document-style NUI.

## Features

- Service records with shop label, notes, optional mileage, and timestamps
- Incident records with privacy support for restricted entries
- Ownership history with registration status changes
- Persistent VIN, plate, and report ID per vehicle
- Clean, document-style multi-page NUI report
- Fully localized with ox_lib locale files
- Multi-framework bridge for QBox, QBCore, and ESX
- Optional jg-vehiclemileage integration for automatic mileage capture
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

## Physical Report Desk

Enable the report desk in `config.lua` to spawn a clerk ped and target interaction. Players can request a physical report for vehicles parked in the zone.

- Requires `ox_target` or `qb-target` for interaction.
- Item handling is routed through `bridge/server.lua` so custom inventories can be added easily.
- `Config.Target` supports `auto`, `ox`, `qb`, or `none`.
- `Config.Inventory` supports `auto` or a custom bridge implementation.

### ox_inventory item

Add the item to `ox_inventory/data/items.lua`:

```lua
['carfax_report'] = {
    label = 'CarFax Report',
    weight = 0,
    consume = 0,
    stack = false
}
```

Metadata is attached automatically (`plate`, `vin`, `report_id`, `label`, `description`) and used when opening the report.

## Exports

### AddService

```lua
exports['UiForge_CarFax']:AddService(plate, data)
```

Example:

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
exports['UiForge_CarFax']:AddIncident(plate, data)
```

Example:

```lua
local ok, err = exports['UiForge_CarFax']:AddIncident('ABC123', {
    incident_type = 'impound',
    notes = 'Vehicle held for evidence.',
    job_label = 'Vespucci PD'
})
```

### AddOwnerChange

```lua
exports['UiForge_CarFax']:AddOwnerChange(plate, data)
```

Example:

```lua
local ok, err = exports['UiForge_CarFax']:AddOwnerChange('ABC123', {
    registration_status = 'valid',
    notes = 'Title transferred and registration renewed.'
})
```

### GetReport

```lua
exports['UiForge_CarFax']:AddOwnerChange(plate)
```

Example:

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

## Preview

[Video](https://youtu.be/4d7RcKxo0xA)

### Screenshots

| Service Car                                                                                             | Incident Report                                                                                             | Owner Transfer                                                                                         |
| ------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| ![Service Car](https://r2.fivemanage.com/BCQqhoUGE4iJJtYTuUBTA/Screenshot2025-12-30at4.26.37PM.png)     | ![Incident Report](https://r2.fivemanage.com/BCQqhoUGE4iJJtYTuUBTA/Screenshot2025-12-30at4.27.23PM.png)     | ![Owner Transfer](https://r2.fivemanage.com/BCQqhoUGE4iJJtYTuUBTA/Screenshot2025-12-30at4.28.24PM.png) |
| Carfax One Page                                                                                         | CarFax Onepage Full                                                                                         | CarFax 2 Page                                                                                          |
| ![Carfax One Page](https://r2.fivemanage.com/BCQqhoUGE4iJJtYTuUBTA/Screenshot2025-12-30at4.28.40PM.png) | ![CarFax Onepage Full](https://r2.fivemanage.com/BCQqhoUGE4iJJtYTuUBTA/Screenshot2025-12-30at4.29.06PM.png) | ![CarFax 2 Page](https://r2.fivemanage.com/BCQqhoUGE4iJJtYTuUBTA/Screenshot2025-12-30at4.29.27PM.png)  |

## License

MIT. See `LICENSE`.
