module 'mock'

---A integral grid based spatial helper

CLASS: SpatialGrid ()

function SpatialGrid:__init( gridSize )
	self.gridSize = gridSize or 30
	self.data = {}
	self.nodeToCell = {}
end

local floor = math.floor
function SpatialGrid:insertNode( x, y, node )
	local cell0 = self.nodeToCell[ node ]
	if cell0 then
		cell0[ node ] = nil
		--todo: shrink
	end

	local cell = self:affirmCell( x, y )
	cell[ node ] = true
	self.nodeToCell[ node ] = cell

end

function SpatialGrid:removeNode( node )
	local cell0 = self.nodeToCell[ node ]
	if cell0 then
		cell0[ node ] = nil
		--todo: shrink
	end
end

function SpatialGrid:affirmCell( x, y )
	local gs = self.gridSize
	local gx, gy = floor( x/gs ), floor( y/gs )
	return self:affirmCellI( gx, gy )
end

function SpatialGrid:affirmCellI( gx, gy )
	local row = self.data[ gy ]
	if not row then
		row = {}
		self.data[ gy ] = row
	end
	local cell = row[ gx ]
	if not cell then
		cell = {}
		row[ gx ] = cell
	end
	return cell
end

function SpatialGrid:findCellI( gx, gy )
	local row = self.data[ gy ]
	return row and row[ gx ]
end

function SpatialGrid:findCell( x, y )
	local gs = self.gridSize
	local gx, gy = floor( x/gs ), floor( y/gs )
	return self:findCellI( gx, gy )
end

function SpatialGrid:findCellRect( x0, y0, x1, y1 )
	--TODO
end

function SpatialGrid:findNodesInRect( x0, y0, x1, y1 )
	local gs = self.gridSize
	local gx0, gy0 = floor( x0/gs ), floor( y0/gs )
	local gx1, gy1 = floor( x1/gs ), floor( y1/gs )
	if gx1 < gx0 then gx1, gx0 = gx0, gx1 end
	if gy1 < gy0 then gy1, gy0 = gy0, gy1 end
	--TODO
end