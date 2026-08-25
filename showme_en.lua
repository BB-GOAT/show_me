local MY_STRINGS =	-- 调用 MY_DATA.armor.desc
{
    armor = "Dmg Absor: " , --A --Armor of the item.
    aggro = "Aggression: " , --B --Score of griefing 
    cookpot = "Cooking: " , --C (Crock Pot)
    dmg = "Damage: " , --D
    electric = "Electricity: " , --E --electric power
    food = "Food: ",
    S2="It's Summer," , --G
    health= "Health: " , --H --for food
    warm = "Insulation: " , --I --winter insulation
    kill = "Kill: " , --J  --for Canibalism 18 mod (if character murder only once)
    kills = "Kills: " , --K  --for Canibalism 18 mod (shows count of kills)
    loyal = "Loyalty: " , --L  --pigman and bunnyman
    S4="It's Autumn," , --M
    remaining_days = "Remaining days: " , --N
    owner = "Owner: " , --O --support of various mods
    perish = "Spoil in: " , --P -- Spoil in N days. 
    hunger= "Hunger: " , --Q
    range = "Range: " , --R  --for range weapon or for mobs
    sanity= "Sanity: " , --S
    thickness = "Thickness: " , --T --It's about thickness of the ice of a pond
    units_of = "units of" , --U
    resist = "Resistance: " , --V --against sleep darts, ice staff etc
    waterproof = "Waterproof: " , --W --Resistance against water
    heal = "Heal: " , --X --How much health will be restored by some medic pack
    fishes = "Fishes: " , --Y  --Count fishes in a pond
    fish = "Fish: " , --Z --Count fishes in a pond if there is only 1 fish
    sec= "Seconds: " ,  --for cooking in Crock Pot
    love = "Love: " ,
    summer = "Summer: " , --summer insulation
    absorb = "Absorb: " , --Absorb damage
    S3="It's Spring," , --
    temperature = "t: " ,
    hp= "HP: " , --for characters
    armor_character = "Armor: " , --Armor of the creature or player.
    sanity_character = "Sanity: " , --S    
    fuel = "Fuel: " , --F --for firepit
    speed = "Speed: " , --Bonus of the speed (percent)
    uses_of = "uses of" ,
    obedience = "Obedience: " ,
    S1="It's Winter," ,
    dmg_character = "Damage: " ,
    power = "Power: ", --P 
    cooldown="Cooldown: ",
    domest = "Tamed: ", -- "Domestication:"
    will_die = "Will die in: ", -- will die in N days (saying about pet or animal).
    will_dry = "Will die in: ", --
    dmg_bonus = "Damage bonus: ", -- Damage: +X (means damage modifier, not base damage)
    crop = "", --Not used. It's just a key for info type. Info - "Product: percent"
    grow_in = "Grows in: ", -- About grass etc
    perish_product = "", --Just a key for info type. Info - "Product: time in days"
    just_time = "", --Just a key for info type. Info - [time]
    timer = "Timer: ",
    trade_gold = 'Gold tribute: ',
    trade_rock = 'Rock tribute: ',
    durability = 'Durability: ',
    strength = 'Strength: ',
    aoe = "AoE: ",
    food_temperature = "Food Temperature: ",
    precipitationrate = "Global Rain: ",
    wetness = "Global Wetness: ",
    growable = " ",
    sanityaura = "Sanity Aura: ",
    fresh = "Fresh in",
    frigde = "frigde",
    food_memory = "Memory",
    buff = "Buff",
    effectiveness = "Effectiveness: ",
    force = "Force: ",
    repairer = "Repair: ",
    -- Crops
    nutrient = "Nutrient: " ,
    moisture = "Moisture: " ,
    stress_tag = " ",
    other_tag = " ",
    harvest="Harvest: ",
    children="Creatures: ",
    basedmg = "Planar Damage: ",
    basearmor = "Planar Defense: ",
    friendlevels = "Friendship Level: ",
    --Thirst mod
    water = "Water: ",
    salt = "Salt: ",
    sip = "A Sip: ",
    watergainspeed = "Water gain speed: ",
    water_poisoned = "Is poisoned!",
    --Prism
    pollinated = "Pollinated: ",
    sickness = "Sickness: ",
    infested = "Infested: ",
}

