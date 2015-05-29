module 'mock'

CLASS: StoryRoleController ( Component )
	:MODEL{
		Field 'roleId'  :string() :getset( 'RoleId' ); -- :selection('_getRoleSelection');
	}

registerComponent( 'StoryRoleController', StoryRoleController )

function StoryRoleController:__init()
	self.ownerContext = false
end

function StoryRoleController:getRoleId()
	return self.roleId
end

function StoryRoleController:setRoleId( id )
	self.roleId = id
	self:updateRegistry()
end


function StoryRoleController:_getRoleSelection() --for editor

end


function StoryRoleController:_updateRegistry()
	self:_removeFromRegistry()
	local context = self:getStoryManager():getActiveContext()
	if context then
		self.context = context 
		context:registerRoleController( self )
	end
end

function StoryRoleController:_removeFromRegistry()
	if self.ownerContext then
		self.ownerContext:removeRoleController( self )
		self.ownerContext = false
	end
end

function StoryRoleController:onAttach( ent )
	self:_updateRegistry()
end

function StoryRoleController:onDetach( ent )
	self:_removeFromRegistry()
end

function StoryRoleController:getContext()
	return self.ownerContext or false
end

function StoryRoleController:getStoryManager()
	return getStoryManager()
end

function StoryRoleController:sendInput( tag, data )
	local context = self:getContext()
	context:sendInput( self.roleId, tag, data )
end

function StoryRoleController:acceptStoryMessage( msg, node )
	self:onStoryMessage( msg, node )
	self:getEntity():tell( msg, node )
end

function StoryRoleController:onStoryMessage( msg, node )
end
