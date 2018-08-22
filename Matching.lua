--Made by purerosefallen

os=require('os')

CardList={
	29088922,
	71870152,
	82693917,
	82971335,
	55586621,
}

DIRECTION_UP		=0x1
DIRECTION_DOWN  	=0x2
DIRECTION_LEFT  	=0x4
DIRECTION_RIGHT 	=0x8
DIRECTION_ALL   	=0xf
DIRECTION_UP_LEFT   =0x10
DIRECTION_UP_RIGHT  =0x20
DIRECTION_DOWN_LEFT =0x40
DIRECTION_DOWN_RIGHT=0x80
MAX_DM				=0
START_LP			=8000
PLAY_TIME			=0
SHOW_HINT_TIME		=0
SCORE_ADD_TIME		=0

Debug.SetAIName("Matching Game")
Debug.ReloadFieldBegin(DUEL_ATTACK_FIRST_TURN+DUEL_SIMPLE_AI)
Debug.SetPlayerInfo(0,8000,0,0)
Debug.SetPlayerInfo(1,8000,0,0)
for i=1,20 do
	local loc=LOCATION_GRAVE
	if i>10 then loc=LOCATION_REMOVED end
	for _,code in ipairs(CardList) do
		Debug.AddCard(code,0,0,loc,0,POS_FACEUP_ATTACK,true)
	end
end
BODING_CARD = Debug.AddCard(19162134,1,1,LOCATION_GRAVE,0,POS_FACEUP_ATTACK)
Debug.ReloadFieldEnd()

function Group.MergeCard(g,p,loc,seq)
	local tc=Duel.GetFieldCard(p,loc,seq)
	if tc then
		g:AddCard(tc)
		return true
	else
		return false
	end
end
function Card.GetDirectionGroup(c,direction)
	local loc=c:GetLocation()
	local cp=c:GetControler()
	local seq=c:GetSequence()
	local g=Group.CreateGroup()
	if direction & DIRECTION_LEFT~=0 then
		if cp==0 and seq~=0 then
			g:MergeCard(cp,loc,seq-1)
		end
		if cp==1 and seq~=4 then
			g:MergeCard(cp,loc,seq+1)
		end
	end
	if direction & DIRECTION_RIGHT~=0 then
		if cp==0 and seq~=4 then
			g:MergeCard(cp,loc,seq+1)
		end
		if cp==1 and seq~=0 then
			g:MergeCard(cp,loc,seq-1)
		end
	end
	if direction & DIRECTION_UP~=0 then
		if loc==LOCATION_SZONE and cp==0 then
			g:MergeCard(0,LOCATION_MZONE,seq)
		elseif loc==LOCATION_MZONE and cp==0 then
			g:MergeCard(1,LOCATION_MZONE,4-seq)
		elseif loc==LOCATION_MZONE and cp==1 then
			g:MergeCard(1,LOCATION_SZONE,seq)
		end
	end
	if direction & DIRECTION_DOWN~=0 then
		if loc==LOCATION_SZONE and cp==1 then
			g:MergeCard(1,LOCATION_MZONE,seq)
		elseif loc==LOCATION_MZONE and cp==1 then
			g:MergeCard(0,LOCATION_MZONE,4-seq)
		elseif loc==LOCATION_MZONE and cp==0 then
			g:MergeCard(0,LOCATION_SZONE,seq)
		end
	end
	if direction & DIRECTION_UP_LEFT~=0 then
		if loc==LOCATION_SZONE and cp==0 and seq~=0 then
			g:MergeCard(0,LOCATION_MZONE,seq-1)
		elseif loc==LOCATION_MZONE and cp==0 and seq~=0 then
			g:MergeCard(1,LOCATION_MZONE,5-seq)
		elseif loc==LOCATION_MZONE and cp==1 and seq~=4 then
			g:MergeCard(1,LOCATION_SZONE,seq+1)
		end
	end
	if direction & DIRECTION_UP_RIGHT~=0 then
		if loc==LOCATION_SZONE and cp==0 and seq~=4 then
			g:MergeCard(0,LOCATION_MZONE,seq+1)
		elseif loc==LOCATION_MZONE and cp==0 and seq~=4 then
			g:MergeCard(1,LOCATION_MZONE,3-seq)
		elseif loc==LOCATION_MZONE and cp==1 and seq~=0 then
			g:MergeCard(1,LOCATION_SZONE,seq-1)
		end
	end
	if direction & DIRECTION_DOWN_LEFT~=0 then
		if loc==LOCATION_SZONE and cp==1 and seq~=4 then
			g:MergeCard(1,LOCATION_MZONE,seq+1)
		elseif loc==LOCATION_MZONE and cp==1 and seq~=4 then
			g:MergeCard(0,LOCATION_MZONE,3-seq)
		elseif loc==LOCATION_MZONE and cp==0 and seq~=0 then
			g:MergeCard(0,LOCATION_SZONE,seq-1)
		end
	end
	if direction & DIRECTION_DOWN_RIGHT~=0 then
		if loc==LOCATION_SZONE and cp==1 and seq~=0 then
			g:MergeCard(1,LOCATION_MZONE,seq-1)
		elseif loc==LOCATION_MZONE and cp==1 and seq~=0 then
			g:MergeCard(0,LOCATION_MZONE,5-seq)
		elseif loc==LOCATION_MZONE and cp==0 and seq~=4 then
			g:MergeCard(0,LOCATION_SZONE,seq+1)
		end
	end
	return g
