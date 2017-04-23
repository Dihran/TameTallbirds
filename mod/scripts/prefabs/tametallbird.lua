local brain = require "brains/smallbirdbrain"

local WAKE_TO_FOLLOW_DISTANCE = 10
local SLEEP_NEAR_LEADER_DISTANCE = 7

local assets=
{
	Asset("ANIM", "anim/ds_tallbird_basic.zip"),
	Asset("SOUND", "sound/tallbird.fsb"),
}

local function GetStatus(inst)
    --print("tametallbird - GetStatus")
    if inst.components.hunger then
        if inst.components.hunger:IsStarving(inst) then
            --print("STARVING")
            return "STARVING"
        elseif inst.components.hunger:GetPercent() < .5 then
            --print("HUNGRY")
            return "HUNGRY"
        end
    end
end

local function ShouldWakeUp(inst)
    return DefaultWakeTest(inst) or inst.components.hunger:IsStarving(inst) or not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE)
end

local function ShouldSleep(inst)
    return DefaultSleepTest(inst) and not inst.components.hunger:IsStarving(inst) and inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE)
end

local function CanEatTest(inst, item)
    -- deprecated
    --print("tametallbird - CanEatTest", inst.name, item.components.edible.foodtype, item, item.prefab)
    local canEat = (item.components.edible.foodtype == "SEEDS") or (item.prefab == "berries")
    --print("   canEat?", canEat)
    return canEat
end

local function ShouldAcceptItem(inst, item)
    --print("tametallbird - ShouldAcceptItem", inst.name, item.name)
    if item.components.edible and inst.components.hunger and inst.components.eater then
        return inst.components.eater:CanEat(item) and inst.components.hunger:GetPercent() < .9
    end
end

local function OnGetItemFromPlayer(inst, giver, item)
    --print("tametallbird - OnGetItemFromPlayer")

    if inst.components.sleeper then
        inst.components.sleeper:WakeUp()
    end

    --I eat food
    if item.components.edible then
        if inst.components.combat.target and inst.components.combat.target == giver then
            inst.components.combat:SetTarget(nil)
            -- inst:FollowPlayer(inst)
        end
        if inst.components.eater:Eat(item) then
            --print("   yummy!")
            -- yay!?
        end
    end
end

local function OnEat(inst, food)
    -- there is no health metre, so eating anything heals a portion of max hp
	inst.components.health:DoDelta(inst.components.health.maxhealth * .33, nil, food.prefab)
	inst.components.combat:SetTarget(nil)
end

local function OnRefuseItem(inst, item)
    --print("tametallbird - OnRefuseItem")
    --inst.sg:GoToState("refuse")
end

local function FollowPlayer(inst, player)
    --print("tametallbird - FollowPlayer")

	if inst.components.follower.leader == nil then
		-- local player = GetPlayer()
		if player and player.components.leader then
			--print("   adding follower")
			player.components.leader:AddFollower(inst)
		end
	end
end

local function UnfollowPlayer(inst)
    --print("tametallbird - UnfollowPlayer")

    if inst.components.follower.leader then
        inst.components.followers.leader:RemoveFollower(inst)
    end
end

local function SetBirdAttackDefault(inst)
    --print("tametallbird - Set phasers to 'KILL'")
    inst:RemoveTag("peck_attack")
    inst.components.combat:SetDefaultDamage(TUNING.TAME_TALLBIRD_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.TAME_TALLBIRD_ATTACK_PERIOD)
end

local function SetBirdAttackPeck(inst)
    --print("tametallbird - Set phasers to 'PECK'")
    inst:AddTag("peck_attack")
    inst.components.combat:SetDefaultDamage(TUNING.TAME_TALLBIRD_DAMAGE_PECK)
    inst.components.combat:SetAttackPeriod(TUNING.TAME_TALLBIRD_PECK_PERIOD)
end

local function OnNewTarget(inst, data)
    --print("tametallbird - OnNewTarget", data.target, inst.components.follower.leader)
    if data.target and data.target:HasTag("player") then
        -- combat component will restore target to player, give them the benefit of the doubt and use peck instead of attack to begin with
        SetBirdAttackPeck(inst)
    else
        SetBirdAttackDefault(inst)
    end
end

local function Retarget(inst)
    local notags = {"FX", "NOCLICK","INLIMBO"}
    return FindEntity(inst, TUNING.TAME_TALLBIRD_TARGET_DIST, function(guy)
    if inst.components.combat:CanTarget(guy)  and (not guy.LightWatcher or guy.LightWatcher:IsInLight()) then
        if inst.components.follower.leader ~= nil then
            return (guy:HasTag("monster") or (guy == inst.components.follower.leader and guy:HasTag("player") and inst.components.hunger and inst.components.hunger:IsStarving()))
        else
            return guy:HasTag("monster")
        end
    end
  end)
