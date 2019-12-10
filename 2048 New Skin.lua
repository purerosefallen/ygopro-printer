Debug.SetAIName("2048")
Debug.ReloadFieldBegin(DUEL_ATTACK_FIRST_TURN+DUEL_SIMPLE_AI,4)
Debug.SetPlayerInfo(0,8000,0,0)
Debug.SetPlayerInfo(1,8000,0,0)



DIRECTION_UP		=0x1
DIRECTION_DOWN		=0x2
DIRECTION_LEFT		=0x4
DIRECTION_RIGHT		=0x8

_os=os or package.preload.os
if _os then
	math.randomseed(_os.time())
end

CardList={
	33700749,
	12007099,
	1110198,
	33310023,
	65050005,
	14000457,
	37564504,
	11200018,
	81040023,
	60159914,
	10906010,
	75646123,
}

for i=1,16 do
	local loc=LOCATION_GRAVE
	if i>8 then loc=LOCATION_REMOVED end
	for _,code in ipairs(CardList) do
		local c=Debug.AddCard(code,i%2,i%2,loc,0,POS_FACEUP_ATTACK,true)
		c:ReplaceEffect(80316585,0,0)
	end
end

FORBIDDEN_CARDS=Group.FromCards(
	Debug.AddCard(26801001,0,0,LOCATION_SZONE,2,POS_FACEUP_ATTACK,true),
	Debug.AddCard(26801001,1,1,LOCATION_SZONE,2,POS_FACEUP_ATTACK,true)
)
FORBIDDEN_CARDS:KeepAlive()

DIRECTION_CARDS=Group.CreateGroup()
DIRECTION_CARDS:KeepAlive()
UP_CARD=	Debug.AddCard(20100212,1,1,LOCATION_MZONE,2,POS_FACEUP_ATTACK,true)
DOWN_CARD=	Debug.AddCard(20100212,0,0,LOCATION_MZONE,2,POS_FACEUP_ATTACK,true)
LEFT_CARD=	Debug.AddCard(33400006,0,0,LOCATION_MZONE,5,POS_FACEUP_ATTACK,true)
RIGHT_CARD=	Debug.AddCard(33400006,1,1,LOCATION_MZONE,5,POS_FACEUP_ATTACK,true)

DIRECTION_LIST_REV={}

DIRECTION_LIST_REV[UP_CARD]=DIRECTION_UP
DIRECTION_LIST_REV[DOWN_CARD]=DIRECTION_DOWN
DIRECTION_LIST_REV[LEFT_CARD]=DIRECTION_LEFT
DIRECTION_LIST_REV[RIGHT_CARD]=DIRECTION_RIGHT

DIRECTION_LIST={
	DIRECTION_UP=	UP_CARD,
	DIRECTION_DOWN=	DOWN_CARD,
	DIRECTION_LEFT=	LEFT_CARD,
	DIRECTION_RIGHT=RIGHT_CARD,
}

for _,c in pairs(DIRECTION_LIST) do
	DIRECTION_CARDS:AddCard(c)
end

Debug.ReloadFieldEnd()

function Duel.NewPlace(tx,ty)
	return {
		x=tx,
		y=ty,
		Equal=function(loc1,loc2)
			return loc1.x==loc2.x and loc1.y==loc2.y
		end,
		Format=function(loc)
			for lo=LOCATION_MZONE,LOCATION_SZONE,4 do
				for p=0,1 do
					for seq=0,1 do
						if Duel.GetPlace(p,lo,seq):Equal(loc) then
							return p,lo,seq
						end
					end
					for seq=3,4 do
						if Duel.GetPlace(p,lo,seq):Equal(loc) then
							return p,lo,seq
						end
					end
				end
			end
		end,
		IsUsable=function(loc)
			local p,lo,seq=loc:Format()
			return Duel.CheckLocation(p,lo,seq)
		end,
		GetCard=function(loc)
			local p,lo,seq=loc:Format()
			return Duel.GetFieldCard(p,lo,seq)
		end,
		Add=function(loc1,loc2)
			return Duel.NewPlace(loc1.x+loc2.x,loc1.y+loc2.y)
		end,
		Sub=function(loc1,loc2)
			return Duel.NewPlace(loc1.x-loc2.x,loc1.y-loc2.y)
		end,
		Mul=function(loc1,m)
			return Duel.NewPlace(loc1.x*m,loc1.y*m)
		end,
		IsInBoard=function(loc)
			return loc.x>=0 and loc.x<=3
				and loc.y>=0 and loc.y<=3
		end,
	}
end
function Duel.GetPlace(p,loc,tseq)
	local res=Duel.NewPlace(0,0)
	local seq=tseq
	if p==1 then
		seq=4-seq
		if loc==LOCATION_MZONE then
			res.y=2
		else
			res.y=3
		end
	else
		if loc==LOCATION_MZONE then
			res.y=1
		else
			res.y=0
		end
	end
	res.x=seq
	if res.x>2 then
		res.x=res.x-1
	end
	return res
end
function Duel.GetDirectionDiff(dir,m)
	tm=m or 1
	if dir==DIRECTION_UP then
		return Duel.NewPlace(0,tm)
	elseif dir==DIRECTION_DOWN then
		return Duel.NewPlace(0,-tm)
	elseif dir==DIRECTION_LEFT then
		return Duel.NewPlace(-tm,0)
	elseif dir==DIRECTION_RIGHT then
		return Duel.NewPlace(tm,0)
	end
	error("Invalid direction",2)
end
function Duel.GetFreePlaces()
	local res={}
	for x=0,3 do
		for y=0,3 do
			local loc=Duel.NewPlace(x,y)
			if loc:IsUsable() then
				table.insert(res,loc)
			end
		end
	end
	return res
