module 'mock'

--------------------------------------------------------------------
--- Shape
-- @type Shape2D
-- @string name name of the shape

CLASS: Shape2D ()
	:MODEL{
		Field 'name' :string();  
		Field 'loc' :type( 'vec2' ) :getset( 'Loc' )
}

function Shape2D:__init()
	self.name = 'shape'
	self.trans = MOAITransform.new()
end

function Shape2D:getLoc()
	return self.trans:getLoc()
end

function Shape2D:getTypeName()
	return 'shape'
end

function Shape2D:getIcon()
	return 'shape'
end

--- get converted PolyLines
-- @int  steps for PolyLines generation
-- @return list of PolyLines
function Shape2D:toPolyLines( steps )
	return {}
end


--------------------------------------------------------------------
CLASS: ShapeRect ( Shape2D )
	:MODEL{
		Field 'size' :type( 'vec2' ) :getset( 'Size' )
	}
function ShapeRect:__init()
	self.w = 10
	self.h = 10
end

function ShapeRect:getSize()
	return self.w, self.h
end

function ShapeRect:setSize( w, h )
	self.w = w
	self.h = h
end

function ShapeRect:getIcon()
	return 'shape_rect'
end

function ShapeRect:getTypeName()
	return 'rect'
end

--------------------------------------------------------------------
CLASS: ShapeCircle ( Shape2D )
	:MODEL{
		Field 'radius' :getset( 'Radius' )
	}
function ShapeCircle:__init()
	self.radius = 10
end

function ShapeCircle:getRadius()
	return self.radius
end

function ShapeCircle:setRadius( r )
	self.radius = r
end

function ShapeCircle:getIcon()
	return 'shape_circle'
end

function ShapeCircle:getTypeName()
	return 'circle'
end
--------------------------------------------------------------------
CLASS: ShapeEllipse ( ShapeRect )
	:MODEL{
	}

--------------------------------------------------------------------
CLASS: ShapePolygon ( Shape2D )
	:MODEL{
		Field 'verts' :array();
	}

function ShapePolygon:__init()
	self.verts = {}
end

function ShapePolygon:addVert( x, y )
	table.insert( self.verts, x, y )
end

function ShapePolygon:getVertCount()
	return #self.verts/2
end

function ShapePolygon:getIcon()
	return 'shape_poly'
end

function ShapePolygon:getTypeName()
	return 'poly'
end

--------------------------------------------------------------------
CLASS: ShapePolygonTree ( Shape2D )
	:MODEL{}


--------------------------------------------------------------------
CLASS: ShapeComposition ()
	:MODEL{
		Field 'shapes' :array( 'Shape2D' ) :sub()
	}

function ShapeComposition:__init()
	self.shapes = {}
end

function ShapeComposition:addShape( s )
	table.insert( self.shapes, s )
end

function ShapeComposition:removeShape( s )
	local idx = table.index( self.shapes, s )
	if idx then table.remove( self.shapes, idx ) end
end

function ShapeComposition:findShape( name )
	for i, s in ipairs( self.shapes ) do
		if s.name == name then return s end
	end
	return nil
end

