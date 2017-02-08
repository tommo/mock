module 'mock'

CLASS: ProtoArraySpawner ( ProtoSpawner )
	:MODEL{
		'----';
		Field 'gridSize' :type( 'vec3' ) :getset( 'GridSize' ) :meta{ decimals = 0 };
		Field 'cellSize' :type( 'vec3' ) :getset( 'CellSize' );
		Field 'offset'   :type( 'vec3' ) :getset( 'Offset' )
}

registerComponent( 'ProtoArraySpawner', ProtoArraySpawner )

function ProtoArraySpawner:__init()
	self.gridSize = { 1,1,1 }
	self.cellSize = { 50,50,50 }
	self.offset = { 0, 0, 0 } 
end


function ProtoArraySpawner:getGridSize()
	return unpack( self.gridSize )
end

function ProtoArraySpawner:setGridSize( x, y, z )
	self.gridSize = {
		math.floor( math.max( 1, x ) ),
		math.floor( math.max( 1, y ) ),
		math.floor( math.max( 1, z ) )
	}
end

function ProtoArraySpawner:getCellSize()
	return unpack( self.cellSize )
end

function ProtoArraySpawner:setCellSize( x, y, z )
	self.cellSize = { x, y, z }
end

function ProtoArraySpawner:getOffset()
	return unpack( self.offset )
end

function ProtoArraySpawner:setOffset( x, y, z )
	self.offset = { x, y, z }
end

function ProtoArraySpawner:onSpawn()
	local result = {}
	local gx, gy, gz = unpack( self.gridSize )
	local cx, cy, cz = unpack( self.cellSize )
	local ox, oy, oz = unpack( self.offset )
	for i = 1, gz do
	for j = 1, gy do
	for k = 1, gx do
		local dx = ( k - 1 ) * cx + rand( -ox, ox )
		local dy = ( j - 1 ) * cy + rand( -oy, oy )
		local dz = ( i - 1 ) * cz + rand( -oz, oz )
		local one = self:spawnOne( dx, dy, dz )
		table.insert( result, one )
	end
	end
	end
	return unpack( result )
end

--------------------------------------------------------------------
--EDITOR Support
function ProtoArraySpawner:onBuildGizmo()
	local giz = mock_edit.IconGizmo( 'spawn.png' )
	return giz
end
