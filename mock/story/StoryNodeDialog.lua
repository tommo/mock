module 'mock'
--------------------------------------------------------------------
CLASS: StoryNodeDialog ( StoryNode )
	:MODEL{}

function StoryNodeDialog:onStateEnter( state )
	local actors = state:getActors( self:getActorId() )
	for i, actor in ipairs( actors ) do
		actor:acceptStoryMessage( 'command.dialog', self )
	end
end

--------------------------------------------------------------------
CLASS: StoryNodeDialogQuick ( StoryNode )
	:MODEL{}

function StoryNodeDialogQuick:onStateEnter( state )
	local actors = state:getActors( self:getActorId() )
	for i, actor in ipairs( actors ) do
		actor:acceptStoryMessage( 'command.dialog_quick', self )
	end
end


registerStoryNodeType( 'DIALOG', StoryNodeDialog )
registerStoryNodeType( 'DIALOG_Q', StoryNodeDialogQuick )
