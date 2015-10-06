module 'mock'

CLASS: StoryNodeActorId ( StoryDecoratorNode )
	:MODEL{}

function StoryNodeActorId:onLoad( data )
end

function StoryNodeActorId:onApply( dstNode )
	-- print('apply role', dstNode, self.text )
	dstNode.actorId = self.text
end

registerStoryNodeType( 'ROLE',  StoryNodeActorId )
registerStoryNodeType( 'ACTOR', StoryNodeActorId )