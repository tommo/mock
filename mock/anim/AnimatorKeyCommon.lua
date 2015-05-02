module 'mock'
--------------------------------------------------------------------
CLASS: AnimatorKeyNumber ( AnimatorKey )
	:MODEL{
		Field 'value'   :number()
	}
function AnimatorKeyNumber:__init()
	self.length = 0
	self.value = 0
end

function AnimatorKeyNumber:isResizable()
	return false
end

function AnimatorKeyNumber:toString()
	return tostring( self.value )
end

function AnimatorKeyNumber:setValue( v )
	self.value = v
end

function AnimatorKeyNumber:getCurveValue()
	return self.value
end

--------------------------------------------------------------------
CLASS: AnimatorKeyBoolean ( AnimatorKey )
	:MODEL{
		Field 'tweenMode' :no_edit();
		Field 'value'   :boolean()
	}
function AnimatorKeyBoolean:__init()
	self.length = 0
	self.value  = true
	self.tweenMode = 1 --constant
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
