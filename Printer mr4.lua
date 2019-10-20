
--[[message
Universal single script to add or remove cards freely. Good to debug or test your card scripts.
]]
--created by puzzle edit
table=require("table")
io=require("io")
LOCATION_EXMZONE=128
EXILE_CARD=256
ADD_COUNTER=512
OVERLAY_CARD=1024
SAVE_FIELD=2048

card_location=LOCATION_GRAVE


custom_list={
[LOCATION_DECK]=67169062,
[LOCATION_HAND]=32807846,
[LOCATION_MZONE]=83764718,
[LOCATION_SZONE]=98494543,
[LOCATION_GRAVE]=81439173,
[LOCATION_REMOVED]=75500286,
[LOCATION_EXTRA]=24094653,
[LOCATION_EXMZONE]=61583217,
[EXILE_CARD]=15256925,
[ADD_COUNTER]=75014062,
[OVERLAY_CARD]=27068117,
[SAVE_FIELD]=11961740,
}
opcode_list={
[LOCATION_DECK]={TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ+TYPE_LINK,OPCODE_ISTYPE,OPCODE_NOT},
[LOCATION_HAND]={TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ+TYPE_LINK,OPCODE_ISTYPE,OPCODE_NOT},
[LOCATION_MZONE]={TYPE_MONSTER,OPCODE_ISTYPE},
[LOCATION_SZONE]={TYPE_SPELL+TYPE_TRAP+TYPE_PENDULUM,OPCODE_ISTYPE},
[LOCATION_GRAVE]=nil,
[LOCATION_REMOVED]=nil,
[LOCATION_EXTRA]={TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ+TYPE_LINK+TYPE_PENDULUM,OPCODE_ISTYPE},
[LOCATION_EXMZONE]={TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ+TYPE_LINK+TYPE_PENDULUM,OPCODE_ISTYPE},
}




Debug.SetAIName("Printer by Nanahira")
Debug.ReloadFieldBegin(DUEL_ATTACK_FIRST_TURN+DUEL_SIMPLE_AI,4)

local g=Group.CreateGroup()
local n=1
function sefilter(c,g)
	return not g:IsContains(c)
end
function ExileGroup(eg)
	local gg=Group.CreateGroup()
	eg:ForEach(function(tc)
		gg:Merge(tc:GetOverlayGroup())
		local e1=Effect.CreateEffect(tc)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CANNOT_TO_HAND)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+0x1fe0000)
		tc:RegisterEffect(e1,true)
		local t={EFFECT_CANNOT_TO_DECK,EFFECT_CANNOT_REMOVE,EFFECT_CANNOT_TO_GRAVE}
		for i,code in pairs(t) do
			local ex=e1:Clone()
			ex:SetCode(code)
			tc:RegisterEffect(ex,true)
		end
	end)
	Duel.SendtoGrave(gg,REASON_RULE)
	Duel.Exile(eg,REASON_RULE)
	eg:ForEach(function(tc)
		tc:ResetEffect(0xfff0000,RESET_EVENT)
	end)
end
local counter_list={}
for line in io.lines('strings.conf') do
	if line:sub(1,8)=="!counter" then
		local p1=line:find("0x")
		local v=tonumber(line:sub(p1,p1+5)) or tonumber(line:sub(p1,p1+4)) or tonumber(line:sub(p1,p1+3)) or tonumber(line:sub(p1,p1+2))
		if v then table.insert(counter_list,v) end
	end
end
function get_save_location(c)
	if c:IsLocation(LOCATION_PZONE) then return LOCATION_PZONE
	else return c:GetLocation() end
end
function get_save_sequence(c)
	if c:IsOnField() then
		local seq=c:GetSequence()
		if c:IsLocation(LOCATION_PZONE) and seq==4 then seq=1 end
		return seq
	else return 0 end