local SHOWME_STRINGS = {
    loyal = "forever", --for very loyal pigman with loyalty over 9000
    of = " of ", -- X of Y (reserved)
    units_1 = "1 unit of ",
    units_many = " units of ",
    uses_1 = "1 use of ",
    uses_many = " uses of ", -- X uses of Y, where X > 1
    days = " days", --Spoil in N days.
    temperature = "Temperature",
    paused = "Paused",
    stopped = 'Stopped',
    already_fresh = "Maximum freshness",
    cheat_fresh = "Cheat mod detected",
    onpickup = " on pick up", --for flowers
    pressure = 'Pressure(%s) ',
    _in = ' in ',
    jieduan = "Stage", chixu = " Duration", pvp = "pvp: ", norot = "Permanent freshness", hot = "Spoil speed +", weak = "Spoil speed +", cold = "Freshness +", refresh = "Refresh speed +", xiaolv = "Efficiency", fangyu = "Absorb", gongji = "Damage", fangshui = "Waterproof", gandian = "Electrified attack", faguang = "light", huifu = "Health regen",
}

--食物信息名称定义，例如【1 单位 veggie】，定义后显示【1单位 蔬菜】
FOOD_TAGS = {
    veggie = "Vegetable", fruit = "Fruit", monster = "Monster Meat", sweetener = "Sweetener", meat = "Meat", fish = "Fish", magic = "Magic", egg = "Egg", decoration = "Wings", dairy = "Dairy", fat = "Fat", inedible = "Twigs", frozen = "Ice", ice = "Ice", seed = "Seed", mogu = "Mushroom", petals_legion = "Petal", foliage = "Foliage", rice = "Rice", insectoid = "Insect", gourd = "Gourd", gel = "Gel", jellyfish = "Jellyfish", odoy_salt = "Salt", ndnr_soybean = "Soybean",
    --Waiter 101
    fungus = "Fungus", mushrooms = "Mushrooms", poultry = "Poultry", wings = "Wings", seafood = "Seafood", nut = "Nut", cactus = "Cactus", starch = "Starch", grapes = "Grape", citrus = "Citrus", tuber = "Tuber", shellfish = "Shellfish",
    --BEEFALO MILK and CHEESE mod
    rawmilk = "Raw Milk",
    --Camp Cuisine: Re-Lunched
    bulb = "Light Bulb", spices = "Spices", challa = "Challah", flour = "Flour",
    --Chocolate
    cacao_cooked = "Cocoa",
}

