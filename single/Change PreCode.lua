local script={}
local output_func=Debug and Debug.Message or print
function SplitData(inputstr)
	local t={}
	for str in string.gmatch(inputstr,"([^|]+)") do
		table.insert(t,str)
	end
	return t
end
function LoadDB(db)
	local res={}
	local res_rev={}
	local file=io.popen("sqlite3 "..db.." -cmd 'select id,name from texts;'")
	local count=0
	for line in file:lines() do
		local data=SplitData(line)
		local code=tonumber(data[1])
		local name=data[2]
		res[code]=name
		res_rev[name]=code
		count=count+1
	end
	file:close()
	return res,res_rev,count
end
function Replace(old,new)
	if not old or old==new then return end
	output_func("Will replace "..old.." to "..new..".")
	table.insert(script,"echo \"Replacing "..old.." to "..new..".\"")
	table.insert(script,"mv -f ./output/c"..old..".lua ./output/c"..new..".lua")
	table.insert(script,"sed -i 's/"..old.."/"..new.."/g' ./output/c*.lua")
	for i=1,9 do
		table.insert(script,"sed -i 's/"..(old+i*100).."/"..new+i.."/g' ./output/c*.lua")	
		table.insert(script,"sed -i 's/"..new.."+"..i.."00/"..new+i.."/g' ./output/c*.lua")		
	end
end
function Output()
	local f=io.open("replace.sh","w")
	for _,s in ipairs(script) do
		f:write(s)
		f:write("\n")
	end
	f:close()
end

local old,old_rev,old_count=LoadDB("ygopro-pre-data/expansions/pre-release.cdb")
local new,new_rev,new_count=LoadDB("cards.cdb")
output_func(old_count.." "..new_count)
table.insert(script,"#!/bin/bash")
table.insert(script,"# Generated by Precode Replacer.")
table.insert(script,"rm -rf ./output/*")
table.insert(script,"mkdir ./output")
table.insert(script,"cp -rf ./ygopro-pre-script/scripts/**/c?????????.lua ./output/")
for code,name in pairs(new) do
	local old_code=old_rev[name]
	Replace(old_code,code)
end
table.insert(script,"rm -rf ./output/c?????????.lua")
Output()
