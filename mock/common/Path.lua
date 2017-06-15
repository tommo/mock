module 'mock'

--TODO

--------------------------------------------------------------------
CLASS: PathVert ()

function PathVert:__init()
	self.x = 0
	self.y = 0
	self.z = 0
end

function PathVert:setLoc( x,y,z )
	self.x = x or self.x
	self.y = y or self.y
	self.z = z or self.z
end

function PathVert:getLoc()
	return self.x, self.y, self.z
end

--------------------------------------------------------------------
CLASS: PathData ()

function PathData:__init()
	self.verts = {}
	self.builtVertCoords = {}
	self._loop = false
	self.dirty = true
	self:testData()
end

function PathData:testData()
	self:addVert( 0, 0, 0 )
	self:addVert( 100, 0, 0 )
	self:addVert( 100, 100, 0 )
	self:addVert( 100, 150, 0 )
end

function PathData:addVert( x,y,z )
	local vert = self:createVert()	
	vert:setLoc( x, y, z )
	return vert
end

function PathData:createVert()
	local v = PathVert()
	table.insert( self.verts, v )
	return v
end

function PathData:insertVert( idx )
	local vert = self:createVert()
	--TODO
	return vert
end

function PathData:getLength()
	return 0
end

function PathData:getPoint( t )
end

function PathData:isLoop()
	return self._loop
end

local insert = table.insert
function PathData:buildVertCoords()
	local result = {}
	for i, vert in ipairs( self.verts ) do
		local x, y, z = vert:getLoc()
		insert( result, x )
		insert( result, y )
	end
	self.builtVertCoords = result
	return result
end

function PathData:getVertCoords()
	if self.dirty then
		self:buildVertCoords()
	end
	return self.builtVertCoords
end


--------------------------------------------------------------------
CLASS: Path (mock.Component)
	:MODEL{}

-- mock.registerComponent( 'Path', Path )
-- mock.registerEntityWithComponent( 'Path', Path )

function Path:__init()
	self.pathData = PathData()
end

function Path:getData()
	return self.pathData
end

function Path:getVertCoords()
	return self.pathData:getVertCoords()
end

