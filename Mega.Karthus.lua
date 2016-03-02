local myHero = GetMyHero()
if GetObjectName(myHero) ~= "Karthus" then return end

local d = require 'DLib'
local IsInDistance = d.IsInDistance
local ValidTarget = d.ValidTarget
local CalcDamage = d.CalcDamage
local GetEnemyHeroes = d.GetEnemyHeroes
local GetTarget = d.GetTarget

---- Create Menu ----
Karthus = MenuConfig("Karthus", "Rx Karthus")
tslowhp = TargetSelector(GetCastRange(myHero, _Q), 8, DAMAGE_MAGIC) -- 8 = TARGET_LOW_HP

-- [[ LastHit ]] --
Karthus:Menu("LHMinion", "Last Hit Minion")
Karthus.LHMinion:Boolean("QLH", "Use Q Last Hit", true)
Karthus.LHMinion:Slider("LHMana", "LastHit if %My MP >=", 10, 0, 100, 1)

function Karthus:LastHit()
 for C=1, minionManager.maxObjects do
 local creep = minionManager.objects[C]
  if GetPercentMP(myHero) >= Karthus.LHMinion.LHMana:Value() then
   if creep.team ~= myHero.team and creep.health > 0 then
     if IsInRange(creep, QRange) and IsReady(_Q) and Karthus.LHMinion.QLH:Value() then
      local QDmgPredict, ac = GetHealthPrediction(creep, 750)
      local QPred = GetCircularAOEPrediction(creep, KarthusQ)
      if QDmgPredict > 0 and QPred and QDmgPredict < myHero:CalcMagicDamage(creep, QCheck(creep, QPred.castPos)) then
       CastSkillShot(_Q, QPred.castPos)
      else
       IOW.attacksEnabled = false
      end
     end
    end
  else
   IOW.attacksEnabled = true
  end
 end
end

local function makeSpellMenu(menu)
	local spellmenu = {
		menu.addItem(MenuBool.new("use Q", true)),
		menu.addItem(MenuBool.new("use W", true)),
		menu.addItem(MenuBool.new("use E", true))
	}
	return spellmenu
end

local submenu = menu.addItem(SubMenu.new("simple karthus"))

local comboMenu = submenu.addItem(SubMenu.new("combo"))
local combo = comboMenu.addItem(MenuKeyBind.new("combo key", string.byte(" ")))
local comboSpell = makeSpellMenu(comboMenu)

local harassMenu = submenu.addItem(SubMenu.new("harass"))
local harass = harassMenu.addItem(MenuKeyBind.new("harass key", string.byte("C")))
local harassSpell = makeSpellMenu(harassMenu)

local qRange = GetCastRange(myHero,_Q)
local function castQ( target )
	local target = GetTarget(qRange, DAMAGE_MAGIC)
	if target and CanUseSpell(myHero,_Q) == READY then
		-- CastStartPosVec,EnemyChampionPtr,EnemyMoveSpeed,YourSkillshotSpeed,SkillShotDelay,SkillShotRange,SkillShotWidth,MinionCollisionCheck,AddHitBox;
		local pred = GetPredictionForPlayer(GetOrigin(target),target,GetMoveSpeed(target),math.huge,500,GetCastRange(myHero,_Q),200,false,true)
		if pred.HitChance == 1 then	
			CastSkillShot(_Q,pred.PredPos)
		end
	end
end

local wRange = GetCastRange(myHero,_W)
local function castW( target )
	local target = GetTarget(wRange, DAMAGE_MAGIC)
	if target and CanUseSpell(myHero,_W) == READY then	
		-- CastStartPosVec,EnemyChampionPtr,EnemyMoveSpeed,YourSkillshotSpeed,SkillShotDelay,SkillShotRange,SkillShotWidth,MinionCollisionCheck,AddHitBox;
		local pred = GetPredictionForPlayer(GetOrigin(target),target,GetMoveSpeed(target),math.huge,500,GetCastRange(myHero,_W),800,false,true)
		if pred.HitChance == 1 then	
			CastSkillShot(_W,pred.PredPos)
		end
	end
end

local isCastingE = false
local eRange = GetCastRange(myHero,_E)
local function castE( target )
	local isInDistance = IsInDistance(target, eRange)

	-- open E
	if isInDistance and CanUseSpell(myHero,_E) == READY and not isCastingE then
		CastSpell(_E)
	end

	-- close E
	if not isInDistance and isCastingE then
		CastSpell(_E)
	end
end

local info = ""
local function killableInfo()
	-- no need show killable info when R in cd
	-- if CanUseSpell(myHero,_R) ~= READY then return end

	local rDmg = 100 + GetCastLevel(myHero,_R) * 150 + GetBonusAP(myHero) * 0.6
	-- info = "R dmg : "..rDmg .. "\n"
	info = ""
	for nID, enemy in pairs(GetEnemyHeroes()) do
		if IsObjectAlive(enemy) then
			realdmg = CalcDamage(myHero, enemy, 0, rDmg)
			hp = GetCurrentHP(enemy)
			if realdmg > hp then
				info = info..GetObjectName(enemy)
				if not IsVisible(enemy) then
					info = info.." maybe"
				end
				info = info.."  killable\n"
			end
			-- info = info..GetObjectName(enemy).."    HP:"..hp.."  dmg: "..realdmg.." "..killable.."\n"
		end
  end
  
end

OnDraw(function()
	DrawText(info,40,500,0,0xffff0000) 
end)

OnTick(function(myHero)
	killableInfo()

	local target = GetCurrentTarget()
	if ValidTarget(target) then
		if combo.getValue() then
			if comboSpell[1].getValue() then castQ(target) end
			if comboSpell[2].getValue() then castW(target) end
			if comboSpell[3].getValue() then castE(target) end
		end

		if harass.getValue() then
			if harassSpell[1].getValue() then castQ(target) end
			if harassSpell[2].getValue() then castW(target) end
			if harassSpell[3].getValue() then castE(target) end
		end
	end
end)

local eBuffName = "KarthusDefile"
OnUpdateBuff(function(object,buffProc)
	if object == myHero and buffProc.Name == eBuffName then
		isCastingE = true
	end
end)

OnRemoveBuff(function(object,buffProc)
	if object == myHero and buffProc.Name == eBuffName then
		isCastingE = false
	end
end)

PrintChat("simple karthus script loaded")