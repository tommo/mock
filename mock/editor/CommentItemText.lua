module 'mock'

--------------------------------------------------------------------
CLASS: CommentItemText ( CommentItem )
	:MODEL{
		Field 'text' :string();
}

function CommentItemText:createVisualizer()
	return CommentItemTextVisualizer( self )
end

--------------------------------------------------------------------
CLASS: CommentItemTextVisualizer ( CommentItemVisualizer )
	:MODEL{}

