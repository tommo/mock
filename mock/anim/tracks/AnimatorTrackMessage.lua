module 'mock'

--------------------------------------------------------------------
CLASS: AnimatorKeyMessage ( AnimatorKey )
	:MODEL{
		Field 'message' :string();
		Field 'arg'     :string();
}
function AnimatorKeyMessage:executeEvent( state, t )
	local track = self.parent
	local target = state:getTrackTarget( track )
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
	context:updateLength( self:calcLength() )
end

function AnimatorTrackMessage:onStateLoad( state )
	local rootEntity, scene = state:getTargetRoot()
	local target = self.targetPath:get( rootEntity, scene )
	state:setTrackTarget( self, target )
end
