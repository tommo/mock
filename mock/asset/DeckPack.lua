module 'mock'

--------------------------------------------------------------------
--
--------------------------------------------------------------------
CLASS: DeckPack ()
	:MODEL{}

function DeckPack:__init()
	self.items = {}
	self.texColor = false
	self.texNormal = false
end

function DeckPack:getDeck( name )
	return self.items[ name ]
end

function DeckPack:load( path )
	local packData = loadAssetDataTable( path .. '/' .. 'decks.json' )
	self.texColor  = MOAITexture.new()
	self.texNormal = MOAITexture.new()
	self.texColor :load( path..'/decks.png'   )
	self.texColor :setFilter( MOAITexture.GL_NEAREST )
	self.texNormal:load( path..'/decks_n.png' )
	self.texMulti = MOAIMultiTexture.new()
	self.texMulti:reserve( 2 )
	self.texMulti:setTexture( 1, self.texColor )
	self.texMulti:setTexture( 2, self.texNormal )
	--
	for i, deckData in ipairs( packData['decks'] ) do
		local deckType = deckData['type']
		local name = deckData[ 'name' ]
		local deck
		if deckType =='deck2d.mquad' then
			deck = MQuadDeck()
			deck.pack = self
			deck:load( deckData )
		end
		self.items[ name ] = deck
	end

end


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
		mesh:setBounds ( unpack(u) )
	end

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


--------------------------------------------------------------------
--
--------------------------------------------------------------------
local function DeckPackloader( node )
	local pack = DeckPack()
	local dataPath = node:getObjectFile( 'export' )
	pack:load( dataPath )
	return pack
end

--------------------------------------------------------------------
local function DeckPackItemLoader( node )
	local pack = loadAsset( node.parent )
	local name = node:getName()	
	local item = pack:getDeck( name )
	if item then
		item:update()
		node.cached.deckItem = item
		local deck = item:getMoaiDeck()
		return deck
	end
	return nil
end

--------------------------------------------------------------------


registerAssetLoader ( 'deck_pack',         DeckPackloader )
registerAssetLoader ( 'deck2d.mquad',     DeckPackItemLoader )
