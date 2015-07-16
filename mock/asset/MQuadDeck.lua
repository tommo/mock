module 'mock'

--------------------------------------------------------------------
--Quad with Normalmap
--------------------------------------------------------------------
local mquadVertexFormat = MOAIVertexFormat.new ()
mquadVertexFormat:declareCoord ( 1, MOAIVertexFormat.GL_FLOAT, 3 )
mquadVertexFormat:declareUV    ( 2, MOAIVertexFormat.GL_FLOAT, 2 )
mquadVertexFormat:declareColor ( 3, MOAIVertexFormat.GL_UNSIGNED_BYTE )

CLASS: MQuadDeck ( Deck2D )
	:MODEL{
	}

function MQuadDeck:__init()
	self.verts = {}
	self.pack = false
end

function MQuadDeck:createMoaiDeck()
	local mesh = MOAITileMesh.new ()	
	mesh:setPrimType ( MOAIMesh.GL_TRIANGLES )
	return mesh
end

function MQuadDeck:getSize()
	return self.w, self.h, self.depth
end

function MQuadDeck:update()
	local mesh = self:getMoaiDeck()

	local tex = self.pack.texMulti
	mesh:setTexture( tex )
	local u0,v0,u1,v1 = 0,0,1,1
	
	local us = u1-u0
	local vs = v1-v0

	local verts  = self.verts
	local vertCount = #verts

	local vbo = MOAIGfxBuffer.new ()
	local memSize = vertCount * mquadVertexFormat:getVertexSize()
	vbo:reserve ( memSize )
	for i = 1, vertCount do
		local vert = verts[ i ]
		vbo:writeFloat ( vert[1], vert[2], vert[3] )
		vbo:writeFloat ( vert[4]*us + u0,  vert[5]*vs + v0 )
		vbo:writeColor32 ( 1, 1, 1 )
	end
	mesh:setVertexBuffer ( vbo, mquadVertexFormat )
	local count =  vbo:countElements ( mquadVertexFormat )
	mesh:setTotalElements ( count )
	local u = {vbo:computeBounds ( mquadVertexFormat ) }
	if u[1] then
		local x0,y0,z0, x1,y1,z1 = unpack(u)
		mesh:setBounds ( x0,y0,z0, x1,y1,z1 )
		self.w, self.h, self.depth = x1 - x0, y1 - y0 , z1 - z0
	end
	mesh:setTile( 1, 0, count )

end

local insert = table.insert
local function insertVert( output, verts, uvs, i )
	local vert = verts[i]
	local uv = uvs[i]
	local v = { vert[1], vert[2], vert[3], uv[1], uv[2] }
	insert( output, v )
end

function MQuadDeck:load( deckData )
	local verts = {}
	for i, mesh in ipairs( deckData.meshes ) do
		local uvs = mesh.uv
		local vts = mesh.verts
		insertVert( verts, vts, uvs, 4 )
		insertVert( verts, vts, uvs, 2 )
		insertVert( verts, vts, uvs, 1 )
		insertVert( verts, vts, uvs, 4 )
		insertVert( verts, vts, uvs, 3 )
		insertVert( verts, vts, uvs, 2 )
	end
	self.verts = verts
end


