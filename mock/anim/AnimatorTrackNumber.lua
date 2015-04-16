module 'mock'


--------------------------------------------------------------------
CLASS: AnimatorKeyNumber ( AnimatorKey )
	:MODEL{
		Field 'message' :string();
		Field 'value'   :number()
	}
function AnimatorKeyNumber:__init()
	self.length = 0
	self.name   = 'message'
	self.number = 0
end

function AnimatorKeyNumber:isResizable()
	return false
end

function AnimatorKeyNumber:start( state, pos )	
	state.target:tell( self.message, self )
end

function AnimatorKeyNumber:toString()
	return tostring( self.message )
end

function AnimatorKeyNumber:setValue( v )
	self.value = v
end

function AnimatorKeyNumber:getCurveValue()
	return self.value
end

--------------------------------------------------------------------
CLASS: AnimatorTrackNumber ( AnimatorTrack )
	:MODEL{}

function AnimatorTrackNumber:__init()
	self.name = 'number'
end

function AnimatorTrackNumber:getType()
	return 'number'
end

function AnimatorTrackNumber:createKey()
	return AnimatorKeyNumber()
end

function AnimatorTrackNumber:toString()
	return '<num>' .. tostring( self.name )
end



--------------------------------------------------------------------
registerAnimatorTrackType( 'number', AnimatorTrackNumber )

