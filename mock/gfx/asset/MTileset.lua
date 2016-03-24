module 'mock'

--------------------------------------------------------------------
--Quad with Normalmap
--------------------------------------------------------------------
local mtilesetVertexFormat = MOAIVertexFormat.new ()
mtilesetVertexFormat:declareCoord ( 1, MOAIVertexFormat.GL_FLOAT, 3 )
mtilesetVertexFormat:declareUV    ( 2, MOAIVertexFormat.GL_FLOAT, 2 )
mtilesetVertexFormat:declareColor ( 3, MOAIVertexFormat.GL_UNSIGNED_BYTE )

CLASS: MTileset ( NamedTileset )
	:MODEL{
	}

function MTileset:__init()
	self.verts = {}
	self.meshSpans = {}
	self.pack = false
end

function MTileset:createMoaiDeck()
	local mesh = MOAITileMesh.new ()	
	mesh:setPrimType ( MOAIMesh.GL_TRIANGLES )
	return mesh
end

function MTileset:update()
	local mesh = self:getMoaiDeck()

	local tex = self.pack.texMulti
	mesh:setTexture( tex )
	local u0,v0,u1,v1 = 0,0,1,1
	
	local us = u1-u0
	local vs = v1-v0

	local verts  = self.verts	
	local vertCount = #verts

	local vbo = MOAIGfxBuffer.new ()
	local memSize = vertCount * mtilesetVertexFormat:getVertexSize()
	vbo:reserve ( memSize )
	for i = 1, vertCount do
		local vert = verts[ i ]
		vbo:writeFloat ( vert[1], vert[2], vert[3] )
		vbo:writeFloat ( vert[4]*us + u0,  vert[5]*vs + v0 )
		vbo:writeColor32 ( 1, 1, 1 )
	end
	mesh:setVertexBuffer ( vbo, mtilesetVertexFormat )
	local count =  vbo:countElements ( mtilesetVertexFormat )
	mesh:setTotalElements ( count )
	
	--tile spans
	mesh:reserveTiles( self.tileCount )
	for i, span in ipairs( self.meshSpans ) do
		local offset, spanSize = span[1], span[2]
		mesh:setTile( i, offset, spanSize )
	end
	
	local u = {vbo:computeBounds ( mtilesetVertexFormat ) }
	if u[1] then
		-- mesh:setBounds ( unpack(u) )
		local tw, th = self.tileWidth, self.tileHeight
		mesh:setBounds( 0,0,0, 1,2.8,1 )
	end
end

local insert = table.insert
local function insertVert( output, verts, uvs, i )
	local vert = verts[i]
	local uv = uvs[i]
	local v = { vert[1], vert[2], vert[3], uv[1], uv[2] }
	insert( output, v )
end

function MTileset:load( deckData )
	self:loadData( deckData )	
	--load mesh verts
	local vbos = {}
	local u0,v0,u1,v1 = 0,0,1,1
	local us = u1-u0
	local vs = v1-v0
	local vertSize = mtilesetVertexFormat:getVertexSize()
	
	local currentVertexOffset = 0

	local verts = {}
	local meshSpans = {}
	for idx, tileData in ipairs( self.idToTile ) do
		local spanSize = 0
		for i, meshData in ipairs( tileData.meshes ) do
			local uvs = meshData.uv
			local vts = meshData.verts
			insertVert( verts, vts, uvs, 4 )
			insertVert( verts, vts, uvs, 2 )
			insertVert( verts, vts, uvs, 1 )
			insertVert( verts, vts, uvs, 4 )
			insertVert( verts, vts, uvs, 3 )
			insertVert( verts, vts, uvs, 2 )
			spanSize = spanSize + 6
		end
		meshSpans[ idx ] = { currentVertexOffset, spanSize }
		local name = self.idToName[ idx ]
		currentVertexOffset = currentVertexOffset + spanSize	
	end

	self.verts = verts
	self.meshSpans = meshSpans
	
end


