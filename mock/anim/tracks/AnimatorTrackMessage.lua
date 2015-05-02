module 'mock'

--------------------------------------------------------------------
CLASS: AnimatorKeyMessage ( AnimatorKey )
	:MODEL{
		Field 'message' :string();
		Field 'arg'     :string();
}
function AnimatorKeyMessage:executeEvent( state, time )
	state.target:tell( self.message, self.arg )
end

--------------------------------------------------------------------
CLASS: AnimatorTrackMessage ( AnimatorTrack )
	:MODEL{}


function AnimatorTrackMessage:__init()
	self.name = 'msg'
	self.targetField = false
end

function AnimatorTrackMessage:getType()
	return 'msg'
end

function AnimatorTrackMessage:toString()
	return '<num>' .. tostring( self.name )
end

function AnimatorTrackMessage:createKey()
	return AnimatorKeyMessage()
end

function AnimatorTrackMessage:build( context )
	context:addEventKeyList( self.keys )
end
