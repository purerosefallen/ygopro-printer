
--[[message
Universal single script to add or remove cards freely. Good to debug or test your card scripts.
]]
--created by puzzle edit
local json = { _version = "0.1.1" }

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
  [ "\\" ] = "\\\\",
  [ "\"" ] = "\\\"",
  [ "\b" ] = "\\b",
  [ "\f" ] = "\\f",
  [ "\n" ] = "\\n",
  [ "\r" ] = "\\r",
  [ "\t" ] = "\\t",
}

local escape_char_map_inv = { [ "\\/" ] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end


local function escape_char(c)
  return escape_char_map[c] or string.format("\\u%04x", c:byte())
end


local function encode_nil(val)
  return "null"
end


local function encode_table(val, stack)
  local res = {}
  stack = stack or {}

  -- Circular reference?
  if stack[val] then error("circular reference") end

  stack[val] = true

  if val[1] ~= nil or next(val) == nil then
    -- Treat as array -- check keys are valid and it is not sparse
    local n = 0
    for k in pairs(val) do
      if type(k) ~= "number" then
        error("invalid table: mixed or invalid key types")
      end
      n = n + 1
    end
    if n ~= #val then
      error("invalid table: sparse array")
    end
    -- Encode
    for i, v in ipairs(val) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"

  else
    -- Treat as an object
    for k, v in pairs(val) do
      if type(k) ~= "string" then
        error("invalid table: mixed or invalid key types")
      end
      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
  end
end


local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
  -- Check for NaN, -inf and inf
  if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return string.format("%.14g", val)
end


local type_func_map = {
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "boolean" ] = tostring,
}


encode = function(val, stack)
  local t = type(val)
  local f = type_func_map[t]
  if f then
    return f(val, stack)
  end
  error("unexpected type '" .. t .. "'")
end


function json.encode(val)
  return ( encode(val) )
end


-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    res[ select(i, ...) ] = true
  end
  return res
end

local space_chars   = create_set(" ", "\t", "\r", "\n")
local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")

local literal_map = {
  [ "true"  ] = true,
  [ "false" ] = false,
  [ "null"  ] = nil,
}


local function next_char(str, idx, set, negate)
  for i = idx, #str do
    if set[str:sub(i, i)] ~= negate then
      return i
    end
  end
  return #str + 1
end


local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if str:sub(i, i) == "\n" then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error( string.format("%s at line %d col %d", msg, line_count, col_count) )
end


local function codepoint_to_utf8(n)
  -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
  local f = math.floor
  if n <= 0x7f then
    return string.char(n)
  elseif n <= 0x7ff then
    return string.char(f(n / 64) + 192, n % 64 + 128)
  elseif n <= 0xffff then
    return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
  elseif n <= 0x10ffff then
    return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                       f(n % 4096 / 64) + 128, n % 64 + 128)
  end
  error( string.format("invalid unicode codepoint '%x'", n) )
end


local function parse_unicode_escape(s)
  local n1 = tonumber( s:sub(3, 6),  16 )
  local n2 = tonumber( s:sub(9, 12), 16 )
  -- Surrogate pair?
  if n2 then
    return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
  else
    return codepoint_to_utf8(n1)
  end
end


local function parse_string(str, i)
  local has_unicode_escape = false
  local has_surrogate_escape = false
  local has_escape = false
  local last
  for j = i + 1, #str do
    local x = str:byte(j)

    if x < 32 then
      decode_error(str, j, "control character in string")
    end

    if last == 92 then -- "\\" (escape char)
      if x == 117 then -- "u" (unicode escape sequence)
        local hex = str:sub(j + 1, j + 5)
        if not hex:find("%x%x%x%x") then
          decode_error(str, j, "invalid unicode escape in string")
        end
        if hex:find("^[dD][89aAbB]") then
          has_surrogate_escape = true
        else
          has_unicode_escape = true
        end
      else
        local c = string.char(x)
        if not escape_chars[c] then
          decode_error(str, j, "invalid escape char '" .. c .. "' in string")
        end
        has_escape = true
      end
      last = nil

    elseif x == 34 then -- '"' (end of string)
      local s = str:sub(i + 1, j - 1)
      if has_surrogate_escape then
        s = s:gsub("\\u[dD][89aAbB]..\\u....", parse_unicode_escape)
      end
      if has_unicode_escape then
        s = s:gsub("\\u....", parse_unicode_escape)
      end
      if has_escape then
        s = s:gsub("\\.", escape_char_map_inv)
      end
      return s, j + 1

    else
      last = x
    end
  end
  decode_error(str, i, "expected closing quote for string")
end


local function parse_number(str, i)
  local x = next_char(str, i, delim_chars)
  local s = str:sub(i, x - 1)
  local n = tonumber(s)
  if not n then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  return n, x
end


local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars)
  local word = str:sub(i, x - 1)
  if not literals[word] then
    decode_error(str, i, "invalid literal '" .. word .. "'")
  end
  return literal_map[word], x
