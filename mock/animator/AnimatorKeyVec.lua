module 'mock'
--------------------------------------------------------------------
CLASS: AnimatorKeyVec2 ( AnimatorValueKey )
	:MODEL{
		Field 'value'  :type('vec2') :getset( 'Value')
}

function AnimatorKeyVec2:__init()
	self.x, self.y = 0, 0
end

function AnimatorKeyVec2:getValue()
	return self.x, self.y
end

function AnimatorKeyVec2:setValue( x, y )
	self.x, self.y = x, y
end

function AnimatorKeyVec2:isResizable()
	return false
end

function AnimatorKeyVec2:toString()
	return string.format( '(.2f,.2f)', self.x, self.y )
end


--------------------------------------------------------------------
CLASS: AnimatorKeyVec3 ( AnimatorValueKey )
	:MODEL{
		Field 'value'  :type('vec3') :getset( 'Value')
}

function AnimatorKeyVec3:__init()
	self.x, self.y, self.z = 0, 0, 0
end

function AnimatorKeyVec3:getValue()
	return self.x, self.y, self.z
end

function AnimatorKeyVec3:setValue( x, y, z )
	self.x, self.y, self.z = x, y, z
end

function AnimatorKeyVec3:isResizable()
	return false
end

function AnimatorKeyVec3:toString()
	return string.format( '(.2f,.2f,.2f)', self.x, self.y, self.z )
end