--给显示预计:xxx定义名称，例如显示【预计:wall_cd 00:30】，定义名称后显示：【沙墙冷却 00:30】
local INTERNAL_TIMERS = {
    --Antlion
    wall_cd = "Wall", rage = 'Rage', nextrepair = 'Next Repair', eat_cd = "Repair",
    --Squid
    ink_cooldown = "Ink", gobble_cooldown = "Gobble", --also: for shark
    --Atrium Gate
    destabilizing = "Destabilizing", destabilizedelay = "Destabilize Delay", cooldown = "Cooldown",
    --Bee Queen Hive
    hivegrowth1 = "Growth Stage 2", hivegrowth2 = "Growth Stage 3", hivegrowth = "Growth Stage 1", shorthivegrowth = "Short Growth", hiveregen = "Regen", firsthivegrowth = "First Growth",
    --Bee Queen
    spawnguards_cd = "Spawn Guards", focustarget_cd = "Focus Target",
    --Crab King
    spell_cooldown = "Spell", claw_regen_delay1 = "Claw 1", claw_regen_delay2 = "Claw 2", claw_regen_delay3 = "Claw 3", claw_regen_delay4 = "Claw 4", claw_regen_delay5 = "Claw 5", claw_regen_delay6 = "Claw 6", claw_regen_delay7 = "Claw 7", claw_regen_delay8 = "Claw 8", claw_regen_delay9 = "Claw 9", claw_regen_delay10 = "Claw 10", claw_regen_delay11 = "Claw 11", claw_regen_delay12 = "Claw 12", claw_regen_delay13 = "Claw 13", claw_regen_delay14 = "Claw 14", regen_crabking = "Regen", casting_timer = "Casting", gem_shine = "Gem Shine", clawsummon_cooldown = "Claw Summon Cooldown", claw_regen_timer = "Call Claw", seastacksummon_cooldown = "seastack summon", fix_timer = "fix", heal_cooldown = "Heal",
    --Trees, ghostly_elixirs.lua
    decay = "Decay",
    --Grass Gekko
    morphing = "Morphing", growTail = "Grow Tail",
    --Lightflier Flower, Flower Cave
    recharge = "Recharge", turnoff = "Turn Off", Pickable_RegenTime = "Regen",
    --Merm King
    hungrytalk_increase_cooldown = "Hungry Talk Increase", hungrytalk_cooldown = "Hungry Talk",
    --Mole Bat
    resetnap = "Reset Nap", cleannest_timer = "Clean Nest", resetallysummon = "Reset Ally Summon", rememberinitiallocation = "Remember Initial Location",
    --Walrus Camp
    walrus = "MacTusk", little_walrus = "Wee MacTusk", icehound = "Blue Hound",
    --Hermit Crab
    speak_time = "Speak", complain_time = "Complain", salad = "Salad", bottledelay = "Bottle", fishingtime = "Fishing",
    --hermit_grannied plus GUID -- dynamic GUID, cannot translate
    --Maxwell Shadow Clone
    obliviate = "Contract", -- will disappear after this time, better defined as contract
    --Wanda, Ocean Whirlportal
    closeportal = "Portal Close", closewhirlportal = "Portal Close",
    --Malbatross
    sleeping_relocate = "Sleeping Relocate", divetask = "Dive", disengage = "Disengage", satiated = "Satiated", splashdelay = "Splash",
    --Toadstool
    sporebomb_cd = "Sporebomb", mushroombomb_cd = "Mushroom Bomb", mushroomsprout_cd = "Mushroom Sprout", pound_cd = "Pound", channeltick = "Cast Wait", channel = "Cast",
    --Toadstool Cap
    darktimer = "Dark", respawndark = "Respawn Dark", respawn = "Respawn",
    --Water Plant
    resetcloud = "Reset Cloud", equipweapon = "Equip Weapon",
    --Wavey Jones
    laughter = "Laughter", reactiondelay = "Reaction", respawndelay = "Respawn", trappedtimer = "Trapped",
    --Bearger
    GroundPound = "Ground Pound", Yawn = "Yawn",
    --Klaus
    chomp_cd = "Chomp", command_cd = "Command",
    --Shark, Shark Boi
    getdistance = "Get Distance", minleaptime = "Leap", calmtime = "Calm", targetboatdelay = "Target Boat", standing_dive_cd = "Leap Dive", torpedo_cd = "Torpedo Spin",
    --Sacred Chest
    localoffering = "Offering", localoffering_pst = "Offer (pst)",
    --Stalker (Resurrected Skeleton)
    snare_cd = "Snare", spikes_cd = "Spikes", channelers_cd = "Channelers", minions_cd = "Minions", mindcontrol_cd = "Mind Control",
    --Deer (No-eyed)
    growantler = "Grow Antler", deercast_cd = "Cast",
    --Fruit Dragon (Salad)
    fire_cd = "Fire", panicing = "Panic",
    --Moon Base
    moonchargepre = "Precharge", mooncharge = "charge(1)", mooncharge2 = "charge(2)", mooncharge3 = "charge(3)", fullmoonstartdelay = "Full Moon",
    --Dragonfly
    regen_dragonfly = "Regen", groundpound_cd = "Ground Pound",
    --Celestial Champion
    hitsound_cd = "Hitsound", roll_cooldown = "Roll", summon_cooldown = "Summon", summon_cd = "summon", spin_cd = "Spin", spike_cd = "Spike", traps_cd = "Trap", finish_pulse = "Finish Pulse", trap_lifetime = "Trap Lifetime", pulse = "Pulse", runaway_blocker = "Escape",
    --Ancient Guardian
    forceleapattack = "Leap", forcebelch = "Ink Spray", rammed = "Ram", endstun = "End Stun", leapattack_cooldown = "Leap Attack",
    --Others
    repair = "Repair", -- Dust Moth Den
    dontfacetime = "Don't Face", -- Merm
    growth = "Growth", -- Salt Stack
    lordfruitfly_spawntime = "Lord Fruit Fly", -- Farm Manager
    facetime = "Face", -- Merm Brain
    regenover = "Recover", -- Salve, Compost Wrap, etc.
    make_debris = "Make Debris", -- Weed Defs
    spread = "Spread", -- Weed Plants
    expire = "Expire", -- Archive Resonator
    drilling = "Drilling", -- Farm Plow
    composting = "Composting", -- Composting Bin
    HatchTimer = "Hatch", -- Moose Egg
    lifespan = "Lifespan", -- Ocean Fish
    offeringcooldown = "Offering", -- Perd (Turkey)
    rock_ice_change = "Melting", -- Ice Rock
    lifetime = "Lifetime", -- School Herd
    disperse = "Disperse", -- Sleep Cloud, Spore Cloud, etc.
    extinguish = "Extinguish", -- Star Caller Staff Light
    transform_cd = "Transform", -- Bernie
    taunt_cd = "Taunt",
    buffover = "Buff", -- Food Buffs (Winter's Feast, etc.)
    resettoss = "Reset Toss", -- Gnarwail
    revive = "Revive", -- Hound Corpse
    toot = "Toot", -- Moon Fissure
    training = "Training", -- Gym (component)
    salt = "Salt", -- Salt Licker (component)
    foodspoil = "Food Spoil", -- Trap (component)
    --Deerclops
    laserbeam_cd = "Lazarbeam", auratime = "Auratime", uppercuttime = "Uppercut", Freeze = "Freeze",
    --Moose
    DisarmCooldown = "Disarm", SuperHop = "SuperHop", WantsToLayEgg = "Lay Egg", TornadoAttack = "Summon Tornado",
    explode = "Explode", -- Spore Bomb
    selfdestruct = "Self Destruct", -- Stalker Minions, Lavae
    self_combustion = "Self Combustion", -- Mini Boat Lantern
    despawn_timer = "Despawn", -- Pig Elite Fighter
    rotting = "Rotting", -- Plant Normal
    grow = "Grow", -- Planted Tree, Rock Avocado Fruit
    remove = "Remove", -- Fish School Spawn Blocker
    Spawner_SpawnDelay = "Spawner Spawn", -- Pig House
    blink = "Blink", flamethrower_cd = "Extreme Cold Flame", ash = "Ash",
    infest_cd = "Infest",
    disappear = "Disappear", errode = "errode",
    --WX-78 Scanner
    toplightflash_tick = "Scanning", onsucceeded_flashtick = "Capture Complete", onsucceeded_timeout = "Capture Cooldown", chargeregenupdate = "Charge Increase", ANNOUNCE_WX_SCANNER_NEW_FOUND = "Announce New Discovery",
    --Wormwood Contract
    finish_transformed_life = "Contract",
    --Water Tree Community
    lookforfish = "Patrol", eat_cooldown = "Eat", investigating = "Inspecting", enriched_cooldown = "Enriched", shed = "Shed", facetarget = "Stare", flotsamgenerator_sink = "Sink", cocoon_regrow_check = "Cocoon Regen", regrow_oceantreenut = "Fig Seed Regen",
    --Moon Dock
    startportalevent = "Event Start", fireportalevent = "Event Ongoing", spawnportalloot_tick = "Spawn Item", right_of_passage = "Passport Active", hit = "Hit",
    --Terra
    summon_delay = "Summoning", warning = "Warning", spawneyes_cd = "Spawn Eye", leash_cd = "Leash", charge_cd = "Charge",
    --Shadow and Moon Factions
    targetswitched = "Target Switch", attack_cooldown = "Attack", idletimer = "Idle Time", try_crystals = "Try Crystals", trynextstage = "Next Stage", seedmiasma = "Merge Shadow", close = "Rift Close", jump_cooldown = "Jump Attack", chase_tick = "Split", finish_spawn = "Finish Spawn", start_explosion = "Explosion", spawn_delay = "Spawn Delay", start_ball_growing = "Expand", stalk_cd = "Stalk", roar_cd = "Roar",
    --Myth
    growup = "Grow", light = "Light Left", peach = "Peach Left", blackbear = "Black Wind Respawn", despawn = "Disappear", flyaway = "Fly Away", goaway = "Leave", cd = "Cooldown", myth_nian_timer = "Nian Beast", nian_leave = "Nian Occupies", bomb_cd = "Corruption Cloud", bombboom = "Corruption Cloud Explode", nian_noclose = "Always Open", nian_killed = "Discount", timeover = "Contract", yj_spear_elec = "Charge",
    TreeDance = "Tree Dance",
    --Shipwrecked
    startsink = "Sink", go_home_delay = "Go Home", SPIKE = "Grow Spike", Run = "Bite",
    --Uncompromising
    regrow = "Regrow", passedby = "Passed", infest = "Borers", vomit_time = "Vomit", unelectrify = "Discharge", electrify = "Charging", scoutingparty = "Scout Party", stumptime = "Mutate in", pounce = "Pounce", mortar = "Spit Web", RockThrow = "Throw", glassshards = "Shard Attack", summoncrystals = "Summon Crystal", defusetime = "Break", natural_death = "Death in", remoss = "Aphids", podreset = "Pod Reset", refill = "Refill", SpitCooldown = "Throw", --Walrus, Spider Queen
    --Prism
    axeuppercut_cd = "Axe Uppercut", heavyhack_cd = "Heavy Hack", callforlightning_cd = "Call Lightning", rangesplash_cd = "Electric Charge/Jump", flashwhirl_cd = "Spin Strike", dehydration = "Dehydration Spoil", birddeath = "Bird Rebirth", birth = "Hatch", state1 = "Hatch Stage 1", state2 = "Hatch Stage 2", state3 = "Hatch Stage 3", taunt = "Enchanting Sound", caw = "Flower Message", flap = "Feather Dance", flap_pre = "Feather Dance pre", eye = "Same Eye", revolt = "Revolt Heat", moonsurge = "Moon Surge", fallenleaf = "Drop", swallow = "Swallow", lure = "Lure",
    --Fu Gui (timers too long, skipped)
    evergreenpluckabletimer = "Pick Cooldown", beehivepluckabletimer = "Honey Regen", beequeenhivegrownpluckabletimer = "Blueprint Steal Cooldown",
}

local INTERNAL_STAGES = {
    --all trees:
    short = "Small", normal = "Medium", tall = "Large", old = "Withered",
    --spiderden:
    small = "Small", med = "Medium", large = "Max", queen = "Separate",
    --rock_avocado_bush:
    stage_1 = "No Fruit", stage_2 = "Growing", stage_3 = "Ripe", stage_4 = "Cracked",
    --weed_plants:
    --small --duplicate
    --med --duplicate
    full = "Mature", bolting = "Bolting", empty = "Empty Branch",
    --farm_plants:
    seed = "Seed", sprout = "Sprout", rotten = "Reverse Growth",
    --smallbird
    --small --duplicate
    --tall  --duplicate
    --baby beefalo:
    baby = "Baby", toddler = "Calf", teen = "Teen", grown = "Adult",
    --mod
    blooming = "Blooming", fruitful = "Fruiting",
}

local STRESS_TAGS = { --https://dontstarve.fandom.com/wiki/Farm_Plant
    nutrients = "Lack of nutrients",
    moisture = "Lack of moisture",
    killjoys = "Killjoys around",
    family = "No plant family",
    season = "Off Season",
    overcrowding = "Overcrowded plants",
    happiness = "Unhappy",
    withered = "Withered",
}

local OTHER_TAGS = {    --Hardcoded values
    onemanband = "Tends crops\nPlaying makes pigmen/bunnymen follow",
    amulet = "Haunt to revive",
    book_birds = "Summon birds",
    book_brimstone = "Summon lightning strikes",
    book_gardening = "Range: 30\nRipens plants within range",
    book_silviculture = "Range: 30\nGrows plants to max stage",
    book_sleep = "Range: 30\nPuts creatures to sleep",
    wx78_music = "Tends nearby crops",
    wx78_movespeed2 = "Each subsequent boost about 60%",
    wx78_heat = "Provides warmth and heat aura",
    wx78_moisture = "Dries faster: 10%",
    wx78_cold = "Provides cooling and cold aura",
    wx78module_taser = "Lightning protection\nElectrified attack buff",
    wx78module_nightvision = "Night vision",
    wx78module_light = "Light aura",
    slingshot_frame_bone = "Ammo slot +1",
    slingshot_frame_gems = "Ammo slot +1\nAOE splash range 3.5",
    slingshot_frame_wagpunk_0 = "Charge damage 1~2x\nCharge planar damage 1~2x\nCharge bullet speed 1~1.25x",
    slingshot_handle_voidcloth = "Enhances dreadstone and pure horror ammo\nDamage +10%\nPlanar damage +5\nCluster terror +2 uses",

    --Halloween
    halloweenpotion_health = "Health regen +1/sec, lasts 30 sec",
    halloweenpotion_sanity = "Sanity regen +1/sec, lasts 30 sec",
    --Wolfgang
    wolfgang_whistle = "Range: 6 tiles\nFollowers gain 9.5 sec double damage\nPlayer gains 5 sanity bonus",
    --Slingshot ammo
    slingshotammo_freeze = "Freeze target",
    slingshotammo_poop = "Target loses aggro",
    slingshotammo_thulecite = "Shadow tentacle spawn chance 50%",
    --Prism
    lileaves = "-30% enemy attack",
    rosorns = "Ignore enemy armor",
    --Shipwrecked
    shark_teethhat = "On boat sanity +6.6/min",
    brainjellyhat = "Craft without tech",
    gashat = "Gas protection",
    armorseashell = "Physical poison protection",
}

--%s 是获取官方tuning.lua的对应值，如果模组不是通过tuning修改值可能会导致显示不正确
OTHER_TITLES = {
    spice_salt = "Food health +%s",
    maxhealth = "Max health +%s",
    maxsanity = "Max sanity +%s",
    maxhunger = "Max hunger +%s",
    wx78_hot_cold = "Food spoilage rate: %s",
    wx78_cold3 = "When wetness above %s, produce ice",
    ghost_atkf = "Shield damage: %s",
    hungerslow = "Hunger slowdown: %s",
    healthpertick = "Health regen: +%s",
    ghost_atk = "Night damage for %s days",
    ghost_shd = "Shield duration extended to 1 sec for %s days",
    ghost_sd = "Speed +%s for %s days",
    batbat = "Lifesteal %s, sanity %s",
    book_hlt = "Ripens %s crops",
    ruins_bat = "Shadow tentacle chance: %s",
    ruinshat = "Shield chance: %s",
    bs_dy = "Weapon durability slowdown %s",
    bs_hp = "Health regen on attack +%s/hit (Wigfrid %s)",
    bs_san = "Sanity regen on attack +%s/hit",
    bs_desan = "Negative sanity effects -%s",
    bs_fire = "Fire damage reduction -%s",
    bs_it = "Taunts enemies in range",
    bs_ip = "Enemies in range panic %s sec",
    bs_shadow = "Damage to lunar creatures +%s",
    bs_shadow2 = "Damage taken from shadow creatures %s",
    bs_lunar = "Damage to shadow creatures +%s",
    bs_lunar2 = "Damage taken from lunar creatures %s",
    hpotion_bravery = "Resist bat spawn from chopping and opening chests for %s days",
    sammo_slow = "Target speed %s, lasts %s sec",
    resist = "Planar resistance: ",
    dmgresist = "Has planar resistance",
    point = " points",
    grow_in = "Grows in: ",
    grow_time = "@Growth time: ",
    energytime = "Energy left: ",
    seednum = "Converting: ",
    fruitnum = "Converted: ",
    second = " sec",
    _in = " approx. ",
    will_other = "Remaining: ",
    fueled = "Durability: ",
    moisture = "Moisture left: ",
    nutrients = "Fertilizer: ",
    nutrients_1 = "Growth stimulant: ",
    nutrients_2 = "Compost: ",
    nutrients_3 = "Manure: ",
    capacity = "Capacity: ",
    siv_mask = "Store: ",
    siv_light = "Radiance: ",
    siv_health = "Health: ",
    ot_fuel = "Fuel: ",
    ot_fuelval = "Fuel value: ",
    lg_moon = "Inlay: ",
    sammo_honey = "Target speed %s",
    ot_pickable = "Pick count: ",
    mpl_hit = "Planar deepen %s/hit, lasts %s sec",
    shf_hit = "Cluster terror %s/use, total %s uses",
    slingshot_range = "Slingshot range: +%s",
    ammo_speed = "Bullet speed: +%s",
    slingshot_speed = "%s chance to not consume ammo",
    critterhunger = "Hunger left: ",

    --new
    -- level = "等级: ",
    -- kills = "击败",
    -- life_stealing = "吸血: ",
    -- sanity = "精神: ",
	-- nutrient = "%d水，%d催，%d堆，%d粪",

    --MOD
    beerpowerpower = "Bulb power: ",
    waterpowerpower = "Water power: ",
    gaspowerpower = "Gas power: ",
}

return {
    MY_STRINGS = MY_STRINGS,
    SHOWME_STRINGS = SHOWME_STRINGS,
    FOOD_TAGS = FOOD_TAGS,
    INTERNAL_TIMERS = INTERNAL_TIMERS,
    INTERNAL_STAGES = INTERNAL_STAGES,
    STRESS_TAGS = STRESS_TAGS,
    OTHER_TAGS = OTHER_TAGS,
    OTHER_TITLES = OTHER_TITLES,
}