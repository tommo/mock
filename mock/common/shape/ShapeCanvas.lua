module 'mock'


--------------------------------------------------------------------
CLASS: ShapeCanvas ( mock.Component )
	:MODEL{
	
	}


function ShapeCanvas:__init()
	self.items = {}
end

function ShapeCanvas:addShape( shape )
	table.insert( self.items, shape )
end

function ShapeCanvas:removeShape( shape )
	local idx = table.index( self.items, shape )
	if idx then table.remove( self.items, idx ) end
end

function ShapeCanvas:createShape( shapeClas )
	local shape = shapeClas()
	local data = self:createShapeData( shape )
	if data then
		data:setShape( shape )
		return shape
	else
		_warn( 'failed to create shape item data' )
		return false
	end
end

function ShapeCanvas:createShapeData( shape )
	return ShapeItemData()
end

function ShapeCanvas:updateShape( shape, data )
end



--------------------------------------------------------------------
CLASS: ShapeItem ()
	:MODEL{
		Field 'name' :string();  
	}

function ShapeItem:__init()
	self.userdata = false
	self.active = true
	self.name   = false
end

function ShapeItem:getName()
	return self.name
end

function ShapeItem:setName( n )
	self.name = n
end

function ShapeItem:getData()
	return self.userdata
end

function ShapeItem:isActive()
	return self.active
end

function ShapeItem:setActive( active )
	if self.active == active then return end
	self.active = active
	if self.userdata then self.userdata:onShapeActiveChanged( self, active ) end
end

function ShapeItem:update()
	if self.userdata then self.userdata:onShapeUpdate( self ) end
end

function ShapeItem:init()
	if self.userdata then self.userdata:onShapeInit( self ) end
end

function ShapeItem:destroy()
	if self.userdata then self.userdata:onShapeDestroy( self ) end
end



--------------------------------------------------------------------
CLASS: ShapeItemData ()
	:MODEL{}

function ShapeItemData:__init()
	self.shape = false
end

function ShapeItemData:setShape( shapeItem )
	self.shape = shapeItem
	self:onShapeInit( shapeItem )
end

function ShapeItemData:onShapeUpdate( shape )
end

function ShapeItemData:onShapeDestroy( shape )
end

function ShapeItemData:onShapeInit( shape )
end

function ShapeItemData:onShapeActiveChange( shape, active )
end



