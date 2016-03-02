
-- Requirement
require "Inspired" 
require "OpenPredict"
print("<font color='#FFFFFF'>Sua doi cua </font><font color='#3366FF'>Cloud </font><font color='#FFFFFF'>, </font><font color='#54FF9F'>Deftsu </font><font color='#FFFFFF'>chua xin phep truoc </font><font color='#912CEE'>Inspired </font><font color='#FFFFFF'> Sr </font>")

class "RxKarthus"
function RxKarthus:__init()
---- Create Menu ----
Karthus = MenuConfig("Karthus", "Rx Karthus")
tslowhp = TargetSelector(GetCastRange(myHero, _Q), 8, DAMAGE_MAGIC) -- 8 = TARGET_LOW_HP

-- [[ Combo ]] --
Karthus:Menu("cb", "Karthus Combo")
Karthus.cb:Boolean("QCB", "Use Q", true)
Karthus.cb:Boolean("WCB", "Use W", true)
Karthus.cb:Boolean("ECB", "Use E", true)

-- [[ Harass ]] --
Karthus:Menu("hr", "Harass")
Karthus.hr:Boolean("HrQ", "Use Q", true)
Karthus.hr:Slider("HrMana", "Enable Harass if %My MP >=", 30, 0, 100, 1)

-- [[ LaneJungle Clear ]] --
Karthus:Menu("FreezeLane", "Lane Jungle Clear")
Karthus.FreezeLane:Slider("LJCMana", "Enable if %My MP >=", 20, 0, 100, 1)
Karthus.FreezeLane:Boolean("QLJC", "Use Q", true)
Karthus.FreezeLane:Boolean("ELJC", "Use E", true)
Karthus.FreezeLane:Slider("CELC", "Use E if Minions Around >=", 3, 1, 10, 1)

-- [[ LastHit ]] --
Karthus:Menu("LHMinion", "Last Hit Minion")
Karthus.LHMinion:Boolean("QLH", "Use Q Last Hit", true)
Karthus.LHMinion:Slider("LHMana", "LastHit if %My MP >=", 10, 0, 100, 1)

-- [[ Misc ]] --
Karthus:Menu("Miscset", "Misc")
Karthus.Miscset:Boolean("AutoSkillUpQ", "Auto Lvl Up Q-E-W", true)
Karthus.Miscset:Boolean("StopE", "Auto Stop E", true)
Karthus.Miscset:Info("SEI", "Auto Stop E if no creeps/enemy in E range")
Karthus.Miscset:Info("StopEInfo", "If you want to spam Seraph's Embrace you must OFF it")
Karthus.Miscset:Slider("hc", "Q HitChance", 2, 1, 10, 0.5)
PermaShow(Karthus.Miscset.StopE)

Karthus:Info("info1", "Use PActivator for Auto Use Items")
Callback.Add("Tick", function(myHero) self:Tick(myHero) end)
Callback.Add("Draw", function(myHero) self:Drawings(myHero) end)
end

--- [[ Location ]] ---
local QRange, WRange, ERange, pn = GetCastRange(myHero, _Q), GetCastRange(myHero, _W), GetCastRange(myHero, _E), '%'
local KarthusQ, leveltable = { delay = 0.75, speed = math.huge, width = 160, range = QRange }, {_Q, _E, _Q, _W, _Q , _R, _Q , _E, _Q , _E, _R, _E, _E, _W, _W, _R, _W, _W}
local function IsInRange(unit, range)
    return unit.valid and IsInDistance(unit, range)
end

local function RCheck()
 if IsReady(_R) or (GotBuff(myHero, "karthusfallenonecastsound") > 0) then return true else return false end
end

local function QCheck(unit, pos)
 local Mno, Enm = MinionsAround(pos, 183, MINION_ENEMY), CountObjectsNearPos(pos, 175, 175, GetEnemyHeroes(), MINION_ENEMY)
 local CheckQDmg = GetCastLevel(myHero, _Q)*40 + 40 + 0.6*myHero.ap
 if GetDistance(unit.pos, pos) <= 167 then
  if Mno + Enm == 1 then return CheckQDmg else return CheckQDmg/2 end
 else
  if Mno + Enm < 1 then return CheckQDmg else return CheckQDmg/2 end
 end
end

function RxKarthus:Tick(myHero)
 if IOW:Mode() == "Combo" then self:Combo()
 elseif IOW:Mode() == "Harass" then self:Harass()
 elseif IOW:Mode() == "LaneClear" then self:LaneClear() self:JungleClear()
 elseif IOW:Mode() == "LastHit" then self:LastHit()
 end
 self:KillSteal()
 if GotBuff(myHero, "KarthusDefile") >= 1 then self:AutoStopE() end
 self:AutoLvlUp()
