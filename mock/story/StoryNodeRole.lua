module 'mock'

CLASS: StoryNodeRole ( StoryDecoratorNode )
	:MODEL{}

function StoryNodeRole:onLoad( data )
end

function StoryNodeRole:onApply( dstNode )
	--TODO
	-- print( 'setting role', self.text, dstNode:getId() )
end

registerStoryNodeType( 'ROLE', StoryNodeRole )