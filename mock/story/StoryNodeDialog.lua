module 'mock'
--------------------------------------------------------------------
CLASS: StoryNodeDialog ( StoryNode )
	:MODEL{}

function StoryNodeDialog:onStateEnter( state )
	local roles = state:getRoleControllers( self:getRoleId() )
	for i, role in ipairs( roles ) do
		role:acceptStoryMessage( 'command.dialog', self )
	end
	print( 'dialog', self.text )
end

--------------------------------------------------------------------
CLASS: StoryNodeDialogQuick ( StoryNode )
	:MODEL{}

function StoryNodeDialogQuick:onStateEnter( state )
	local roles = state:getRoleControllers()
	for i, role in ipairs( roles ) do
		role:acceptStoryMessage( 'command.dialog_quick', self )
	end
end


registerStoryNodeType( 'DIALOG', StoryNodeDialog )
registerStoryNodeType( 'DIALOG_Q', StoryNodeDialogQuick )