end
function op(e,tp,eg,ep,ev,re,r,rp,c,sg,og)
	local p=e:GetHandler():GetOwner()
	local lc=e:GetLabel()
	local ctt={}
	for i=1,63 do
		table.insert(ctt,i)
	end
	if lc==256 then
		local g=e:GetLabelObject()
		local sg=Duel.GetMatchingGroup(sefilter,0,0x7f,0x7f,nil,g)
		if sg:GetCount()==0 then return end
		local tg=sg:Select(0,1,99,nil)
		ExileGroup(tg)
		return 
	end
	if lc==512 then
		if #counter_list==0 then return end
		local sg=Duel.GetMatchingGroup(Card.IsFaceup,0,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
		if sg:GetCount()==0 then return end
		local tc=sg:Select(0,1,1,nil):GetFirst()
		local counter=Duel.AnnounceNumber(tp,table.unpack(counter_list))	   
		local ct=Duel.AnnounceNumber(0,table.unpack(ctt))
		tc:AddCounter(counter,ct)
		return 
	end
	if lc==1024 then
		local sg=Duel.GetMatchingGroup(Card.IsType,0,LOCATION_MZONE,LOCATION_MZONE,nil,TYPE_XYZ)
		if sg:GetCount()==0 then return end
		local tg=sg:Select(0,1,63,nil)
		local cd=Duel.AnnounceCard(0)   
		local ct=Duel.AnnounceNumber(0,table.unpack(ctt))
		local tc=tg:GetFirst()
		while tc do
			local xg=Group.CreateGroup()
			for i=1,ct do
				local d=Duel.CreateToken(p,cd)
				d:CompleteProcedure()
				xg:AddCard(d)
			end
			Duel.Remove(xg,POS_FACEDOWN,0x20400)
			Duel.Overlay(tc,xg)
			tc=tg:GetNext()
		end
		return
	end
	if lc==2048 then
		local sg=Duel.GetMatchingGroup(sefilter,0,0x7f,0x7f,nil,e:GetLabelObject())
		local lp0,lp1=Duel.GetLP(0),Duel.GetLP(1)
		local str="<pdata>\n<lp>"..lp0..","..lp1.."</lp>\n"
		local tc=sg:GetFirst()
		while tc do
			str=str.."<card><code>"..tc:GetOriginalCode().."</code><player>"..tc:GetControler().."</player><owner>"..tc:GetOwner().."</owner><location>"..get_save_location(tc).."</location><sequence>"..get_save_sequence(tc).."</sequence><position>"..tc:GetPosition().."</position><stype>"..tc:GetSummonType().."</stype><sloc>"..tc:GetSummonLocation().."</sloc></card>\n"
			for i,counter in pairs(counter_list) do
				local ct=tc:GetCounter(counter)
				if ct>0 then
					str=str.."<counter><code>"..counter.."</code><count>"..ct.."</count></counter>\n"
				end
			end
			local og=tc:GetOverlayGroup()
			og:ForEach(function(oc)
				str=str.."<overlaycard><code>"..oc:GetOriginalCode().."</code><owner>"..oc:GetOwner().."</owner><stype>"..oc:GetSummonType().."</stype><sloc>"..oc:GetSummonLocation().."</sloc></overlaycard>\n"
			end)
			tc=sg:GetNext()
		end
		str=str.."</pdata>"
		local f=io.open("PrinterData.txt","w+")
		f:write(str)
		f:close()
		Debug.ShowHint("Saved")
		return
	end
	local ftype=opcode_list[lc]
	local cd=0
	if ftype then
		cd=Duel.AnnounceCardFilter(0,table.unpack(ftype))
	else
		cd=Duel.AnnounceCard(0)
	end
	local ct=Duel.AnnounceNumber(0,table.unpack(ctt))
	for i=1,ct do
		local d=Duel.CreateToken(p,cd)
		if lc==1 then
			Duel.SendtoDeck(d,nil,0,0x20400)
		elseif lc==2 then
			Duel.SendtoHand(d,nil,0x20400)
		elseif lc==4 then
			local pos=nil
			if d:IsType(TYPE_LINK) then
				pos=POS_FACEUP_ATTACK
			else
				pos=Duel.SelectPosition(0,d,15)
			end
			Duel.MoveToField(d,0,p,lc,pos,true)
		elseif lc==8 then
			local pos=nil
			if d:IsType(TYPE_PENDULUM) then
				pos=POS_FACEUP_ATTACK
			else
				pos=Duel.SelectPosition(0,d,POS_ATTACK)
			end
			Duel.MoveToField(d,0,p,lc,pos,true)
		elseif lc==16 then
			Duel.SendtoGrave(d,0x20400)
		elseif lc==32 then
			local pos=Duel.SelectPosition(0,d,POS_ATTACK)
			Duel.Remove(d,pos,0x20400)
		elseif lc==64 then
			if d:IsType(TYPE_PENDULUM) then
				local pos=Duel.SelectPosition(0,d,POS_ATTACK)
				if pos==POS_FACEUP_ATTACK then
					Duel.SendtoExtraP(d,nil,0x20400)
				else
					Duel.SendtoDeck(d,nil,0,0x20400)
				end
			else
				Duel.SendtoDeck(d,nil,0,0x20400)
			end
		elseif lc==128 then
			local pos=nil
			if d:IsType(TYPE_LINK) then
				pos=POS_FACEUP_ATTACK
			else
				pos=Duel.SelectPosition(0,d,15)
			end
			if d:IsType(TYPE_PENDULUM) then
				Duel.SendtoExtraP(d,nil,0x20400)
			else
				Duel.SendtoDeck(d,nil,0,0x20400)
			end
			Duel.MoveToField(d,p,p,LOCATION_MZONE,pos,true)
		end
		d:CompleteProcedure()
	end
end
local original_card_group=Group.CreateGroup()
original_card_group:KeepAlive()
function reg(c,n,g)
	c:ResetEffect(c:GetOriginalCode(),RESET_CARD)
	local effect_list={
		EFFECT_CANNOT_TO_DECK,
		EFFECT_CANNOT_TO_HAND,
		EFFECT_CANNOT_REMOVE,
		EFFECT_CANNOT_SPECIAL_SUMMON,
		EFFECT_CANNOT_SUMMON,
		EFFECT_CANNOT_MSET,
		EFFECT_CANNOT_SSET,
		EFFECT_IMMUNE_EFFECT,
		EFFECT_CANNOT_BE_EFFECT_TARGET,
		EFFECT_CANNOT_CHANGE_CONTROL,
	}
	local effect_list_0={
		EFFECT_CHANGE_TYPE,
	}
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC_G)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_SET_AVAILABLE+EFFECT_FLAG_BOTH_SIDE)
	e2:SetRange(0xff)
	e2:SetLabel(n)
	e2:SetLabelObject(g)
	e2:SetOperation(op)
	c:RegisterEffect(e2)
	for i,v in pairs(effect_list) do
		local e6=Effect.CreateEffect(c)
		e6:SetType(EFFECT_TYPE_SINGLE)
		e6:SetCode(v)
		e6:SetProperty(0x40500+EFFECT_FLAG_IGNORE_IMMUNE)
		e6:SetValue(aux.TRUE)
		c:RegisterEffect(e6)
	end
	for i,v in pairs(effect_list_0) do
		local e6=Effect.CreateEffect(c)
		e6:SetType(EFFECT_TYPE_SINGLE)
		e6:SetCode(v)
		e6:SetProperty(0x40500+EFFECT_FLAG_IGNORE_IMMUNE)
		e6:SetValue(0)
		c:RegisterEffect(e6)
	end
