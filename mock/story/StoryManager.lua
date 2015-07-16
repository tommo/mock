module 'mock'

--------------------------------------------------------------------
CLASS: StoryManager ( GlobalManager )
	:MODEL{}


function StoryManager:__init()
	self.contexts = {}
	self.roleControllers = {}
	self.activeContext = false
end

function StoryManager:getKey()
	return 'StoryManager'
end

function StoryManager:onInit( game )
	--TEST:
	if not hasAsset( 'story/basic.story' ) then return end
	local context = self:createContext()
	context:setActive()
	context:setStoryPath( 'story/basic.story' )
	context:start()
end

function StoryManager:onUpdate( game, dt )
	for _, context in ipairs( self.contexts ) do
		context:tryUpdate()
	end
end

function StoryManager:getActiveContext()
	return self.activeContext
end

function StoryManager:setActiveContext( context )
	self.activeContext = context
end

function StoryManager:createContext()
	local context = StoryContext()
	table.insert( self.contexts, context )
	return context
end

function StoryManager:registerRoleController( controller )
	local roleId = controller:getRoleId()
	if not roleId then return end
	local roles = self.roleControllers[ roleId ]
	if not roles then
		roles = {}
		self.roleControllers[ roleId ] = roles
	end
	table.insert( roles, controller )
end

function StoryManager:unregisterRoleController( controller )
	local roleId = controller:getRoleId()
	local roles = self.roleControllers[ roleId ]
	if not roles then return end
	for i, r in ipairs( roles ) do
		if r == controller then
			table.remove( roles, i )
			return
		end
	end
end

function StoryManager:getRoleControllers( roleId )
	local roles = self.roleControllers[ roleId ]
	return roles or {}
end

function StoryManager:sendInput( roleId, tag, data )
	print( 'input event', roleId, tag, data )
	if self.activeContext then
		self.activeContext:sendInput( roleId, tag, data )
	end
end

function StoryManager:sendSceneEvent( sceneId, event ) --scene, enter/exit
	if not sceneId then return end
	print( 'scene event', sceneId, event )
	if self.activeContext then
		self.activeContext:sendSceneEvent( sceneId, event )
	end
end

--------------------------------------------------------------------
local storyManager = StoryManager()
function getStoryManager()
	return storyManager
end