end

function RxKarthus:Combo(target)
 local target = tslowhp:GetTarget()
 if target then
  local WPred = GetPredictionForPlayer(myHeroPos(),target,GetMoveSpeed(target),math.huge,250,WRange,100,false,true)
  local QPred = GetCircularAOEPrediction(target, KarthusQ)
  if IsReady(_W) and myHero.mana >= 130 and IsInRange(target, WRange) and WPred.HitChance >= 1 and Karthus.cb.WCB:Value() then
   CastSkillShot(_W, WPred.PredPos)
  end
  
  if IsReady(_E) and IsInRange(target, ERange) and GotBuff(myHero, "KarthusDefile") <= 0 and Karthus.cb.ECB:Value() then
   CastSpell(_E)
  end
	
  if IsReady(_Q) and IsInRange(target, QRange) and QPred and QPred.hitChance >= Karthus.Miscset.hc:Value()/10 and Karthus.cb.QCB:Value() then
   CastSkillShot(_Q, QPred.castPos)
  end
 end
end

function RxKarthus:LaneClear()
 for C=1, minionManager.maxObjects do
 local creep = minionManager.objects[C]
  if GetPercentMP(myHero) >= Karthus.FreezeLane.LJCMana:Value() and creep.team == MINION_ENEMY and creep.health > 0 then
   if IsInRange(creep, QRange) and IsReady(_Q) and Karthus.FreezeLane.QLJC:Value() then
   local QPred = GetCircularAOEPrediction(creep, KarthusQ)
    if creep.health < myHero:CalcMagicDamage(creep, GetCastLevel(myHero, _Q)*40 + 40 + 0.6*myHero.ap) +myHero.damage/2+12+7.5*GetLevel(myHero) then
    local QDmgPredict, ac = GetHealthPrediction(creep, 750)
     if QDmgPredict > 0 and QPred and QDmgPredict < myHero:CalcMagicDamage(creep, QCheck(creep, QPred.castPos)) then
      CastSkillShot(_Q, QPred.castPos)
     end
    else
     if QPred then DelayAction(function() CastSkillShot(_Q, QPred.castPos) end, 350) end
    end
   end
	
    if IsReady(_E) and IsInRange(creep, ERange) and Karthus.FreezeLane.ELJC:Value() and (MinionsAround(myHero.pos, ERange, MINION_ENEMY) >= Karthus.FreezeLane.CELC:Value() or MinionsAround(myHero.pos, ERange, MINION_JUNGLE) >= 1) and GotBuff(myHero, "KarthusDefile") <= 0 then
     CastSpell(_E)	
    end
  end
 end
end

function RxKarthus:JungleClear()
 for C, creep in pairs(minionManager.objects) do
  if GetPercentMP(myHero) >= Karthus.FreezeLane.LJCMana:Value() and creep.team == MINION_JUNGLE and creep.health > 0 and IsInRange(creep, QRange) and IsReady(_Q) and Karthus.FreezeLane.QLJC:Value() then
   local QPred = GetCircularAOEPrediction(creep, KarthusQ)
   CastSkillShot(_Q, QPred.castPos)
  end
 end
end

function RxKarthus:LastHit()
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


function RxKarthus:AutoStopE()
 if IOW:Mode() == "Combo" and EnemiesAround(myHero.pos, ERange) <= 0 then CastSpell(_E) end
 if IOW:Mode() == "LaneClear" and MinionsAround(myHero.pos, ERange, MINION_ENEMY) < Karthus.FreezeLane.CELC:Value() and MinionsAround(myHero.pos, ERange, MINION_JUNGLE) < 1 then CastSpell(_E) end
 if Karthus.Miscset.StopE:Value() and MinionsAround(myHero.pos, ERange, MINION_ENEMY) < 2 and MinionsAround(myHero.pos, ERange, MINION_JUNGLE) < 1 and EnemiesAround(myHero.pos, ERange) <= 0 then CastSpell(_E) end
end

function RxKarthus:AutoLvlUp()
 if Karthus.Miscset.AutoSkillUpQ:Value() then
  LevelSpell(leveltable[GetLevel(myHero)])
 end
end


if myHero.charName == "Karthus" then RxKarthus() end
PrintChat(string.format("<font color='#FF0000'>Mega Karthus by Trnthi </font><font color='#FFFF00'>Version 1.0 Da load xong </font><font color='#08F7F3'>Hen xui %s</font>",myHero.name)) 
print("Recommend Farm with LastHit.")