end

local function KeepTarget(inst, target)
    return inst.components.combat:CanTarget(target) and (not target.LightWatcher or target.LightWatcher:IsInLight())
end

local function OnAttacked(inst, data)
    --print("tametallbird - OnAttacked !!!")

    if data.attacker ~= nil and (data.attacker == inst.components.follower.leader or data.attacker:HasTag("player")) then
        --print("  what did I ever do to you!?")
        -- well i was just annoyed, but now you done pissed me off!
        SetBirdAttackDefault(inst)
    end

    inst.components.combat:SuggestTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, 10, function(dude) return dude:HasTag("smallbird") and not dude.components.health:IsDead() end, 5)
end

local function GetPeepChance(inst)
    local peep_percent = 0.1
    if inst.components.hunger then
        if inst.components.hunger:IsStarving() then
            peep_percent = 1
        elseif inst.components.hunger:GetPercent() < .25 then
            peep_percent = 0.9
        elseif inst.components.hunger:GetPercent() < .5 then
            peep_percent = 0.75
        end
    end
    --print("tametallbird - GetPeepChance", peep_percent)
    return peep_percent
end

local function OnHealthDelta(inst, data)
    if data.cause == "hunger" and data.newpercent < .5 and inst.components.follower.leader then
        --print("tametallbird - STARVING i'm blowing this popsicle stand!", data.newpercent)

        if inst.components.combat.target == inst.components.follower.leader then
            inst.components.combat:SetTarget(nil)
        end

        inst.components.follower:SetLeader(nil)
    end
end

local function create_common(inst)
    --print("tametallbird - create_common")

    --inst = inst or CreateEntity()

    

    --print("tametallbird - create_common END")
    return inst
end

local function create_tame_tallbird()
    --print("tametallbird - create_tame_tallbird")

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.AnimState:SetBank("tallbird")
    inst.AnimState:SetBuild("ds_tallbird_basic")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:Hide("beakfull")

    inst:AddTag("animal")
    inst:AddTag("companion")
    inst:AddTag("character")
    inst:AddTag("tallbird")
    -- Adding teenbird tag for now so the SGtallbird works correctly
    inst:AddTag("teenbird")
    inst:AddTag("tametallbird")

    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()

    MakeCharacterPhysics(inst, 10, .5)

    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)

    inst.Transform:SetFourFaced()

    inst:SetBrain(brain)

    inst.userfunctions =
    {
        FollowPlayer = FollowPlayer,
        GetPeepChance = GetPeepChance,
        UnfollowPlayer = UnfollowPlayer,
    }

    ------------------------------------------
    inst:AddComponent("health")
    inst:AddComponent("hunger")

    inst:AddComponent("combat")
    inst:ListenForEvent("attacked", OnAttacked)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 7

    inst:AddComponent("follower")

    inst:AddComponent("eater")
    inst.components.eater:SetOmnivore()
    inst.components.eater:SetOnEatFn(OnEat)
    --inst.components.eater:SetCanEatTestFn(CanEatTest)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem

    inst:SetStateGraph("SGtallbird")

    inst.Transform:SetScale(1, 1, 1)

    inst.Physics:SetCylinder(.5, 1)

    inst.DynamicShadow:SetSize(2.75, 1)
    MakeLargeBurnableCharacter(inst, "head")
    MakeMediumFreezableCharacter(inst, "head")

    inst.components.health:SetMaxHealth(TUNING.TAME_TALLBIRD_HEALTH)
    inst:ListenForEvent("healthdelta", OnHealthDelta)

    inst.components.hunger:SetMax(TUNING.TAME_TALLBIRD_HUNGER)
    inst.components.hunger:SetRate(TUNING.TAME_TALLBIRD_HUNGER/TUNING.TAME_TALLBIRD_STARVE_TIME)
    inst.components.hunger:SetKillRate(TUNING.TAME_TALLBIRD_HEALTH/TUNING.TAME_TALLBIRD_STARVE_KILL_TIME)

    inst.components.combat.hiteffectsymbol = "head"
    inst.components.combat:SetRange(TUNING.TAME_TALLBIRD_ATTACK_RANGE)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    SetBirdAttackDefault(inst)

    inst:ListenForEvent("newcombattarget", OnNewTarget)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"meat"}, {"meat"})

    --print("tametallbird - create_tame_tallbird END")
    return inst
end

return Prefab( "common/tametallbird", create_tame_tallbird, assets)