end


local function parse_array(str, i)
  local res = {}
  local n = 1
  i = i + 1
  while 1 do
    local x
    i = next_char(str, i, space_chars, true)
    -- Empty / end of array?
    if str:sub(i, i) == "]" then
      i = i + 1
      break
    end
    -- Read token
    x, i = parse(str, i)
    res[n] = x
    n = n + 1
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "]" then break end
    if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
  end
  return res, i
end


local function parse_object(str, i)
  local res = {}
  i = i + 1
  while 1 do
    local key, val
    i = next_char(str, i, space_chars, true)
    -- Empty / end of object?
    if str:sub(i, i) == "}" then
      i = i + 1
      break
    end
    -- Read key
    if str:sub(i, i) ~= '"' then
      decode_error(str, i, "expected string for key")
    end
    key, i = parse(str, i)
    -- Read ':' delimiter
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    -- Read value
    val, i = parse(str, i)
    -- Set
    res[key] = val
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "}" then break end
    if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
  end
  return res, i
end


local char_func_map = {
  [ '"' ] = parse_string,
  [ "0" ] = parse_number,
  [ "1" ] = parse_number,
  [ "2" ] = parse_number,
  [ "3" ] = parse_number,
  [ "4" ] = parse_number,
  [ "5" ] = parse_number,
  [ "6" ] = parse_number,
  [ "7" ] = parse_number,
  [ "8" ] = parse_number,
  [ "9" ] = parse_number,
  [ "-" ] = parse_number,
  [ "t" ] = parse_literal,
  [ "f" ] = parse_literal,
  [ "n" ] = parse_literal,
  [ "[" ] = parse_array,
  [ "{" ] = parse_object,
}


parse = function(str, idx)
  local chr = str:sub(idx, idx)
  local f = char_func_map[chr]
  if f then
    return f(str, idx)
  end
  decode_error(str, idx, "unexpected character '" .. chr .. "'")
end


function json.decode(str)
  if type(str) ~= "string" then
    error("expected argument of type string, got " .. type(str))
  end
  local res, idx = parse(str, next_char(str, 1, space_chars, true))
  idx = next_char(str, idx, space_chars, true)
  if idx <= #str then
    decode_error(str, idx, "trailing garbage")
  end
  return res
end

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
	for i=1,12 do
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
		local data={
			lp={
				Duel.GetLP(0),
				Duel.GetLP(1)
			},
			cards={}
		}
		local cid=0
		local id_list={}
		for tc in aux.Next(sg) do
			cid=cid+1
			id_list[tc]=cid
			local cdata={
				id=cid,
				code=tc:GetOriginalCode(),
				controler=tc:GetControler(),
				owner=tc:GetOwner(),
				location=get_save_location(tc),
				sequence=get_save_sequence(tc),
				position=tc:GetPosition(),
				summon_type=tc:GetSummonType(),
				summon_location=tc:GetSummonLocation(),
				overlay_cards={},
				counter={}
			}
			for _,counter in pairs(counter_list) do
				local ct=tc:GetCounter(counter)
				if ct>0 then
					table.insert(cdata.counter,{
						type=counter,
						count=ct
					})
				end
			end
			local og=tc:GetOverlayGroup()
			for oc in aux.Next(og) do
				cid=cid+1
				id_list[oc]=cid
				table.insert(cdata.overlay_cards, {
					id=cid,
					code=oc:GetOriginalCode(),
					owner=oc:GetOwner(),
					summon_type=oc:GetSummonType(),
					summon_location=oc:GetSummonLocation(),
				})
			end
			table.insert(data.cards,cdata)
		end
		local str=json.encode(data)
		local f=io.open("single/printer_data.json","w+")
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
	local f=io.open("single/printer_data.json","r")
	local raw=f:read("*a")
	print(raw)
	local data=json.decode(raw)
	lp0=data.lp[1]
	lp1=data.lp[2]
	for _,cdata in ipairs(data.cards) do
		local tc=Debug.AddCard(cdata.code,cdata.owner,cdata.controler,cdata.location,cdata.sequence,cdata.position,true)
		for _,counter in ipairs(cdata.counter) do
			Debug.PreAddCounter(tc,counter.type,counter.count)
		end
		for _,overlay_cards in ipairs(cdata.overlay_cards) do
			local oc=Debug.AddCard(overlay_cards.code,overlay_cards.owner,cdata.controler,LOCATION_MZONE,cdata.sequence,POS_FACEUP_ATTACK,true)
			Debug.PreSummon(oc,overlay_cards.summon_type,overlay_cards.summon_location)
		end
	end
	f:close()
end)
Debug.SetPlayerInfo(0,lp0,0,0)
Debug.SetPlayerInfo(1,lp1,0,0)
Debug.ReloadFieldEnd()
if load_result then
	Debug.ShowHint("Loaded")
else
	Debug.ShowHint("Load Failed")
end