end
function Card.IsCanMoveDownwards(c)
	return c:GetDirectionGroup(DIRECTION_DOWN):GetCount()==0 and (c:IsLocation(LOCATION_MZONE) or c:IsControler(1))
end
function Card.SetItemHint(c)
	local code = c:GetFlagEffectLabel(10000002)
	if code then 
		c:SetHint(CHINT_CARD,code)
		c:SetCardTarget(BODING_CARD)
	end
end
function Card.GetDownwardsPlace(c)
	local loc=c:GetLocation()
	local cp=c:GetControler()
	local seq=c:GetSequence()
	if loc==LOCATION_SZONE and cp==1 then
		local tc=Duel.GetFieldCard(1,LOCATION_MZONE,seq)
		if not tc then
			loc = LOCATION_MZONE
		end
	end
	if loc==LOCATION_MZONE and cp==1 then
		local tc=Duel.GetFieldCard(0,LOCATION_MZONE,4-seq)
		if not tc then
			cp = 0
			seq = 4-seq
		end
	end
	if loc==LOCATION_MZONE and cp==0 then
		local tc=Duel.GetFieldCard(0,LOCATION_SZONE,seq)
		if not tc then
			loc = LOCATION_SZONE
		end
	end
	return loc,cp,seq
end
function Card.MoveDownwards(c)
	local loc,cp,seq = c:GetDownwardsPlace()
	Duel.MoveToField(c,1,cp,loc,POS_FACEUP_ATTACK,true)
	Duel.MoveSequence(c,seq)
	c:SetItemHint()
end
function Card.GetChangedCode(c)
	return c:GetFlagEffectLabel(10000000) or c:GetCode()
end
function Card.IsChangedCode(c,code)
	return c:GetChangedCode()==code
end
function Card.IsNeedToGrave(c)
	local code=c:GetChangedCode()
	return c:GetDirectionGroup(DIRECTION_UP+DIRECTION_DOWN):IsExists(Card.IsChangedCode,2,nil,code) or c:GetDirectionGroup(DIRECTION_LEFT+DIRECTION_RIGHT):IsExists(Card.IsChangedCode,2,nil,code)
