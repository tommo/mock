module 'mock'

--------------------------------------------------------------------
CLASS: StoryThread ()
	:MODEL{}

function StoryThread:__init()
	self.currentNodeId = false
end

function StoryThread:update()
	--check proceed to next node
end

function StoryThread:deserializeState( data )
end

function StoryThread:serializeState()
	local data = {}
	return data
end


--------------------------------------------------------------------
CLASS: StoryController ( Component )
	:MODEL{}

function StoryController:__init()
	self.activeThreads = {}
	self.flagDicts = {}
end

function StoryController:affirmFlagDict( id )
	local flagDict = self.flagDicts[ id ]
	if not flagDict then
		flagDict = FlagDict()
		self.flagDicts[ id ] = flagDict
	end
	return flagDict
end

function StoryController:getFlagDict( id )
	return self.flagDicts[ id ]
end

function StoryController:deserializeState( data )
end

function StoryController:serializeState()
	local data = {}
	return data
end