end
for card_value,card_code in pairs(custom_list) do
	local a0=Debug.AddCard(card_code,0,0,card_location,0,POS_FACEUP_ATTACK)
	local a1=Debug.AddCard(card_code,1,1,card_location,0,POS_FACEUP_ATTACK)
	original_card_group:AddCard(a0)
	original_card_group:AddCard(a1)
	reg(a0,card_value,original_card_group)
	reg(a1,card_value,original_card_group)
end
--require("specials/special")
local ex=Effect.GlobalEffect()
ex:SetType(EFFECT_TYPE_FIELD)
ex:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
ex:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
ex:SetTargetRange(LOCATION_SZONE,LOCATION_SZONE)
Duel.RegisterEffect(ex,0)
local ex=Effect.GlobalEffect()
ex:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
ex:SetCode(EVENT_ADJUST)
ex:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
ex:SetLabelObject(original_card_group)
ex:SetOperation(function(e)
	local eg=e:GetLabelObject()
	local tc=eg:GetFirst()
	while tc do
		if not tc:IsLocation(LOCATION_GRAVE) then
			Duel.SendtoGrave(tc,REASON_RULE+REASON_RETURN)
		end
		tc=eg:GetNext()
	end
end)
Duel.RegisterEffect(ex,0)
local ex=Effect.GlobalEffect()
ex:SetType(EFFECT_TYPE_FIELD)
ex:SetCode(EFFECT_TRAP_ACT_IN_HAND)
ex:SetTargetRange(LOCATION_HAND,LOCATION_HAND)
Duel.RegisterEffect(ex,0)
local ex=Effect.GlobalEffect()
ex:SetType(EFFECT_TYPE_FIELD)
ex:SetCode(EFFECT_HAND_LIMIT)
ex:SetTargetRange(1,1)
ex:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
ex:SetValue(100)
Duel.RegisterEffect(ex,0)
local ex=Effect.GlobalEffect()
ex:SetType(EFFECT_TYPE_FIELD)
ex:SetCode(EFFECT_EXTRA_TOMAIN_KOISHI)
ex:SetTargetRange(1,1)
ex:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
ex:SetValue(100)
Duel.RegisterEffect(ex,0)

