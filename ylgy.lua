--[[message
羊了个羊！
By Nanahira @Nana_Yumesaki
]]

------

if os then
  --math.randomseed(os.time())
end

for i=1,100 do
	math.random()
end

Debug.SetAIName("羊了个羊")
Debug.ReloadFieldBegin(DUEL_ATTACK_FIRST_TURN+DUEL_SIMPLE_AI)
Debug.SetPlayerInfo(0,8000,0,0)
Debug.SetPlayerInfo(1,8000,0,0)

cardCodes = {
  46986414,
  26077387,
  55410871,
  12580477,
  36975314,
  88820235,
  44508094,
  84013237,
  16178681,
  5043010,
}
local eachCardCount = 15

function shuffleArray(arr)
  local n = #arr
  while n > 2 do
    local k = math.random(n)
    arr[n], arr[k] = arr[k], arr[n]
    n = n - 1
  end
  return arr
end

cards = {}
for i = 1, 9 do
  for _,card in ipairs(cardCodes) do
    table.insert(cards, card)
  end
end

shuffleArray(cards)

function getPlayerAndSequence(seq)
  local p = 0
  if seq > 6 then
    p = 1
    seq = seq - 6
  end
  return p, seq - 1
end

local fieldCards = {}
local fieldCardGroup = Group.CreateGroup()
fieldCardGroup:KeepAlive()
for i = 1, 12 do
  local p, seq = getPlayerAndSequence(i)
  fieldCards[i] = Debug.AddCard(62967433,p,p,LOCATION_MZONE,seq,POS_FACEDOWN_DEFENSE,true)
  fieldCardGroup:AddCard(fieldCards[i])
end

function addCard(card, i)
  local p, seq = getPlayerAndSequence(i)
  Debug.AddCard(card,0,p,LOCATION_MZONE,seq,POS_FACEUP_ATTACK,true)
end

for _,card in ipairs(cards) do
  addCard(card, math.random(12))
end

function Card.GetSurfaceCard(c)
  local og = c:GetOverlayGroup()
  if #og == 0 then
    return nil
  end
  return og:GetMaxGroup(Card.GetSequence):GetFirst()  
end

function getLeftmostZone()
  for p = 0, 1 do
    for i = 0, 4 do
      local c = Duel.GetFieldCard(p, LOCATION_SZONE, i)
      if c == nil then
        return p, 0x1 << i
      end
    end
  end
end

function Card.ProcessSelected(c)
  local sc = c:GetSurfaceCard()
  local tp, tz = getLeftmostZone()
  Duel.MoveToField(sc, tp, tp, LOCATION_SZONE, POS_FACEUP_ATTACK, true, tz)
  local hg = Duel.GetFieldGroup(0, LOCATION_SZONE, LOCATION_SZONE)
  local sameCodeCards = hg:Filter(Card.IsCode, nil, sc:GetCode())
  if #sameCodeCards >= 3 then
    Duel.SendtoGrave(sameCodeCards, REASON_RULE)
  elseif #hg >= 7 then
    Duel.SetLP(0, 0)
    Debug.ShowHint("槽位已满，你输了")
    return true
  end
  return false
end

function process()
  Debug.ShowHint("羊了个羊！选择卡片来把最上面的卡片放入手卡。7 个手卡后，你将会输掉游戏。By Nanahira @Nana_Yumesaki")
  while true do
    local fg = fieldCardGroup:Filter(function(c) return c:GetSurfaceCard() ~= nil end, nil)
    if #fg == 0 then
      Duel.SetLP(1, 0)
      Debug.ShowHint("你赢了")
      return
    end
    local fc = fg:Select(0, 1, 1, nil):GetFirst()
    if fc:ProcessSelected() then
      return
    end
  end
end

Debug.ReloadFieldEnd()
local e=Effect.GlobalEffect()
e:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
e:SetCode(EVENT_ADJUST)
e:SetOperation(function(e)
  process()
  e:Reset()
end)
Duel.RegisterEffect(e,1)
