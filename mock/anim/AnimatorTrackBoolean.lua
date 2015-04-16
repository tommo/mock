module 'mock'

--------------------------------------------------------------------
CLASS: AnimatorKeyBoolean ( AnimatorKey )
	:MODEL{
		Field 'tweenMode' :no_edit();
		Field 'value'   :boolean()
	}
function AnimatorKeyBoolean:__init()
	self.length = 0
	self.value  = true
	self.tweenMode = 1
end

function AnimatorKeyBoolean:isResizable()
	return true
end

function AnimatorKeyBoolean:start( state, pos )	
	state.target:tell( self.message, self )
end

function AnimatorKeyBoolean:toString()
	return tostring( self.message )
end

function AnimatorKeyBoolean:setValue( v )
	self.value = v and true or false
end

function AnimatorKeyBoolean:getCurveValue()
	return self.value and 100 or 0
end

--------------------------------------------------------------------
CLASS: AnimatorTrackBoolean ( AnimatorTrack )
	:MODEL{
}

function AnimatorTrackBoolean:__init()
	self.name = 'boolean'
	self.tweenMode = 0 --always constant 
end

function AnimatorTrackBoolean:getType()
	return 'boolean'
end

function AnimatorTrackBoolean:createKey()
	return AnimatorKeyBoolean()
end

function AnimatorTrackBoolean:toString()
	return '<bool>' .. tostring( self.name )
end



--------------------------------------------------------------------
registerAnimatorTrackType( 'boolean', AnimatorTrackBoolean )

