module 'mock'

CLASS: StoryNodeAttr ( StoryDecoratorNode )
	:MODEL{}

function StoryNodeAttr:onLoad( data )
end

function StoryNodeAttr:onApply( dstNode )
	--TODO
	-- print( 'setting attr', self.text, dstNode:getId() )
end

registerStoryNodeType( 'ATTR', StoryNodeAttr )
