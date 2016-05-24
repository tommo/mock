module 'mock'

CLASS: ProtoArraySpawner ( ProtoSpawner )
	:MODEL{
		'----';
		Field 'gridSize' :type( 'vec3' ) :getset( 'GridSize' ) :meta{ decimals = 0 };
		Field 'cellSize' :type( 'vec3' ) :getset( 'CellSize' );
}

registerComponent( 'ProtoArraySpawner', ProtoArraySpawner )

function ProtoArraySpawner:__init()
	self.gridSize = { 1,1,1 }
	self.cellSize = { 50,50,50 }
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

function ProtoArraySpawner:onSpawn()
	local gx, gy, gz = unpack( self.gridSize )
	local cx, cy, cz = unpack( self.cellSize )
	for i = 1, gz do
	for j = 1, gy do
	for k = 1, gx do
		local dx = ( k - 1 ) * cx
		local dy = ( j - 1 ) * cy
		local dz = ( i - 1 ) * cz
		self:spawnOne( dx, dy, dz )
	end
	end
	end
end

--------------------------------------------------------------------
--EDITOR Support
function ProtoArraySpawner:onBuildGizmo()
	local giz = mock_edit.IconGizmo( 'spawn.png' )
	return giz
end
