module 'mock'

CLASS: UVTransform ( Component )
	:MODEL{
		Field 'loc' :type( 'vec2' ) :getset( 'Loc' ) :meta{ step=0.05 };
		Field 'scl' :type( 'vec2' ) :getset( 'Scl' ) :meta{ step=0.05 };
		Field 'piv' :type( 'vec2' ) :getset( 'Piv' ) :meta{ step=0.05 };
}

mock.registerComponent( 'UVTransform', UVTransform )

function UVTransform:__init()
	self.transform = MOAITransform.new()
end

function UVTransform:setLoc( x, y )
	return self.transform:setLoc( x, y ) 
end

function UVTransform:getLoc()
	return self.transform:getLoc()
end

function UVTransform:setScl( x, y )
	return self.transform:setScl( x, y ) 
end

function UVTransform:getScl()
	return self.transform:getScl()
end

function UVTransform:setPiv( x, y )
	return self.transform:setPiv( x, y ) 
end

function UVTransform:getPiv()
	return self.transform:getPiv()
end

function UVTransform:onAttach( ent )
	for com in pairs( ent:getComponents() ) do
		if com:isInstance( GraphicsPropComponent ) then
			com:setUVTransform( self.transform )
		end
	end
end

