module 'mock'

EnumLineStyle = _ENUM{
	{ 'none',  MOAIVectorTesselator.LINE_NONE },
	{ 'vector', MOAIVectorTesselator.LINE_VECTOR }
}

EnumFillStyle = _ENUM{
	{ 'none',  MOAIVectorTesselator.FILL_NONE },
	{ 'solid', MOAIVectorTesselator.FILL_SOLID }
}

--------------------------------------------------------------------
CLASS: VectorShape ()
	:MODEL{
		Field 'fillStyle' :enum( EnumFillStyle );
		Field 'fillColor' :type( 'color' ) :getset( 'FillColor' );
		'----';
		Field 'lineStyle' :enum( EnumLineStyle )
		Field 'lineWidth' :range( 0 );
		Field 'lineColor' :type( 'color' ) :getset( 'LineColor' );
	}

function VectorShape:__init()
	self.lineStyle = MOAIVectorTesselator.LINE_VECTOR
	self.lineWidth = 1
	self.fillStyle = MOAIVectorTesselator.FILL_SOLID
	self.fillColor = { .5,.5, 1, 1 }
	self.lineColor = {  1, 1, 1, 1 }
end

function VectorShape:getFillColor()
	return unpack( self.fillColor )
end

function VectorShape:getLineColor()
	return unpack( self.lineColor )
end

function VectorShape:setFillColor( r,g,b,a )
	self.fillColor = { r,g,b,a }
end

function VectorShape:setLineColor( r,g,b,a )
	self.lineColor = { r,g,b,a }
end

