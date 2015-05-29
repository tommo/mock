module 'mock'

--------------------------------------------------------------------
CLASS: StoryManager ()
	:MODEL{}


function StoryManager:__init()
	self.contexts = {}
	self.activeContext = false
end

function StoryManager:update()
	for _, context in ipairs( self.contexts ) do
		context:tryUpdate()
	end
end

function StoryManager:getActiveContext()
	return self.activeContext
end

function StoryManager:createContext()
	local context = StoryContext()
	table.insert( self.contexts, context )
	return context
end

function StoryManager:actionUpdate()
	if not self.rootState then return end
	while self.rootState:isActive() do
		coroutine.yield()
		self.rootState:update()
	end
end


--------------------------------------------------------------------
local storyManager = StoryManager()
function getStoryManager()
	return storyManager
end

connectGlobalSignalFunc( 'game.update', function()
	storyManager:update()
end )
