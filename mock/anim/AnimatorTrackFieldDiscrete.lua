module 'mock'

--------------------------------------------------------------------
CLASS: AnimatorTrackFieldDiscrete ( AnimatorTrackField )

function AnimatorTrackFieldDiscrete:build( context ) --building shared data
	self.idCurve = self:buildIdCurve()
	context:updateLength( self:calcLength() )
end

function AnimatorTrackFieldDiscrete:onStateLoad( state )
	local rootEntity, scene = state:getTargetRoot()
	local target = self.targetPath:get( rootEntity, scene )
	local context = { target, false }
	state:addUpdateListenerTrack( self, context )
end

function AnimatorTrackFieldDiscrete:apply( state, context, t )
	local target, keyId = context[1], context[2]
	local newId = self.idCurve:getValueAtTime( t )
	if keyId ~= newId then
		local value = self.keys[ newId ].value
		context[2] = newId
		return self.targetField:setValue( target, value )
	end
end
