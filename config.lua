Config = {}

Config.Debug = false
Config.Target = 'auto' -- auto | ox | qb | none (E key fallback is always available)
Config.RequireOnDuty = true
Config.InteractDistance = 2.0
Config.TipDistance = 3.0
-- How close staff must be to any club pole to use the stage board
Config.ManageDistance = 55.0

-- Standing-at-pole coords are used as the scene origin. Tweak if a dancer sits
-- off the pole: positive Z lifts them, XY slides them on the floor.
-- Per-pole `offset` in the club poles table is added on top of this.
Config.PoleAlign = vector3(0.0, 0.0, 0.0)

-- Dancers automatically switch to a different pole routine so they are not clones.
Config.AnimationCycle = {
    enabled = true,
    minMs = 45000,
    maxMs = 90000,
}

-- In-game placement editor (/editdancers). Saved to SQL.
Config.Editor = {
    command = 'editdancers',
    maxDistanceFromPole = 12.0,
    moveSpeed = 0.018,
    slowSpeed = 0.005,
    fastSpeed = 0.055,
    rotSpeed = 1.2,
}

-- Stripper / low-clothing vanilla peds. Freemode entries use a bikini-style outfit.
-- outfit = { {component, drawable, texture}, ... }
Config.Dancers = {
    { model = 's_f_y_stripper_01',   label = 'Amber' },
    { model = 's_f_y_stripper_02',   label = 'Jade' },
    { model = 's_f_y_stripperlite',  label = 'Lola' },
    { model = 'csb_stripper_01',     label = 'Destiny' },
    { model = 'csb_stripper_02',     label = 'Chanel' },
    { model = 'a_f_y_topless_01',    label = 'Skye' },
    { model = 's_f_y_hooker_01',     label = 'Candy' },
    { model = 's_f_y_hooker_02',     label = 'Roxy' },
    { model = 's_f_y_hooker_03',     label = 'Trixie' },
    { model = 'a_f_y_beach_01',      label = 'Summer' },
    { model = 'a_f_y_beach_02',      label = 'Bree' },
    { model = 's_f_y_baywatch_01',   label = 'Bay' },
    { model = 'a_f_y_genhot_01',     label = 'Gigi' },
    { model = 'u_f_y_bikerchic',     label = 'Raven' },
    {
        model = 'mp_f_freemode_01',
        label = 'Ruby',
        blend = { 21, 45, 0.45 },
        hair = { 4, 0, 4, 3 },
        outfit = { { 2, 4, 0 }, { 3, 15, 0 }, { 4, 15, 0 }, { 6, 35, 0 }, { 8, 14, 0 }, { 11, 15, 0 } },
    },
    {
        model = 'mp_f_freemode_01',
        label = 'Nova',
        blend = { 25, 12, 0.4 },
        hair = { 10, 0, 1, 1 },
        outfit = { { 2, 10, 0 }, { 3, 15, 0 }, { 4, 15, 1 }, { 6, 5, 0 }, { 8, 14, 0 }, { 11, 15, 0 } },
    },
    {
        model = 'mp_f_freemode_01',
        label = 'Vixen',
        blend = { 6, 21, 0.55 },
        hair = { 15, 0, 27, 27 },
        outfit = { { 2, 15, 0 }, { 3, 15, 0 }, { 4, 21, 0 }, { 6, 35, 1 }, { 8, 3, 0 }, { 11, 18, 0 } },
    },
}

-- attach = 'scene' wraps the pole (correct look). attach = 'anim' plays on the spot.
Config.Routines = {
    pole = {
        { dict = 'mini@strip_club@pole_dance@pole_dance1', clip = 'pd_dance_01', label = 'Pole Spin', attach = 'scene' },
        { dict = 'mini@strip_club@pole_dance@pole_dance2', clip = 'pd_dance_02', label = 'Pole Climb', attach = 'scene' },
        { dict = 'mini@strip_club@pole_dance@pole_dance3', clip = 'pd_dance_03', label = 'Pole Floorwork', attach = 'scene' },
        { dict = 'mini@strip_club@private_dance@part1', clip = 'priv_dance_p1', label = 'Stage Tease 1', attach = 'anim' },
        { dict = 'mini@strip_club@private_dance@part2', clip = 'priv_dance_p2', label = 'Stage Tease 2', attach = 'anim' },
        { dict = 'mini@strip_club@private_dance@part3', clip = 'priv_dance_p3', label = 'Stage Tease 3', attach = 'anim' },
        { dict = 'mini@strip_club@private_dance@idle', clip = 'priv_dance_idle', label = 'Idle Tease', attach = 'anim' },
        { dict = 'anim@amb@nightclub@mini@dance@dance_solo@female@var_a@', clip = 'high_center', label = 'Club Solo A', attach = 'anim' },
        { dict = 'anim@amb@nightclub@mini@dance@dance_solo@female@var_b@', clip = 'high_center', label = 'Club Solo B', attach = 'anim' },
        { dict = 'anim@amb@nightclub@mini@dance@dance_solo@female@var_a@', clip = 'med_center', label = 'Club Groove', attach = 'anim' },
    },
    platform = {
        { dict = 'mini@strip_club@private_dance@part1', clip = 'priv_dance_p1', label = 'Floor Routine 1', attach = 'anim' },
        { dict = 'mini@strip_club@private_dance@part2', clip = 'priv_dance_p2', label = 'Floor Routine 2', attach = 'anim' },
        { dict = 'mini@strip_club@private_dance@part3', clip = 'priv_dance_p3', label = 'Floor Routine 3', attach = 'anim' },
        { dict = 'mini@strip_club@private_dance@idle', clip = 'priv_dance_idle', label = 'Tease Idle', attach = 'anim' },
        { dict = 'anim@amb@nightclub@mini@dance@dance_solo@female@var_a@', clip = 'high_center', label = 'Club Solo A', attach = 'anim' },
        { dict = 'anim@amb@nightclub@mini@dance@dance_solo@female@var_b@', clip = 'high_center', label = 'Club Solo B', attach = 'anim' },
        { dict = 'anim@amb@nightclub@mini@dance@dance_solo@female@var_a@', clip = 'med_center', label = 'Club Groove', attach = 'anim' },
    },
}

