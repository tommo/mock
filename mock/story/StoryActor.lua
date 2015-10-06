module 'mock'

CLASS: StoryActor ( Behaviour )
	:MODEL{
		Field 'actorId' :string();
		Field 'story'   :asset( 'story_graph' ) :getset( 'StoryGraphPath' )
	}

registerComponent( 'StoryActor', StoryActor )

function StoryActor:__init()
	self.actorId      = ''
	self.storyGraph   = false
	self.localContext = false
end

function StoryActor:getActorId()
	return self.actorId
end

function StoryActor:setActorId( id )
	self.actorId = id
end

function StoryActor:getStoryGraphPath()
	return self.storyGraphPath
end

function StoryActor:setStoryGraphPath( path )
	self.storyGraphPath = path
	self:refreshLocalContext()
	
end

--------------------------------------------------------------------
--localContext
function StoryActor:getStoryManager()
	return getStoryManager()
end

function StoryActor:getSceneContext()
	local scene = self:getScene()
	local manager = getStoryManager()
	return manager:getSceneContext( scene )
end

function StoryActor:getContext()
	return self.localContext
end

function StoryActor:getGlobalContext()
	return self:getStoryManager():getGlobalContext()
end

function StoryActor:refreshLocalContext()
	if not self.localContext then return end
	local path = self.storyGraphPath
	if path then
		self.localContext:reset()
		local graph = loadAsset( path )
		if graph then self.localContext:setStoryGraph( graph ) end
	else
		self.localContext:reset()
	end
end

function StoryActor:onAttach( ent )
	StoryActor.__super.onAttach( self, ent )
	self:getStoryManager():registerActor( self )
	local sceneContext = self:getSceneContext()
	local localContext = sceneContext:createChildContext()
	self.localContext = localContext
	self.localContext:setOwnerActor( self )
	self:refreshLocalContext()
end


function StoryActor:onDetach( ent )
	StoryActor.__super.onDetach( self, ent )
	self:getStoryManager():unregisterActor( self )
	local sceneContext = self:getSceneContext()
	sceneContext:removeChildContext( self.localContext )
end

function StoryActor:onStart( ent )
	StoryActor.__super.onStart( self, ent )
	self.localContext:start()
end

--------------------------------------------------------------------
--Interaction
function StoryActor:sendInput( tag, data )
	return self.localContext:sendInput( self, tag, data )
end

function StoryActor:acceptStoryMessage( msg, node )
	return self:getEntity():tell( 'story.msg', { msg, node } )
end
