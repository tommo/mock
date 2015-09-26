module 'mock'

--------------------------------------------------------------------
CLASS: AnimatorEventTrack ( AnimatorTrack )
	:MODEL{}

function AnimatorEventTrack:isPlayable()
	return true
end

--------------------------------------------------------------------
CLASS: AnimatorEventKey ( AnimatorKey )
	:MODEL{}

function AnimatorEventKey:isResizable()
	return true
end