Config.Tips = {
    amounts = { 20, 50, 100, 500, 1000 },
    allowCustom = true,
    min = 5,
    max = 5000,
    cooldown = 4,
}

-- 17.5% of washed dirty money is deposited to the club job account in Renewed Banking.
-- The guest receives the remaining 82.5% as clean pocket cash.
Config.Wash = {
    enabled = true,
    feePercent = 17.5,
    -- self: guests use the club desk
    -- employee: staff count a nearby guest's dirty money
    -- both: desk + staff-on-guest
    mode = 'both',
    min = 100,
    max = 250000,
    cooldown = 20,
    progressMsPerThousand = 400,
    progressMin = 3500,
    progressMax = 18000,
}

Config.Cash = {
    -- auto: ox_inventory "money" item when that resource is running, otherwise framework cash
    method = 'auto',
    oxItem = 'money',
    qbAccount = 'cash',
    esxAccount = 'money',
}

-- Dirty / marked money. "auto" picks the first source the player actually has.
Config.DirtyMoney = {
    method = 'auto', -- auto | item | account
    item = 'markedbills',
    altItem = 'black_money',
    useWorth = true,
    account = 'black_money',
}

Config.Banking = {
    resource = 'Renewed-Banking',
    washTitle = 'Dirty Money Wash',
    tipTitle = 'Stage Tips',
}

Config.Clubs = {
    vanillaunicorn = {
        enabled = true,
        label = 'Vanilla Unicorn',
        account = 'vanillaunicorn',
        jobs = {
            vanillaunicorn = 0,
        },
        washGrade = 0,
        blip = {
            enabled = true,
            coords = vector3(-705.04, -712.28, 30.17),
            sprite = 121,
            color = 8,
            scale = 0.8,
            label = 'Vanilla Unicorn',
        },
        -- Coords taken while standing on each pole. Scene origin uses these plus PoleAlign.
        poles = {
            { coords = vector3(-712.95, -705.11, 30.17), heading = 0.0, style = 'pole', label = 'Pole 1 · Lower West' },
            { coords = vector3(-703.12, -709.49, 30.17), heading = 0.0, style = 'pole', label = 'Pole 2 · Lower East' },
            { coords = vector3(-679.94, -696.96, 35.08), heading = 0.0, style = 'pole', label = 'Pole 3 · Upper East 1' },
            { coords = vector3(-679.85, -703.98, 35.08), heading = 0.0, style = 'pole', label = 'Pole 4 · Upper East 2' },
            { coords = vector3(-679.87, -710.84, 35.08), heading = 0.0, style = 'pole', label = 'Pole 5 · Upper East 3' },
            { coords = vector3(-679.86, -717.88, 35.08), heading = 0.0, style = 'pole', label = 'Pole 6 · Upper East 4' },
            { coords = vector3(-695.54, -722.07, 35.28), heading = 0.0, style = 'pole', label = 'Pole 7 · Upper South 1' },
            { coords = vector3(-703.24, -722.14, 35.28), heading = 0.0, style = 'pole', label = 'Pole 8 · Upper South 2' },
            { coords = vector3(-710.97, -722.08, 35.28), heading = 0.0, style = 'pole', label = 'Pole 9 · Upper South 3' },
        },
        -- Move this to your office / cashier if it is in a wall.
        wash = {
            coords = vector3(-717.50, -705.10, 30.17),
            radius = 1.2,
            label = 'Count Dirty Money',
        },
    },
}

-- Groups that can always manage stages (framework group / permission name).
Config.AdminGroups = {
    'god',
    'admin',
    'superadmin',
}
