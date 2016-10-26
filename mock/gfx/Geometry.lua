--------------------------------------------------------------------
--@classmod Geometry
module 'mock'

local draw = MOAIDraw
local gfx  = MOAIGfxDevice


CLASS: GeometryComponent( DrawScript )
	:MODEL{
		-- Field 'blend'  :enum( EnumBlendMode ) :getset('Blend');		
	}

function GeometryComponent:__init()
	self.color = {1,1,1,1}
end

function GeometryComponent:applyColor()
	local ent = self._entity
	if ent then
		-- gfx.setPenColor( ent:getColor() )
	end
end

-- function GeometryComponent:getBlend()
-- 	return self.blend
-- end

-- function GeometryComponent:setBlend( b )
-- 	self.blend = b	
-- 	setPropBlend( self.prop, b )
-- end

function GeometryComponent:getPickingProp()
	return self.prop
end

--------------------------------------------------------------------
CLASS: GeometryRect ( GeometryComponent )
	:MODEL{
		Field 'w';
		Field 'h';
		Field 'fill'  :boolean()
	}
registerComponent( 'GeometryRect', GeometryRect )

function GeometryRect:__init()
	self.w = 100
	self.h = 100
	self.fill = false
end

function GeometryRect:getSize()
	return self.w, self.h
end

function GeometryRect:setSize( w, h )
	self.w = w
	self.h = h
end

function GeometryRect:onDraw()
	self:applyColor()
	local w,h = self.w, self.h
	if self.fill then
		draw.fillRect( -w/2,-h/2, w/2,h/2 )
	else
		draw.drawRect( -w/2,-h/2, w/2,h/2 )
	end
end

function GeometryRect:onGetRect()
	local w,h = self.w, self.h
	return -w/2,-h/2, w/2,h/2
end


--------------------------------------------------------------------
CLASS: GeometryCircle ( GeometryComponent )
	:MODEL{
		Field 'radius';
		Field 'fill' :boolean()
	}
registerComponent( 'GeometryCircle', GeometryCircle )

function GeometryCircle:__init()
	self.radius = 100
	self.fill = false
end

function GeometryCircle:getRadius()
	return self.radius
end

function GeometryCircle:setRadius( r )
	self.radius = r
end

function GeometryCircle:onDraw()
	self:applyColor()
	if self.fill then
		draw.fillCircle( 0,0, self.radius )
	else
		draw.drawCircle( 0,0, self.radius )
	end
end

function GeometryCircle:onGetRect()
	local r = self.radius
	return -r,-r, r,r
end

--------------------------------------------------------------------
CLASS: GeometryRay ( GeometryComponent )
	:MODEL{
		'----';
		Field 'length' :set( 'setLength' );		
	}
registerComponent( 'GeometryRay', GeometryRay )

function GeometryRay:__init()
	self.length = 100
end

function GeometryRay:onDraw()
	self:applyColor()
	local l = self.length
	draw.fillRect( -1,-1, 1,1 )
	draw.drawLine( 0, 0, l, 0 )
	draw.fillRect( -1 + l, -1, 1 + l,1 )
end

function GeometryRay:onGetRect()
	local l = self.length
	return 0,0, l,1
end

function GeometryRay:setLength( l )
	self.length = l
end

--------------------------------------------------------------------
CLASS: GeometryBoxOutline ( GeometryComponent )
	:MODEL{
		Field 'size' :type( 'vec3' ) :getset( 'Size' );
	}
registerComponent( 'GeometryBoxOutline', GeometryBoxOutline )

function GeometryBoxOutline:__init()
	self.sizeX = 100
	self.sizeY = 100
	self.sizeZ = 100
end

function GeometryBoxOutline:getSize()
	return self.sizeX, self.sizeY, self.sizeZ
end

function GeometryBoxOutline:setSize( x,y,z )
	self.sizeX, self.sizeY, self.sizeZ = x,y,z
end

function GeometryBoxOutline:onDraw()
	local x,y,z = self.sizeX/2, self.sizeY/2, self.sizeZ/2
	self:applyColor()
	draw.drawBoxOutline( -x, -y, -z, x, y, z )
end

function GeometryBoxOutline:onGetRect()
	local x,y,z = self.sizeX/2, self.sizeY/2, self.sizeZ/2
	return -x, -y, x, y
end


--------------------------------------------------------------------
CLASS: GeometryPolygon ( GeometryComponent )
	:MODEL{
		Field 'verts' :array( 'number' ) :getset( 'Verts' ) :no_edit();
	}
registerComponent( 'GeometryPolygon', GeometryPolygon )

function GeometryPolygon:__init()
	self.boundRect = {0,0,0,0}
	self:setVerts{
		0,0,
		0,100,
		100,100,
		150, 50
	}
end

function GeometryPolygon:getVerts()
	return self.verts
end

function GeometryPolygon:setVerts( verts )
	self.verts = verts 
	local x0,y0,x1,y1
	for i = 1, #verts, 2 do
		local x, y = verts[ i ], verts[ i + 1 ]
		x0 = x0 and ( x < x0 and x or x0 ) or x
		y0 = y0 and ( y < y0 and y or y0 ) or y
		x1 = x1 and ( x > x1 and x or x1 ) or x
		y1 = y1 and ( y > y1 and y or y1 ) or y
	end
	self.boundRect = { x0 or 0, y0 or 0, x1 or 0, y1 or 0 }
	local loopVerts = { unpack(verts) }
	local count = #verts
	if count < 6 then return end
	table.insert( loopVerts, loopVerts[ 1 ] )
	table.insert( loopVerts, loopVerts[ 2 ] )
	self.loopVerts = loopVerts
end


function GeometryPolygon:onDraw()
	self:applyColor()
	draw.drawLine( unpack( self.loopVerts ) )
end

function GeometryPolygon:onGetRect()
	return unpack( self.boundRect )
end
