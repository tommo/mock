module 'mock'


CLASS: StoryNodeUserInput ( StoryNode )
 	:MODEL{}

function StoryNodeUserInput:__init()
	self.tag  = 'UNKNOWN'
	self.role = false
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

