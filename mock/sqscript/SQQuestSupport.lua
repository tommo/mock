module 'mock'

local globalEnv = getGlobalSQEvalEnv()

globalEnv.quest_active     = isQuestActive
globalEnv.quest_finished   = isQuestFinished
globalEnv.quest_not_played = isQuestNotPlayed
globalEnv.quest_played     = isQuestPlayed

globalEnv.Q = setmetatable( {}, {
		__index = function( t, k )
			return isQuestActive( k )
		end,
		__newindex = function()
			return error( 'read only!' )
		end
	}
)
