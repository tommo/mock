module 'mock'


--------------------------------------------------------------------
CLASS: ShapeItem ()
	:MODEL{}

function ShapeItem:__init()
	self.userdata = false
end


--------------------------------------------------------------------
CLASS: ShapeCanvas ()
	:MODEL{}

function ShapeCanvas:__init()
	self.shapes = {}
end

function ShapeCanvas:_addShape( shape )
	table.insert( self.shapes, shape )
end

function ShapeCanvas:removeShape( shape )
	local idx = table.index( self.shapes, shape )
	if idx then table.remove( self.shapes, idx ) end
end

function ShapeCanvas:createShape( shapeClas )
	local shape = shapeClas()
	local data = self:createShapeData( shape )
end

function ShapeCanvas:createShapeData( shape )
end

function ShapeCanvas:updateShape( shape, data )
end
