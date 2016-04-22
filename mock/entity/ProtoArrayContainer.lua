module 'mock'

CLASS: ProtoArrayContainer ( mock.Entity )
	:MODEL{
		'----';
		Field 'proto' :asset_pre( 'proto' ) :set( 'setProto' );
		'----';
		Field 'resetLayer' :boolean() :onset( 'refreshProto' );
		'----';
		Field 'gridSize' :type( 'vec3' ) :getset( 'GridSize' ) :meta{ decimals = 0 };
		Field 'cellSize' :type( 'vec3' ) :getset( 'CellSize' );
		
	}

registerEntity( 'ProtoArrayContainer', ProtoArrayContainer )

function ProtoArrayContainer:__init()
	self.proto   = false
	self.resetTransform = true
	self.resetLoc = true
	self.resetScl = false
	self.resetRot = false
	self.resetLayer = false

	self.instances = {}
	self.instanceCount = 0

	self.gridSize = { 1,1,1 }
	self.cellSize = { 50,50,50 }

end

function ProtoArrayContainer:getGridSize()
	return unpack( self.gridSize )
end

function ProtoArrayContainer:setGridSize( x, y, z )
	self.gridSize = {
		math.floor( math.max( 1, x ) ),
		math.floor( math.max( 1, y ) ),
		math.floor( math.max( 1, z ) )
	}
	return self:refreshProto()
end

function ProtoArrayContainer:getCellSize()
	return unpack( self.cellSize )
end

function ProtoArrayContainer:setCellSize( x, y, z )
	self.cellSize = { x, y, z }
	return self:updateLayout()
end

function ProtoArrayContainer:refreshProto()
	if not self.loaded then return end

	for i, instance in ipairs( self.instances ) do
		instance:destroyWithChildrenNow()
	end
	self.instances = {}
	self.instanceCount = 0
	local instances = self.instances	
	if self.proto then
		local gw, gh, gd = self:getGridSize()
		local count = gw*gh*gd
		for i = 1, count do
			local instance = createProtoInstance( self.proto )
			instances[ i ] = instance
		end
		self.instanceCount = count
		self:updateLayout()
		local resetLayer = self.resetLayer
		local selfLayer = self:getLayer()
		for i = 1, count do
			local instance = instances[ i ]
			if resetLayer then
				self:addInternalChild( instance, selfLayer )
			else
				self:addInternalChild( instance )
			end
		end
		self.instance = instance
	end	
	self:updateLayout()
end

function ProtoArrayContainer:updateLayout()
	if self.instanceCount <= 0 then return end
	local gw, gh, gd = self:getGridSize()
	local cw, ch, cd = self:getCellSize()
	local i = 0
	local instances = self.instances
	for x = 0, gw-1 do
	for y = 0, gh-1 do
	for z = 0, gd-1 do
		i = i + 1 
		local instance = instances[ i ]
		local ix, iy, iz = x * cw, y * ch, z * cd
		if instance then instance:setLoc( ix, iy, iz ) end
	end
	end
	end
end

function ProtoArrayContainer:setProto( path )
	self.proto = path
	self:refreshProto()
end

function ProtoArrayContainer:getInstance()
	return self.instance
end

function ProtoArrayContainer:onLoad()
	self.loaded = true
	self:refreshProto()
end
