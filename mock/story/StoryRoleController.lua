module 'mock'

CLASS: StoryRoleController ()
	:MODEL{
		Field 'role'  :string() :selection('getRoleSelection') :getset( 'Role' )
	}

registerComponent( 'StoryRoleController', StoryRoleController )

function StoryRoleController:getRole()
	return self.role
end

function StoryRoleController:setRole( r )
	self.role = r
end

function StoryRoleController:getRoleSelection()
end

function StoryRoleController:acceptInput( tag, data )
end
