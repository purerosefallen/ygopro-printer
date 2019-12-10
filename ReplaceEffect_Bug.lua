--created by puzzle editor
Debug.SetAIName("简单人机电脑")
Debug.ReloadFieldBegin(DUEL_ATTACK_FIRST_TURN+DUEL_SIMPLE_AI,4)
Debug.SetPlayerInfo(0,100,0,0)
Debug.SetPlayerInfo(1,8000,0,0)

--自己的怪兽区
Debug.AddCard(15341821,0,0,LOCATION_MZONE,1,POS_FACEUP_ATTACK) --蒲公英狮
Debug.AddCard(39765958,0,0,LOCATION_MZONE,2,POS_FACEUP_ATTACK) --琰魔龙 红莲魔
--对方的怪兽区
Debug.AddCard(46986417,1,1,LOCATION_MZONE,1,POS_FACEUP_ATTACK) --黑魔术师
Debug.AddCard(26082117,1,1,LOCATION_MZONE,2,POS_FACEUP_ATTACK) --我我我魔术师
Debug.AddCard(15341821,1,1,LOCATION_MZONE,3,POS_FACEUP_ATTACK) --蒲公英狮
--自己的魔陷区
Debug.AddCard(50584941,0,0,LOCATION_SZONE,4,POS_FACEDOWN_ATTACK) --红莲霸权
Debug.AddCard(50584941,0,0,LOCATION_SZONE,3,POS_FACEDOWN_ATTACK) --红莲霸权
Debug.AddCard(50584941,0,0,LOCATION_SZONE,2,POS_FACEDOWN_ATTACK) --红莲霸权
Debug.AddCard(50584941,0,0,LOCATION_SZONE,1,POS_FACEDOWN_ATTACK) --红莲霸权
--对方的魔陷区
--自己的手卡
Debug.AddCard(53129443,0,0,LOCATION_HAND,2,POS_FACEUP_ATTACK) --黑洞
Debug.AddCard(83764718,0,0,LOCATION_HAND,3,POS_FACEUP_ATTACK) --死者苏生
Debug.AddCard(83764718,0,0,LOCATION_HAND,4,POS_FACEUP_ATTACK) --死者苏生
--对方的手卡
--自己的墓地
Debug.AddCard(36857073,0,0,LOCATION_GRAVE,0,POS_FACEUP_ATTACK):CompleteProcedure() --琰魔龙 红莲魔·葬
Debug.AddCard(80666118,0,0,LOCATION_GRAVE,0,POS_FACEUP_ATTACK):CompleteProcedure() --红莲魔龙·右红痕
Debug.AddCard(80666118,0,0,LOCATION_GRAVE,0,POS_FACEUP_ATTACK):CompleteProcedure() --红莲魔龙·右红痕
Debug.AddCard(97489701,0,0,LOCATION_GRAVE,0,POS_FACEUP_ATTACK):CompleteProcedure() --真红莲新星龙
Debug.AddCard(62242678,0,0,LOCATION_GRAVE,0,POS_FACEUP_ATTACK):CompleteProcedure() --琰魔龙王 红莲魔·厄
Debug.AddCard(16172067,0,0,LOCATION_GRAVE,0,POS_FACEUP_ATTACK):CompleteProcedure() --红莲魔龙·暴君
Debug.AddCard(36857073,0,0,LOCATION_GRAVE,0,POS_FACEUP_ATTACK):CompleteProcedure() --琰魔龙 红莲魔·葬
Debug.AddCard(70902743,0,0,LOCATION_GRAVE,0,POS_FACEUP_ATTACK):CompleteProcedure() --红莲魔龙
Debug.AddCard(70902743,0,0,LOCATION_GRAVE,0,POS_FACEUP_ATTACK):CompleteProcedure() --红莲魔龙
Debug.AddCard(36857073,0,0,LOCATION_GRAVE,0,POS_FACEUP_ATTACK):CompleteProcedure() --琰魔龙 红莲魔·葬
--对方的墓地
--自己除外的卡
--对方除外的卡
Debug.AddCard(46986419,1,1,LOCATION_REMOVED,0,POS_FACEUP_ATTACK) --黑魔术师

Debug.ReloadFieldEnd()
aux.BeginPuzzle()