end
function Duel.NewCard(lv)
	return Duel.GetFirstMatchingCard(Card.IsLevel,0,LOCATION_GRAVE+LOCATION_REMOVED,LOCATION_GRAVE+LOCATION_REMOVED,nil,math.min(lv,12))
end

function Card.GetPlace(c)
	return Duel.GetPlace(c:GetControler(),c:GetLocation(),c:GetSequence())
end

function Card.MoveToPlace(c,loc)
	if c:GetPlace():Equal(loc) or not loc:IsInBoard() then return end
	local p,lo,seq=loc:Format()
	if not Duel.CheckLocation(p,lo,seq) then return end
	Duel.MoveToField(c,1,p,lo,POS_FACEUP_ATTACK,true,0x1<<seq)
	Duel.MoveSequence(c,seq)
end
function Card.MergeWith(c,tc)
	local loc=tc:GetPlace()
	local lv=c:GetOriginalLevel()
	Duel.SendtoGrave(tc,REASON_RULE)
	c:MoveToPlace(loc)
	Duel.SendtoGrave(c,REASON_RULE)
	local nc=Duel.NewCard(lv+1)
	nc:MoveToPlace(loc)
	MERGED_CARDS:AddCard(nc)
	return nc
end
function Card.GetNearestCard(c,dir)
	local loc=c:GetPlace()
	local diff=Duel.GetDirectionDiff(dir)
	local tc=nil
	while not tc do
		local tloc=loc:Add(diff)
		if not tloc:IsInBoard() then break end
		loc=tloc
		tc=loc:GetCard()
	end
	return tc,loc
end
MOVED_CARDS=Group.CreateGroup()
MOVED_CARDS:KeepAlive()
MERGED_CARDS=Group.CreateGroup()
MERGED_CARDS:KeepAlive()
function Card.IsMergableWith(c,tc)
	if MERGED_CARDS:IsContains(c) or MERGED_CARDS:IsContains(tc) then return false end
	return c:GetOriginalLevel()==tc:GetOriginalLevel()
end
function Card.IsCanMoveToDirection(c,dir,moved)
	if DIRECTION_CARDS:IsContains(c) or FORBIDDEN_CARDS:IsContains(c) then return false end
	if not dir then
		error("Direction is missing",2)
		return false
	end
	local loc=c:GetPlace():Add(Duel.GetDirectionDiff(dir))
	if not loc:IsInBoard() then return false end
	local tc=loc:GetCard()
	return not tc or (not moved and c:IsMergableWith(tc))
end
function Duel.IsCanMoveToDirection(dir)
	return Duel.IsExistingMatchingCard(Card.IsCanMoveToDirection,0,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil,dir)
end
function Card.MoveToDirection(c,dir,moved)
	if MOVED_CARDS:IsContains(c) or not c:IsCanMoveToDirection(dir,moved) then return end
	local tc,loc=c:GetNearestCard(dir)
	if not tc then
		c:MoveToPlace(loc)
	elseif not moved and c:IsMergableWith(tc) then
		local nc=c:MergeWith(tc)
		nc:MoveToDirection(dir,true)
		return nc
	else
		c:MoveToPlace(loc:Sub(Duel.GetDirectionDiff(dir)))
	end
	return c
end
function Duel.GenerateRandom()
	local free=Duel.GetFreePlaces()
	local loc=free[math.random(#free)]
	Duel.NewCard(math.random(2)):MoveToPlace(loc)
end
function Duel.MoveToDirection(dir)
	if not Duel.IsCanMoveToDirection(dir) then return end
	if dir&(DIRECTION_LEFT+DIRECTION_RIGHT)>0 then
		local st=dir==DIRECTION_LEFT and 0 or 3
		local ed=dir==DIRECTION_RIGHT and 0 or 3
		local sp=st>ed and -1 or 1
		for x=st,ed,sp do
			for y=0,3 do
				local c=Duel.NewPlace(x,y):GetCard()
				if c then
					local nc=c:MoveToDirection(dir)
					if nc then MOVED_CARDS:AddCard(nc) end
				end
			end
		end
	elseif dir&(DIRECTION_UP+DIRECTION_DOWN)>0 then
		local st=dir==DIRECTION_DOWN and 0 or 3
		local ed=dir==DIRECTION_UP and 0 or 3
		local sp=st>ed and -1 or 1
		for y=st,ed,sp do
			for x=0,3 do
				local c=Duel.NewPlace(x,y):GetCard()
				if c then
					local nc=c:MoveToDirection(dir)
					if nc then MOVED_CARDS:AddCard(nc) end
				end
			end
		end
	end
	MOVED_CARDS:Clear()
	MERGED_CARDS:Clear()
end

function Duel.Process(e)
	Debug.ShowHint("YGOPro 2048\nMade by Nanahira")
	for i=1,2 do
		Duel.GenerateRandom()
	end
	while true do
		local g=DIRECTION_CARDS:Filter(function(c)
			return Duel.IsCanMoveToDirection(DIRECTION_LIST_REV[c])
		end,nil)
		if #g==0 then
			Debug.ShowHint("Game over!")
			Duel.SetLP(0,0)
			break
		end
		Duel.MoveToDirection(DIRECTION_LIST_REV[g:Select(0,1,1,nil):GetFirst()])
		if Duel.IsExistingMatchingCard(function(c)
			return c:GetOriginalLevel()==12
		end,0,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) then
			Debug.ShowHint("You win!")
			Duel.SetLP(1,0)
			break
		else
			Duel.GenerateRandom()
		end
	end
	e:Reset()
end


for i=1,100 do
	math.random()
end
local e=Effect.GlobalEffect()
e:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
e:SetCode(EVENT_ADJUST)
e:SetOperation(Duel.Process)
Duel.RegisterEffect(e,1)
