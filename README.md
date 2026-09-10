# djfivem_dancers

FiveM club resource for **Vanilla Unicorn** (and an optional nightclub) that lets on-duty club staff put high-quality female dancers on poles, lets guests throw cash at the stage, and lets people wash dirty money at the club for a **17.5% business cut** deposited through **Renewed Banking**.

## Features

- Job-locked **stage control**: place, swap, change routine, or remove dancers
- Premium vanilla female peds (Kerry, Poppy, Hot Posh, After Hours club customers, etc.) — not `s_f_y_stripper_*`
- Pole dances plus VIP-room / nightclub floor routines
- Throw cash at a dancer (preset or custom) with raining-cash effects
- Tips go to the club **Renewed Banking** job account
- Dirty → clean wash: club keeps **17.5%**, guest receives **82.5%** clean cash
- Self-service wash desk **or** staff counting a nearby guest’s dirty money
- ox_lib menus, ox_target / qb-target, QBCore / Qbox / ESX, ox_inventory or qb-inventory
- Vanilla Unicorn **or Gabz** pole coordinates via one config flag

## Requirements

- [ox_lib](https://github.com/overextended/ox_lib)
- [Renewed-Banking](https://github.com/Renewed-Scripts/Renewed-Banking)
- ox_target **or** qb-target (optional — E-key fallback is included)
- qb-core, qbx_core, or es_extended

## Install

1. Drop this folder into `resources` as `djfivem_dancers`
2. Add to `server.cfg` **after** ox_lib, your framework, inventory, target, and Renewed-Banking:

```cfg
ensure ox_lib
ensure ox_target
ensure Renewed-Banking
ensure djfivem_dancers
```

3. Create the club job if you do not already have one (QBCore / Qbox `jobs.lua`):

```lua
unicorn = {
    label = 'Vanilla Unicorn',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Employee', payment = 50 },
        ['1'] = { name = 'Host', payment = 75 },
        ['2'] = { name = 'Manager', payment = 100, bankAuth = true },
        ['3'] = { name = 'Owner', isboss = true, payment = 150, bankAuth = true },
    },
},
```

`bankAuth = true` is what Renewed Banking uses so bosses can see the club account. The job name (`unicorn`) **must** match `Config.Clubs.unicorn.account`.

4. Open `config.lua`:
   - Set `Config.UnicornMLO = 'gabz'` if you use Gabz Vanilla Unicorn
   - Point `Config.Clubs.*.jobs` at your real job names
   - Adjust pole / wash coordinates if you use a different MLO

## Dirty money

`Config.DirtyMoney.method = 'auto'` uses the first source the player actually has:

| Server | Typical dirty money | Config if auto is wrong |
| --- | --- | --- |
| Qbox + ox_inventory | `black_money` item (count = dollars) | `item = 'black_money'`, `useWorth = false` |
| QBCore + marked bills | `markedbills` with `info.worth` / `metadata.worth` | `item = 'markedbills'`, `useWorth = true` |
| ESX | `black_money` account | `method = 'account'` |

Clean cash is added as ox_inventory `money` when ox_inventory is running, otherwise framework cash.

## How it plays

**Staff (unicorn job, on duty)**  
Target a pole → Stage Control → pick a dancer and routine.

**Guests**  
Target the dancer or pole → Throw Money. Cash comes from pocket money and is deposited to the club account.

**Wash**  
Use the office desk (default VU office) to wash your own dirty money, or staff can use **Count Their Dirty Money** on a nearby guest. The guest confirms. Example: `$10,000` dirty → **$1,750** to the Unicorn account, **$8,250** clean cash back.

Fee percent is `Config.Wash.feePercent` (default `17.5`).

## Adding another club

Copy a club entry in `Config.Clubs`. Set `account` to that job’s name, add pole coords (`style = 'pole'` or `'platform'`), and a wash desk. Staff jobs are listed under `jobs`.

```lua
bahama = {
    label = 'Bahama Mamas',
    account = 'bahama',
    jobs = { bahama = 0 },
    washGrade = 0,
    poles = {
        { coords = vector3(0.0, 0.0, 0.0), heading = 0.0, style = 'pole', label = 'Main Stage' },
    },
    wash = { coords = vector3(0.0, 0.0, 0.0), radius = 1.2, label = 'Count Dirty Money' },
},
```

## Commands

- `/cleardancers` — admin / console, clears every staged dancer

## Notes

- Dancers are local peds synced from the server (reliable animations, no extra network peds)
- If a model is missing from your game build it is skipped; pick another dancer
- Wash and tip amounts are validated on the server (distance, cooldown, balances)
