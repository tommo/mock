module 'mock'

--------------------------------------------------------------------
local _questManger
function getQuestManger()
	return _questManger
end

--------------------------------------------------------------------
CLASS: QuestManager ( GlobalManager )
	:MODEL{}

function QuestManager:__init()
end

function QuestManager:getKey()
	return 'QuestManager'
end

function QuestManager:onInit( game )
end

--------------------------------------------------------------------
_questManger = QuestManager()
