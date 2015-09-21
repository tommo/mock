module 'mock'
--------------------------------------------------------------------
CLASS: AnimatorValueTrack ( AnimatorTrack )
	:MODEL{}

CLASS: AnimatorValueKey ( AnimatorKey )
	:MODEL{}


--------------------------------------------------------------------
CLASS: AnimatorKeyNumber ( AnimatorValueKey )
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
CLASS: AnimatorKeyBoolean ( AnimatorValueKey )
	:MODEL{
		Field 'tweenMode' :no_edit();
		Field 'value'   :boolean()
	}
function AnimatorKeyBoolean:__init()
	self.length = 0
	self.value  = true
	self.tweenMode = 1 --constant
end

function AnimatorKeyBoolean:toString()
	return tostring( self.value )
end

function AnimatorKeyBoolean:setValue( v )
	self.value = v and true or false
end

function AnimatorKeyBoolean:getCurveValue()
	return self.value and 1 or 0
end


--------------------------------------------------------------------
CLASS: AnimatorKeyString ( AnimatorValueKey )
	:MODEL{
		Field 'value'   :string()
	}
function AnimatorKeyString:__init()
	self.length = 0
	self.value  = ''
	self.tweenMode = 1 --constant
end

function AnimatorKeyString:isResizable()
	return false
end

function AnimatorKeyString:toString()
	return tostring( self.value )
end

function AnimatorKeyString:setValue( v )
	self.value = v and tostring( v ) or ''
end

function AnimatorKeyString:getCurveValue()
	return self.value and 1 or 0
end
