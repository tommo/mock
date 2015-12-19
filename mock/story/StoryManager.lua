module 'mock'

--------------------------------------------------------------------
CLASS: StoryManager ( GlobalManager )
	:MODEL{}


function StoryManager:__init()
	self.contexts = {}
	self.actorRegistry = {}
	self.globalContext = false
end

function StoryManager:getKey()
	return 'StoryManager'
end

function StoryManager:onInit( game )
	self.globalContext = StoryContext()
end

function StoryManager:getActorRegistry()
	return self.actorRegistry
end

function StoryManager:getActors( actorId )
	return self.actorRegistry[ actorId ] or {}
end

function StoryManager:registerActor( actor )
	local id = actor:getActorId()
	local t = self.actorRegistry[ id ]
	if not t then
		t = {}
		self.actorRegistry[ id ] = t
	end
	table.insert( t, actor )
	return actor
end

function StoryManager:unregisterActor( actor )
	local id = actor:getActorId()
	local t = self.actorRegistry[ id ]
	if t then
		local idx = table.index( t, actor )
		if idx then
			table.remove( t, idx )
		end
	end
end

function StoryManager:onUpdate( game, dt )
	if not self.globalContext then return end
	self.globalContext:tryUpdate()
end

function StoryManager:getGlobalContext()
	return self.globalContext
end

function StoryManager:getGlobalFlagDict()
	return self.globalContext:getLocalFlagDict()
end

function StoryManager:getSceneContext( scn )
	return scn:getUserObject( 'scene_story_context' )
end

function StoryManager:addSceneContext( scn )
	local context = self.globalContext:createChildContext()
	scn:setUserObject( 'scene_story_context', context )
	return context
end

function StoryManager:removeSceneContext( scn )
	local context = self:getSceneContext( scn )
	if not context then return end
	scn:setUserObject( 'scene_story_context', nil )
	self.globalContext:removeChildContext( context )
end

function StoryManager:onSceneReset( scn )
	if scn:isEditorScene() then return end
	self:addSceneContext( scn )
end

function StoryManager:onSceneClear( scn )
	if scn:isEditorScene() then return end
	self:removeSceneContext( scn )
end

--------------------------------------------------------------------
local storyManager = StoryManager()
function getStoryManager()
	return storyManager
end

