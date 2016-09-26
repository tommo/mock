module 'mock'

--------------------------------------------------------------------
--- Shape
-- @type ShapeItem2D
-- @string name name of the shape

CLASS: ShapeItem2D ( ShapeItem )
	:MODEL{
		Field 'loc' :type( 'vec2' ) :getset( 'Loc' )
}

function ShapeItem2D:__init()
	self.name = 'shape'
	self.trans = MOAITransform.new()
end

function ShapeItem2D:getLoc()
	return self.trans:getLoc()
end

function ShapeItem2D:getTypeName()
	return 'shape'
end

function ShapeItem2D:getIcon()
	return 'shape'
end

--- get converted PolyLines
-- @int  steps for PolyLines generation
-- @return list of PolyLines
function ShapeItem2D:toPolyLines( steps )
	return {}
end


--------------------------------------------------------------------
CLASS: ShapeRect ( ShapeItem2D )
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
CLASS: ShapeCircle ( ShapeItem2D )
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
CLASS: ShapePolygon ( ShapeItem2D )
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

-- --------------------------------------------------------------------
-- CLASS: ShapePolygonTree ( ShapeItem2D )
-- 	:MODEL{}

