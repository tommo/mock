module 'mock'

CLASS: StoryRoleController ( Behaviour )
	:MODEL{
		Field 'roleId'  :string() :getset( 'RoleId' ); -- :selection('_getRoleSelection');
	}

registerComponent( 'StoryRoleController', StoryRoleController )

function StoryRoleController:__init()
end

function StoryRoleController:getRoleId()
	return self.roleId
end

function StoryRoleController:setRoleId( id )
	self.roleId = id
	self:_updateRegistry()
end

function StoryRoleController:_getRoleSelection() --for editor
end

function StoryRoleController:_updateRegistry()
	self:_removeFromRegistry()
	self:getStoryManager():registerRoleController( self )
end

function StoryRoleController:_removeFromRegistry()
	self:getStoryManager():unregisterRoleController( self )
end

function StoryRoleController:onAttach( ent )
	self:_updateRegistry()
end

function StoryRoleController:onDetach( ent )
	self:_removeFromRegistry()
end

function StoryRoleController:getContext()
	return self:getStoryManager():getActiveContext()
end

function StoryRoleController:getStoryManager()
	return getStoryManager()
end

function StoryRoleController:sendInput( tag, data )
	self:getStoryManager():sendInput( self.roleId, tag, data )
end

function StoryRoleController:acceptStoryMessage( msg, node )
	self:onStoryMessage( msg, node )
	self:getEntity():tell( 'story.msg', { msg, node } )
end

function StoryRoleController:onStoryMessage( msg, node )
	-- print( msg, node )
end
