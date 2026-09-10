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

-- Premium vanilla female peds (story / DLC). No s_f_y_stripper / stripperlite models.
Config.Dancers = {
    { model = 'u_f_y_hotposh_01',        label = 'Vivienne' },
    { model = 'ig_kerrymcintosh_02',     label = 'Kerry' },
    { model = 'ig_kerrymcintosh',        label = 'Kerry (Classic)' },
    { model = 'u_f_y_poppymich_02',      label = 'Poppy' },
    { model = 'u_f_y_poppymich',         label = 'Poppy (Classic)' },
    { model = 'a_f_y_clubcust_04',       label = 'Aria' },
    { model = 'a_f_y_clubcust_03',       label = 'Noelle' },
    { model = 'a_f_y_clubcust_02',       label = 'Mia' },
    { model = 'a_f_y_clubcust_01',       label = 'Sienna' },
    { model = 'a_f_y_bevhills_04',       label = 'Brooke' },
    { model = 'a_f_y_vinewood_04',       label = 'Luna' },
    { model = 'mp_f_execpa_01',          label = 'Scarlett' },
    { model = 'mp_f_execpa_02',          label = 'Elena' },
    { model = 'u_f_y_jewelass_01',       label = 'Jewel' },
    { model = 'ig_tracydisanto',         label = 'Tracy' },
    { model = 'a_f_y_smartcaspat_01',    label = 'Cassandra' },
    { model = 'ig_jackie',               label = 'Jackie' },
    { model = 'a_f_y_genhot_01',         label = 'Gigi' },
    { model = 'u_f_y_bikerchic',         label = 'Raven' },
    { model = 's_f_y_clubbar_01',        label = 'Nikki' },
    { model = 'a_f_y_bevhills_01',       label = 'Claire' },
    { model = 'ig_natalia',              label = 'Natalia' },
    { model = 'u_f_y_spyactress',        label = 'Iris' },
    { model = 'a_f_y_femaleagent',       label = 'Agent Fox' },
    { model = 'a_f_y_carclub_01',        label = 'Tessa' },
    { model = 's_f_y_casino_01',         label = 'Diamond' },
    { model = 'ig_tonya',                label = 'Tonya' },
    { model = 'a_f_y_hipster_02',        label = 'Harper' },
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
