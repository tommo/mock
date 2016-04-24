module 'mock'

--------------------------------------------------------------------
CLASS: AnimatorKeyColor ( AnimatorValueKey )
	:MODEL{
		Field 'value'  :type('color') :getset( 'Value' )
}

function AnimatorKeyColor:__init()
	self.value = { 1,1,1,1 }
end

function AnimatorKeyColor:getValue()
	return unpack( self.value )
end

function AnimatorKeyColor:setValue( r,g,b,a )
	self.value = { r,g,b,a }
end

function AnimatorKeyColor:isResizable()
	return false
end

function AnimatorKeyColor:toString()
	return string.format( '(.1f,.1f,.1f,.1f)', unpack( self.value ) )
end
