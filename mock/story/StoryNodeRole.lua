module 'mock'

CLASS: StoryNodeRole ( StoryDecoratorNode )
	:MODEL{}

function StoryNodeRole:onLoad( data )
end

function StoryNodeRole:onApply( dstNode )
	-- print('apply role', dstNode, self.text )
	dstNode.roleId = self.text
end

registerStoryNodeType( 'ROLE', StoryNodeRole )