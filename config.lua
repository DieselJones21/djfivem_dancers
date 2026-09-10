Config = {}

-- 'vanilla' uses the default Vanilla Unicorn interior.
-- 'gabz' uses the common Gabz Vanilla Unicorn pole positions.
Config.UnicornMLO = 'vanilla'

Config.Debug = false
Config.Target = 'auto' -- auto | ox | qb | none (E key fallback is always available)
Config.RequireOnDuty = true
Config.InteractDistance = 2.0
Config.TipDistance = 3.0

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

Config.Routines = {
    pole = {
        { dict = 'mini@strip_club@pole_dance@pole_dance1', clip = 'pd_dance_01', label = 'Pole Routine 1' },
        { dict = 'mini@strip_club@pole_dance@pole_dance2', clip = 'pd_dance_02', label = 'Pole Routine 2' },
        { dict = 'mini@strip_club@pole_dance@pole_dance3', clip = 'pd_dance_03', label = 'Pole Routine 3' },
    },
    platform = {
        { dict = 'mini@strip_club@private_dance@part1', clip = 'priv_dance_p1', label = 'Floor Routine 1' },
        { dict = 'mini@strip_club@private_dance@part2', clip = 'priv_dance_p2', label = 'Floor Routine 2' },
        { dict = 'mini@strip_club@private_dance@part3', clip = 'priv_dance_p3', label = 'Floor Routine 3' },
        { dict = 'mini@strip_club@private_dance@idle', clip = 'priv_dance_idle', label = 'Tease Idle' },
        { dict = 'anim@amb@nightclub@mini@dance@dance_solo@female@var_a@', clip = 'high_center', label = 'Club Solo A' },
        { dict = 'anim@amb@nightclub@mini@dance@dance_solo@female@var_b@', clip = 'high_center', label = 'Club Solo B' },
        { dict = 'anim@amb@nightclub@mini@dance@dance_solo@female@var_a@', clip = 'med_center', label = 'Club Groove' },
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
    -- Transaction titles shown in Renewed Banking history
    washTitle = 'Dirty Money Wash',
    tipTitle = 'Stage Tips',
}

local unicornVanilla = {
    poles = {
        { coords = vector3(112.60, -1286.76, 28.56), heading = 0.0, style = 'pole',     label = 'Main Stage' },
        { coords = vector3(104.18, -1293.94, 29.26), heading = 0.0, style = 'pole',     label = 'Left Pole' },
        { coords = vector3(102.24, -1290.54, 29.26), heading = 0.0, style = 'pole',     label = 'Right Pole' },
        { coords = vector3(118.77, -1302.42, 29.27), heading = 210.0, style = 'platform', label = 'VIP Room 1' },
        { coords = vector3(113.35, -1303.17, 29.27), heading = 210.0, style = 'platform', label = 'VIP Room 2' },
        { coords = vector3(111.25, -1301.80, 29.27), heading = 30.0,  style = 'platform', label = 'VIP Room 3' },
    },
    wash = {
        coords = vector3(96.22, -1292.71, 29.27),
        radius = 1.15,
        label = 'Count Dirty Money',
    },
}

local unicornGabz = {
    poles = {
        { coords = vector3(108.85, -1289.03, 29.25), heading = 0.0, style = 'pole',     label = 'Main Stage' },
        { coords = vector3(104.77, -1294.17, 29.25), heading = 0.0, style = 'pole',     label = 'Left Pole' },
        { coords = vector3(102.23, -1289.85, 29.25), heading = 0.0, style = 'pole',     label = 'Right Pole' },
        { coords = vector3(118.71, -1302.35, 29.27), heading = 210.0, style = 'platform', label = 'VIP Room 1' },
        { coords = vector3(113.40, -1303.20, 29.27), heading = 210.0, style = 'platform', label = 'VIP Room 2' },
        { coords = vector3(111.22, -1301.85, 29.27), heading = 30.0,  style = 'platform', label = 'VIP Room 3' },
    },
    wash = {
        coords = vector3(93.15, -1292.12, 29.26),
        radius = 1.15,
        label = 'Count Dirty Money',
    },
}

local unicornLayout = Config.UnicornMLO == 'gabz' and unicornGabz or unicornVanilla

Config.Clubs = {
    unicorn = {
        label = 'Vanilla Unicorn',
        -- Renewed Banking job account name (must match the job name)
        account = 'unicorn',
        -- job name = minimum grade that can place / remove dancers
        jobs = {
            unicorn = 0,
            vanillaunicorn = 0,
        },
        -- Minimum grade that can wash money for a guest (desk is still available in "self"/"both")
        washGrade = 0,
        blip = {
            enabled = true,
            coords = vector3(128.87, -1298.93, 29.23),
            sprite = 121,
            color = 8,
            scale = 0.8,
            label = 'Vanilla Unicorn',
        },
        poles = unicornLayout.poles,
        wash = unicornLayout.wash,
    },

    -- After Hours nightclub interior (go-go platforms, not poles).
    -- Enable this job on your server or remove the club if you do not use it.
    nightclub = {
        label = 'Nightclub',
        account = 'nightclub',
        jobs = {
            nightclub = 0,
        },
        washGrade = 0,
        blip = {
            enabled = false,
            coords = vector3(-16.75, 216.50, 106.75),
            sprite = 614,
            color = 7,
            scale = 0.8,
            label = 'Nightclub',
        },
        poles = {
            { coords = vector3(-1598.57, -3015.68, -78.21), heading = 270.0, style = 'platform', label = 'Left Platform' },
            { coords = vector3(-1596.22, -3007.97, -78.21), heading = 270.0, style = 'platform', label = 'Right Platform' },
            { coords = vector3(-1594.12, -3012.05, -78.21), heading = 90.0,  style = 'platform', label = 'Center Stage' },
        },
        wash = {
            coords = vector3(-1618.52, -3012.06, -75.21),
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
