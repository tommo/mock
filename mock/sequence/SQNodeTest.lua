---------------------------------------------------------------------
CLASS: SQNodeMoveTo ( SQNode )
	:MODEL{
		Field 'target' :type( 'vec2' ) :getset( 'Target' )
}

function SQNodeMoveTo:__init()
	self.target = { 0, 0 }
end

function SQNodeMoveTo:getTarget()
	return unpack( self.target )
end

function SQNodeMoveTo:setTarget( x, y )
	self.target = { x, y }
end


---------------------------------------------------------------------
CLASS: SQNodeTalk ( SQNode )
	:MODEL{
		Field 'text' :string() :widget( 'textbox' );
}

function SQNodeTalk:enter()
	self.text = 'Hello!'
end

function SQNodeTalk:update( dt )
end

function SQNodeTalk:enter()
end

