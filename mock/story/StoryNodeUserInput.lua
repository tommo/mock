module 'mock'


CLASS: StoryNodeUserInput ( StoryNode )
 	:MODEL{}

function StoryNodeUserInput:__init()
	self.tag  = 'UNKNOWN'
	self.data = false
end

function StoryNodeUserInput:onStart( state )
	local actorId = self:getActorId()
	local actors = state:getActors( actorId )
	for i, actor in ipairs( actors ) do
		actor:acceptStoryMessage( 'input.start', self )
	end
end

function StoryNodeUserInput:onStop( state )
	local actorId =  self:getActorId()
	local actors = state:getActors( self:getActorId() )
	for i, actor in ipairs( actors ) do
		actor:acceptStoryMessage( 'input.stop', self )
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

