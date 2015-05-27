module 'mock'
CLASS: StoryRoleController ()
	:MODEL{
		Field 'story' :asset('story');
		Field 'role'  :string() :selection('getRoleSelection') :getset( 'Role' )
	}

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