local lp0,lp1=8000,8000
local load_result=pcall(function()
	local tcp,ts,tempc
	for line in io.lines('PrinterData.txt') do
		local lp00,lp01=line:find("<lp>")
		local lp10,lp11=line:find("</lp>")
		if lp00 and lp01 and lp10 and lp11 then
			local slp=line:sub(lp01+1,lp10-1)
			if slp then
				local sp=slp:find(",")
				local slp0=slp:sub(1,sp-1)
				local slp1=slp:sub(sp+1,#slp)
				if slp0 then lp0=tonumber(slp0) or lp0 end
				if slp1 then lp1=tonumber(slp1) or lp1 end
			end
		elseif line:find("<card>") and line:find("</card>") then
			local cd,cp,op,l,s,pos,stype,sloc
			local cd1,cd2=line:find("<code>")
			local cd3,cd4=line:find("</code>")
			if cd1 and cd2 and cd3 and cd4 then
				local scd=line:sub(cd2+1,cd3-1)
				if scd then cd=tonumber(scd) end
			end
			local cp1,cp2=line:find("<player>")
			local cp3,cp4=line:find("</player>")
			if cp1 and cp2 and cp3 and cp4 then
				local scp=line:sub(cp2+1,cp3-1)
				if scp then cp=tonumber(scp) end
			end
			local op1,op2=line:find("<owner>")
			local op3,op4=line:find("</owner>")
			if op1 and op2 and op3 and op4 then
				local sop=line:sub(op2+1,op3-1)
				if sop then op=tonumber(sop) end
			end
			local l1,l2=line:find("<location>")
			local l3,l4=line:find("</location>")
			if l1 and l2 and l3 and l4 then
				local sl=line:sub(l2+1,l3-1)
				if sl then l=tonumber(sl) end
			end
			local s1,s2=line:find("<sequence>")
			local s3,s4=line:find("</sequence>")
			if s1 and s2 and s3 and s4 then
				local ss=line:sub(s2+1,s3-1)
				if ss then s=tonumber(ss) end
			end
			local pos1,pos2=line:find("<position>")
			local pos3,pos4=line:find("</position>")
			if pos1 and pos2 and pos3 and pos4 then
				local spos=line:sub(pos2+1,pos3-1)
				if spos then pos=tonumber(spos) end
			end
			local stype1,stype2=line:find("<stype>")
			local stype3,stype4=line:find("</stype>")
			if stype1 and stype2 and stype3 and stype4 then
				local sstype=line:sub(stype2+1,stype3-1)
				if sstype then stype=tonumber(sstype) end
			end
			local sloc1,sloc2=line:find("<sloc>")
			local sloc3,sloc4=line:find("</sloc>")
			if sloc1 and sloc2 and sloc3 and sloc4 then
				local ssloc=line:sub(sloc2+1,sloc3-1)
				if ssloc then sloc=tonumber(ssloc) end
			end
			if cd and cp and op and l and s and pos then
				local tc=Debug.AddCard(cd,op,cp,l,s,pos,true)
				tcp,ts,tempc=cp,s,tc
				if stype and sloc then
					Debug.PreSummon(tc,stype,sloc)
				end
			end   
		elseif line:find("<overlaycard>") and line:find("</overlaycard>") and tcp and ts then
			local cd,op,stype,sloc
			local cd1,cd2=line:find("<code>")
			local cd3,cd4=line:find("</code>")
			if cd1 and cd2 and cd3 and cd4 then
				local scd=line:sub(cd2+1,cd3-1)
				if scd then cd=tonumber(scd) end
			end
			local op1,op2=line:find("<owner>")
			local op3,op4=line:find("</owner>")
			if op1 and op2 and op3 and op4 then
				local sop=line:sub(op2+1,op3-1)
				if sop then op=tonumber(sop) end
			end
			local stype1,stype2=line:find("<stype>")
			local stype3,stype4=line:find("</stype>")
			if stype1 and stype2 and stype3 and stype4 then
				local sstype=line:sub(stype2+1,stype3-1)
				if sstype then stype=tonumber(sstype) end
			end
			local sloc1,sloc2=line:find("<sloc>")
			local sloc3,sloc4=line:find("</sloc>")
			if sloc1 and sloc2 and sloc3 and sloc4 then
				local ssloc=line:sub(sloc2+1,sloc3-1)
				if ssloc then sloc=tonumber(ssloc) end
			end
			if cd and op then
				local tc=Debug.AddCard(cd,op,tcp,LOCATION_MZONE,ts,POS_FACEUP_ATTACK,true)
				if stype and sloc then
					Debug.PreSummon(tc,stype,sloc)
				end
			end
		elseif line:find("<counter>") and line:find("</counter>") and tempc then
			local tp,ct
			local tp1,tp2=line:find("<code>")
			local tp3,tp4=line:find("</code>")
			if tp1 and tp2 and tp3 and tp4 then
				local stp=line:sub(tp2+1,tp3-1)
				if stp then tp=tonumber(stp) end
			end
			local ct1,ct2=line:find("<count>")
			local ct3,ct4=line:find("</count>")
			if ct1 and ct2 and ct3 and ct4 then
				local sct=line:sub(ct2+1,ct3-1)
				if sct then ct=tonumber(sct) end
			end
			if tp and ct then
				Debug.PreAddCounter(tempc,tp,ct)
			end
		end
	end
end)
Debug.SetPlayerInfo(0,lp0,0,0)
Debug.SetPlayerInfo(1,lp1,0,0)
Debug.ReloadFieldEnd()
if load_result then
	Debug.ShowHint("Loaded")
else
	Debug.ShowHint("Load Failed")
end
