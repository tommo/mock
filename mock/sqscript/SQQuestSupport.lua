module 'mock'

local globalEnv = getGlobalSQEvalEnv()

globalEnv.isQuestActive     = isQuestActive
globalEnv.isQuestFinished   = isQuestFinished
globalEnv.isQuestNotPlayed = isQuestNotPlayed
globalEnv.isQuestPlayed     = isQuestPlayed

globalEnv['Q'] = setmetatable( {}, {
		__index = function( t, k )
			return isQuestActive( k )
		end,
		__newindex = function()
			return error( 'read only!' )
		end
	}
)