end
function Card.CreateSingleCard(code)
	local code=code or CardList[math.random(#CardList)]
	local c=Duel.GetFirstMatchingCard(Card.IsCode,0,LOCATION_GRAVE+LOCATION_REMOVED,0,nil,code) or Duel.CreateToken(0,code)
	c:ResetEffect(c:GetOriginalCode(),RESET_CARD)
	c:ResetFlagEffect(10000001)
	c:ResetFlagEffect(10000002)
	return c
end
function Duel.CheckTop()
	while Duel.GetFieldGroupCount(1,1,LOCATION_SZONE)<5 do
		Duel.MoveToField(Card.CreateSingleCard(),1,0,LOCATION_SZONE,POS_FACEUP_ATTACK,true)
	end
	while Duel.GetFieldGroupCount(1,1,LOCATION_MZONE)<5 do
		Duel.MoveToField(Card.CreateSingleCard(),1,0,LOCATION_MZONE,POS_FACEUP_ATTACK,true)
	end
	while Duel.GetFieldGroupCount(0,0,LOCATION_MZONE)<5 do
		Duel.MoveToField(Card.CreateSingleCard(),1,1,LOCATION_MZONE,POS_FACEUP_ATTACK,true)
	end
	while Duel.GetFieldGroupCount(0,0,LOCATION_SZONE)<5 do
		Duel.MoveToField(Card.CreateSingleCard(),1,1,LOCATION_SZONE,POS_FACEUP_ATTACK,true)
	end
end
function Duel.CheckMoveDownwards()
	local g=Duel.GetMatchingGroup(Card.IsCanMoveDownwards,0,LOCATION_MZONE,LOCATION_ONFIELD,nil)
	while g:GetCount()>0 do
		for tc in aux.Next(g) do
			tc:MoveDownwards()
		end
		g=Duel.GetMatchingGroup(Card.IsCanMoveDownwards,0,LOCATION_MZONE,LOCATION_ONFIELD,nil)
	end
end
function Card.IsAlreadyToGrave(c)
	return c:GetFlagEffect(10000001)>0
end
function Card.IsNotAlreadyToGrave(c)
	return c:GetFlagEffect(10000001)==0
end
function Group.ProcessToGrave(g)
	local ag=g:Filter(Card.IsNotAlreadyToGrave,nil)
	local ct1=ag:GetCount()
	local ct2=0
	for tc in aux.Next(ag) do
		tc:RegisterFlagEffect(10000001,0,0,0)
	end
	for tc in aux.Next(ag) do
		local l=tc:GetFlagEffectLabel(10000002)
		tc:ResetFlagEffect(10000002)
		if l then
			Duel.Hint(HINT_CARD,0,l)
			local f=Item.FunctionList[l]
			local lg=f(tc)
			if lg then
				local n1,n2=lg:ProcessToGrave()
				ct2=ct2+n1+n2
			end
		end
		tc:ResetFlagEffect(10000001)
		Duel.SendtoGrave(tc,REASON_RULE)
	end
	return ct1,ct2
end
function Duel.CheckToGrave()
	local g=Duel.GetMatchingGroup(Card.IsNeedToGrave,0,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	if g:GetCount()==0 then return end
	local tg=g:Clone()
	for tc in aux.Next(g) do
		local code=tc:GetCode()
		local g1=tc:GetDirectionGroup(DIRECTION_UP+DIRECTION_DOWN)
		local g2=tc:GetDirectionGroup(DIRECTION_LEFT+DIRECTION_RIGHT)
		if g1:IsExists(Card.IsCode,2,nil,code) then tg:Merge(g1) end
		if g2:IsExists(Card.IsCode,2,nil,code) then tg:Merge(g2) end
	end
	return tg:ProcessToGrave()
end
function Card.IsNoItem(c)
	return c:GetFlagEffect(10000002)==0
end
function Duel.AddItem(item_type)
	local g=Duel.GetMatchingGroup(Card.IsNoItem,0,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	local tc=g:RandomSelect(0,1):GetFirst()
	if tc then
		local list=Item.List[item_type]
		local code=list[math.random(#list)]
		-- invisible
		tc:RegisterFlagEffect(10000002,0,EFFECT_FLAG_ABSOLUTE_TARGET,0,code,aux.Stringid(code,0))
		tc:SetItemHint()
	end
end
function Duel.CheckScore(ct1,ct2,mul)
	local score1=150*(ct1-2)*mul
	local score2=100*(ct1+mul-3)
	local score3=ct2*50
	if SCORE_ADD_TIME > 0 then
		SCORE_ADD_TIME = SCORE_ADD_TIME - 1
		score1 = score1 * 2
		score2 = score2 * 2
		score3 = score3 * 2
	end
	MAX_DM = math.max(score1,MAX_DM)
	MAX_DM = math.max(score3,MAX_DM)
	Duel.SetLP(0,Duel.GetLP(0)+score2)
	Duel.Damage(1,score3,REASON_RULE)
	Duel.Damage(1,score1,REASON_RULE)
	if mul==1 and ct1>5 then
		Duel.AddItem(2)
	elseif mul==1 and ct1>3 then
		Duel.AddItem(1)
	end
end
function Duel.RefreshField()
	local finish=true
	local mul=1
	while true do
		while Duel.GetFieldGroupCount(0,LOCATION_ONFIELD,LOCATION_ONFIELD)<20 do
			Duel.CheckMoveDownwards()
			Duel.CheckTop()
		end
		local ct1,ct2=Duel.CheckToGrave()
		if ct1 then
			Duel.CheckScore(ct1,ct2,mul)
			mul=mul*2
		else break end
	end
end
function Card.IsExchangable(c,tc)
	c:RegisterFlagEffect(10000000,0,0,0,tc:GetCode())
	tc:RegisterFlagEffect(10000000,0,0,0,c:GetCode())
	local res=Duel.IsExistingMatchingCard(Card.IsNeedToGrave,0,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	c:ResetFlagEffect(10000000)
	tc:ResetFlagEffect(10000000)
	return res
end
function Group.IsFitToExchange(g)
	local c1=g:GetFirst()
	local c2=g:GetNext()
	return c1:IsExchangable(c2)
end
function Card.IsCanBeSelected(c)
	return c:GetDirectionGroup(DIRECTION_ALL):IsExists(Card.IsExchangable,1,c,c)
end
function Group.Exchange(g)
	local c1=g:GetFirst()
	local c2=g:GetNext()
	local loc1=c1:GetLocation()
	local cp1=c1:GetControler()
	local seq1=c1:GetSequence()
	local loc2=c2:GetLocation()
	local cp2=c2:GetControler()
	local seq2=c2:GetSequence()
	local f=Duel.Exile or Duel.SendtoGrave
	f(c1,REASON_RULE)
	Duel.MoveToField(c2,1,cp1,loc1,POS_FACEUP_ATTACK,true)
	Duel.MoveSequence(c2,seq1)
	Duel.MoveToField(c1,1,cp2,loc2,POS_FACEUP_ATTACK,true)
	Duel.MoveSequence(c1,seq2)
	c1:SetItemHint()
	c2:SetItemHint()
end

function Duel.ReloadField()
	for p=0,1 do
		for loc=4,8,4 do
			for i=0,4 do
				Duel.MoveToField(Card.CreateSingleCard(),1,p,loc,POS_FACEUP_ATTACK,true)
			end
		end
	end
end
function Duel.GetScore()
	return math.ceil(math.max(Duel.GetLP(0),0)-math.max(Duel.GetLP(1),0))
end
function Duel.CalculateTime(t1,t2)
	local ltime=t2-t1
	PLAY_TIME=PLAY_TIME+ltime
	SHOW_HINT_TIME=math.max(SHOW_HINT_TIME-ltime,0)
	local mlp=(Duel.GetLP(0)-(ltime*400))
	Duel.SetLP(0,math.max(mlp,0))
	if Duel.GetLP(0)==0 then
		local s = string.format("Game Over.\nStart LP: %d\nMax Damage: %d\nTotal Time: %d second\nScore: %d",START_LP,MAX_DM,math.floor(PLAY_TIME),Duel.GetScore())
		Debug.ShowHint(s)
		return true
	end
	return false
end
function Duel.WinMsg()
	local end_time = os.clock()
	local s = string.format("You Win!\nStart LP: %d\nMax Damage: %d\nTotal Time: %d sec\nScore: %d",START_LP,MAX_DM,math.floor(PLAY_TIME),Duel.GetScore()) 
	Debug.ShowHint(s)
end


function Duel.StartGame()
	Debug.ShowHint("Created By purerosefallen.\nYGOPro1 recommanded.")
	START_LP = Duel.AnnounceNumber(0,8000,16000,40000,80000)
	Duel.SetLP(1,START_LP)
	Duel.ReloadField()
	local RemainTime=Duel.GetLP(0)
	START_TIME = os.clock()
	while true do
		Duel.RefreshField()
		if Duel.GetLP(1) <= 0 then
			Duel.WinMsg()
			return
		end
		local g=Duel.GetFieldGroup(0,LOCATION_ONFIELD,LOCATION_ONFIELD)
		while not g:IsExists(Card.IsCanBeSelected,1,nil) do
			Debug.ShowHint("No more available moves")
			for tc in aux.Next(g) do
				tc:ResetFlagEffect(10000002)
			end
			Duel.SendtoGrave(g,REASON_RULE)
			Duel.ReloadField()
			Duel.RefreshField()
			if Duel.GetLP(1) <= 0 then
				Duel.WinMsg()
				return
			end
			g=Duel.GetFieldGroup(0,LOCATION_ONFIELD,LOCATION_ONFIELD)
		end
		local sg=Group.CreateGroup()
		repeat
			local rs = true
			sg:Clear()
			local t1=os.clock()
			if SHOW_HINT_TIME>0 then
				local g1=g:FilterSelect(0,Card.IsCanBeSelected,1,1,nil)
				sg:Merge(g1)
			else
				local g1=g:Select(0,1,1,nil)
				sg:Merge(g1)
			end
			local tc=sg:GetFirst()
			local tg=tc:GetDirectionGroup(DIRECTION_ALL):Filter(SHOW_HINT_TIME>0 and Card.IsExchangable or aux.TRUE,nil,tc)
			local sc=tg:SelectUnselect(sg,0,false,true,1,1)
			if sc then sg:AddCard(sc) end
			if not sc or sc == tc then rs = false end
			local t2=os.clock()
			if Duel.CalculateTime(t1,t2) then return end
		until (rs and sg:IsFitToExchange())
		sg:Exchange()
	end
end

Item={}
Item.List={
	[1]={
		98380593,
		38430673,
		33767325,
		77754944,
	},
	[2]={
		72403299,
		86361354,
		23171610,
	},
}
function Item.StrikeFilter(c,ec)
	if c:IsAlreadyToGrave() then return false end
	if c:IsControler(ec:GetControler()) then
		return c:IsLocation(ec:GetLocation()) or c:GetSequence()==ec:GetSequence()
	else
		return c:GetSequence()+ec:GetSequence()==4
	end
end
function Item.LightingFilter(c,code)
	return c:IsCode(code) and c:IsNotAlreadyToGrave()
end
Item.FunctionList={
	[98380593]=function(c)
		Duel.Recover(0,2000,REASON_RULE)
	end,
	[38430673]=function(c)
		return Duel.GetMatchingGroup(Item.StrikeFilter,0,LOCATION_ONFIELD,LOCATION_ONFIELD,c,c)
	end,
	[33767325]=function(c)
		Duel.Damage(1,1000,REASON_RULE)
	end,
	[77754944]=function(c)
		return c:GetDirectionGroup(0xff):Filter(Card.IsNotAlreadyToGrave,nil)
	end,
	[72403299]=function(c)
		SHOW_HINT_TIME=SHOW_HINT_TIME+10
	end,
	[86361354]=function(c)
		return Duel.GetMatchingGroup(Item.LightingFilter,0,LOCATION_ONFIELD,LOCATION_ONFIELD,c,c:GetCode())
	end,
	[23171610]=function(c)
		SCORE_ADD_TIME=SCORE_ADD_TIME+10
	end,
}

--math.randomseed(os.time()+os.clock())
for i=1,100 do
	math.random()
end
local e=Effect.GlobalEffect()
e:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
e:SetCode(EVENT_ADJUST)
e:SetOperation(Duel.StartGame)
Duel.RegisterEffect(e,1)
