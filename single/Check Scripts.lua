--Made by purerosefallen

io=require('io')
os=require('os')
os.remove("error.log")
Debug.Message(os.date())
Debug.SetAIName("Check Scripts")
Debug.ReloadFieldBegin(DUEL_ATTACK_FIRST_TURN+DUEL_SIMPLE_AI)
Debug.SetPlayerInfo(0,8000,0,0)
Debug.SetPlayerInfo(1,8000,0,0)
local f=io.popen("bash echo \"select id from datas;\" | sqlite3 expansions/222DIY.cdb")
for line in f:lines() do
	Debug.AddCard(tonumber(line),0,0,LOCATION_GRAVE,0,POS_FACEUP_ATTACK,true)
end
f:close()
Debug.ReloadFieldEnd()