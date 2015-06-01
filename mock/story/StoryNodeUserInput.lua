module 'mock'


CLASS: StoryNodeUserInput ( StoryNode )
 	:MODEL{}

function StoryNodeUserInput:__init()
	self.tag  = 'UNKNOWN'
	self.data = false
end

function StoryNodeUserInput:onStart( state )
	local roleId =  self:getRoleId()
	local roles = state:getRoleControllers( self:getRoleId() )
	for i, role in ipairs( roles ) do
		role:acceptStoryMessage( 'input.start', self )
	end
end

function StoryNodeUserInput:onStop( state )
	local roleId =  self:getRoleId()
	local roles = state:getRoleControllers( self:getRoleId() )
	for i, role in ipairs( roles ) do
		role:acceptStoryMessage( 'input.stop', self )
	end
end

function StoryNodeUserInput:getTag()
	return self.tag
end

function StoryNodeUserInput:getData()
	return self.data
end

function StoryNodeUserInput:onLoad( nodeData )
	local text = self.text
	local tag, data = text:match( '%s*(%w+)%s*:%s*(.*)' )
	if not tag then
		tag = text:match( '%s*(%w+)%s*' )
		data = false
	end
	self.tag  = tag
	self.data = data

end

registerStoryNodeType( 'INPUT', StoryNodeUserInput )

