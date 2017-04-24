-- Add a prefabpostinit to teenbirds to make then select which type of adult they should grow up into.
print('Loading tallbird mod')

_G = GLOBAL
TUNING = _G.TUNING
STRINGS = _G.STRINGS
require = _G.require

tweak_teenbird = _G.require('tweaks/tweakteenbird')

AddPrefabPostInit("teenbird", tweak_teenbird)
------------------------------------------------------

-- Define a new prefab for Tame Tallbirds
PrefabFiles = {'tametallbird'}
STRINGS.NAMES.TAMETALLBIRD = 'Tame Tallbird'
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TAMETALLBIRD = {
	GENERIC = "Very tall and very loyal.",
	HUNGRY = "Better get you some food, Big Guy.",
	STARVING = "Careful Big Guy, just don't eat me!",
}

------------------------------------------------------
-- Tuning Values for Tame Tallbirds
TUNING.TAME_TALLBIRD_HEALTH = 400 * GetModConfigData("TAMETALLBIRD_HEALTH_MOD")
TUNING.TAME_TALLBIRD_DAMAGE = 50 * GetModConfigData("TAMETALLBIRD_DAMAGE_MOD")
TUNING.TAME_TALLBIRD_ATTACK_PERIOD = 2
TUNING.TAME_TALLBIRD_ATTACK_RANGE = 3
TUNING.TAME_TALLBIRD_TARGET_DIST = 8
TUNING.TAME_TALLBIRD_DEFEND_DIST = 12

TUNING.TAME_TALLBIRD_DAMAGE_PECK = 2
TUNING.TAME_TALLBIRD_PECK_PERIOD = 4
TUNING.TAME_TALLBIRD_HUNGER = 120
TUNING.TAME_TALLBIRD_STARVE_TIME = TUNING.TOTAL_DAY_TIME * GetModConfigData("TAMETALLBIRD_STARVE_TIME")
TUNING.TAME_TALLBIRD_STARVE_KILL_TIME = 240

-- Tuning Values for Tallbird Growth
TUNING.SMALLBIRD_HATCH_TIME = TUNING.TOTAL_DAY_TIME * GetModConfigData("TALLBIRDEGG_HATCH_TIME")
TUNING.SMALLBIRD_GROW_TIME = TUNING.TOTAL_DAY_TIME * GetModConfigData("TEEN_GROWTH_TIME")
TUNING.TEENBIRD_GROW_TIME = TUNING.TOTAL_DAY_TIME * GetModConfigData("ADULT_GROWTH_TIME")

------------------------------------------------------
-- For Reference
--TALLBIRD_HEALTH = 400,
--TALLBIRD_DAMAGE = 50,
--TALLBIRD_ATTACK_PERIOD = 2,
--TALLBIRD_ATTACK_RANGE = 3,
--TALLBIRD_TARGET_DIST = 8,
--TALLBIRD_DEFEND_DIST = 12,

--TEENBIRD_DAMAGE_PECK = 2,
--TEENBIRD_PECK_PERIOD = 4,
--TEENBIRD_HUNGER = 60,
--TEENBIRD_STARVE_TIME = total_day_time * 1,
--TEENBIRD_STARVE_KILL_TIME = 240,

-- print(TUNING.SMALLBIRD_HATCH_TIME)

------------------------------------------------------
-- Speed smallbird growth for testing purposes
if GetModConfigData("DEBUG_GROWTH_SPEED") then
	TUNING.SMALLBIRD_HATCH_TIME = 5
	TUNING.SMALLBIRD_GROW_TIME = 10
	TUNING.TEENBIRD_GROW_TIME = 10
end
