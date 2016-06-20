module 'mock'

--------------------------------------------------------------------
CLASS: EntityMovement2DKey ( AnimatorEventKey )
	:MODEL{
		Field 'loc' :type( 'vec2' ) :getset( 'Loc' );
		Field 'rot' :float();
}

function EntityMovement2DKey:__init()
	self.x = 0
	self.y = 0
	self.rot = 0
end

function EntityMovement2DKey:getLoc()
	return self.x, self.y
end

function EntityMovement2DKey:setLoc( x, y )
	self.x, self.y = x, y
end

function EntityMovement2DKey:toString()
	return string.format( '%.2f,%.2f', self.x, self.y )
end

function EntityMovement2DKey:isResizable()
	return false
end


--------------------------------------------------------------------
CLASS: EntityMovement2DTrack ( AnimatorEventTrack )
	:MODEL{
		Field 'worldSpace' :boolean();
}

function EntityMovement2DTrack:__init()
	self.worldSpace = true
end

function EntityMovement2DTrack:build( context )
	self.idCurve = self:buildIdCurve()
	context:updateLength( self:calcLength() )
end

function EntityMovement2DTrack:onStateLoad( state )
	
end
