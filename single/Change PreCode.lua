local script={"#!/bin/bash"}
function Auxiliary.SplitData(inputstr)
	local t={}
	for str in string.gmatch(inputstr,"([^|]+)") do
		table.insert(t,str)
	end
	return t
end
function Auxiliary.LoadDB(db)
	local res={}
	local res_rev={}
	local file=io.popen("bash echo \"select id,name from texts;\" | sqlite3 "..db)
	for line in file:lines() do
		local data=Auxiliary.SplitData(line)
		local code=tonumber(data[1])
		local name=data[2]
		res[code]=name
		res_rev[name]=code
	end
	file:close()
	return res,res_rev
end
function Auxiliary.Replace(old,new)
	if not old then
		Debug.Message(new.." not found.")
		return
	end
	if old<100000000 then return end
	Debug.Message("Will replace "..old.." to "..new..".")
	table.insert(script,"mv -f ./script/c"..old..".lua ./script/c"..new..".lua")
	table.insert(script,"mv -f ./pics/"..old..".jpg ./pics/"..new..".jpg")
	table.insert(script,"sed -i 's/"..old.."/"..new.."/g' ./script/c*.lua")
	for i=1,9 do
		table.insert(script,"sed -i 's/"..(old+i*100).."/"..new+i.."/g' ./script/c*.lua")	
		table.insert(script,"sed -i 's/"..new.."+"..i.."00/"..new+i.."/g' ./script/c*.lua")		
	end
end
function Auxiliary.Output()
	local f=io.open("replace.sh","w")
	for _,s in ipairs(script) do
		f:write(s)
		f:write("\n")
	end
	f:close()
end

local old,old_rev=Auxiliary.LoadDB("ygopro-pre-data/expansions/pre-release.cdb")
local new,new_rev=Auxiliary.LoadDB("cards.cdb")
for code,name in pairs(new) do
	local old_code=old_rev[name]
	Auxiliary.Replace(old_code,code)
end
table.insert(script,"rm -rf ./script/c?????????.lua")
Auxiliary.Output()