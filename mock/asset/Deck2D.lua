module 'mock'
--------------------------------------------------------------------
local function getTextureUV( tex )
	local ttype = tex.type
	local t, uv
	if ttype == 'sub_texture' then
		t = tex.atlas
		uv = tex.uv
		
	elseif ttype == 'framebuffer' then
		t = tex:getMoaiFrameBuffer()
		uv = { 0,0,1,1 }

	else
		t = tex
		uv = { 0,1,1,0 }

	end

	return t, uv
end

local loadedDecks = table.weak()

function getLoadedDecks()
	return loadedDecks
end

--------------------------------------------------------------------
CLASS: Deck2D ()
	:MODEL {
		Field 'type'     :string()  :no_edit();
		Field 'name'     :string()  :getset('Name')    :readonly() ;
		Field 'texture'  :asset('texture')  :getset('Texture') :readonly() ;		
	}

function Deck2D:__init()
	loadedDecks[ self ] = true
	self._deck = self:createMoaiDeck()
	self._deck.source = self
	self.name  = 'deck'
	self.w = 0
	self.h = 0
end

function Deck2D:setTexture( path, autoResize )
	local tex, node = mock.loadAsset( path )
	if not tex then return end
	if autoResize ~= false then
		local w, h = tex:getSize()
		self.w = w
		self.h = h
	end
	self.texturePath = path
	self.texture = tex
	self:update()
end

function Deck2D:getSize()
	return self.w , self.h
end

function Deck2D:setSize( w, h )
	self.w = w
	self.h = h
end

function Deck2D:getRect()
	local ox,oy = self:getOrigin()
	local w,h   = self:getSize()
	return ox - w/2, oy - h/2, ox + w/2, oy + h/2 
end

function Deck2D:getTexture()
	return self.texturePath
end

function Deck2D:setName( n )
	self.name = n
end

function Deck2D:getName()
	return self.name
end

function Deck2D:setOrigin( dx, dy )
end

function Deck2D:getOrigin()
	return 0,0
end

function Deck2D:getMoaiDeck()	
	return self._deck
end

function Deck2D:createMoaiDeck()
end

function Deck2D:update()
end


--------------------------------------------------------------------
CLASS: Quad2D ( Deck2D )
	:MODEL{
		Field 'ox' :number() :label('offset X') ;
		Field 'oy' :number() :label('offset Y') ;
		Field 'w'  :number() :label('width')  ;
		Field 'h'  :number() :label('height') ;
	}

function Quad2D:__init()
	self.ox = 0
	self.oy = 0
	self.w = 0
	self.h = 0
end

function Quad2D:setOrigin( ox, oy )
	self.ox = ox
	self.oy = oy
end

function Quad2D:getOrigin()
	return self.ox, self.oy
end

function Quad2D:createMoaiDeck()
	return MOAIGfxQuad2D.new()
end

function Quad2D:update()
	local deck = self:getMoaiDeck()
	
	local tex, uv = getTextureUV( self.texture )
	deck:setTexture( tex )
	deck:setUVRect( unpack( uv ) )

	local w, h = self.w, self.h
	deck:setRect( self.ox - w/2, self.oy - h/2, self.ox + w/2, self.oy + h/2 )
end



--------------------------------------------------------------------
CLASS: Tileset ( Deck2D )
	:MODEL {
		Field 'ox'       :int() :label('offset X') ;
		Field 'oy'       :int() :label('offset Y') ;
		Field 'tw'       :int() :label('tile width')  ;
		Field 'th'       :int() :label('tile height') ;
		Field 'spacing'  :int() :label('spacing')  ;
	}

function Tileset:__init()
	self.ox      = 0
	self.oy      = 0
	self.tw      = 32
	self.th      = 32
	self.col     = 1
	self.row     = 1
	self.spacing = 0
end

function Tileset:createMoaiDeck()
	local deck = MOAITileDeck2D.new()
	return deck
end

function Tileset:update()
	local texW, texH = self.w, self.h
	local tw, th  = self.tw, self.th
	local ox, oy  = self.ox, self.oy
	local spacing = self.spacing

	if tw < 0 then tw = 1 end
	if th < 0 then th = 1 end

	self.tw = tw
	self.th = th
	local w1, h1   = tw + spacing, th + spacing
	local col, row = math.floor(texW/w1), math.floor(texH/h1)	

	local deck = self:getMoaiDeck()

	local tex, uv = getTextureUV( self.texture )
	local u0,v0,u1,v1 = unpack( uv )
	deck:setTexture( tex )

	local du, dv = u1 - u0, v1 - v0
	deck:setSize(
		col, row, 
		w1/texW * du,      h1/texH * dv,
		ox/texW * du + u0, oy/texH * dv + v0,
		tw/texW * du,      th/texH * dv
		)
	
	self.col = col
	self.row = row

end

--------------------------------------------------------------------
CLASS: StretchPatch ( Quad2D )
	:MODEL {
		Field 'left'   :number() :label('border left')   :meta{ min=0, max=1 };
		Field 'right'  :number() :label('border right')  :meta{ min=0, max=1 };
		Field 'top'    :number() :label('border top')    :meta{ min=0, max=1 };
		Field 'bottom' :number() :label('border bottom') :meta{ min=0, max=1 };
	}

function StretchPatch:__init()
	self.ox = 0
	self.oy = 0
	self.w = 0
	self.h = 0

	self.left   = 0.3
	self.right  = 0.3
	self.top    = 0.3
	self.bottom = 0.3

end

function StretchPatch:setOrigin( ox, oy )
	self.ox = ox
	self.oy = oy
end

function StretchPatch:createMoaiDeck()
	local deck = MOAIStretchPatch2D.new()
	deck:reserveRows( 3 )
	deck:reserveColumns( 3 )
	deck:reserveUVRects( 1 )
	deck:setUVRect( 1, 0, 1, 1, 0 )
	return deck
end

function StretchPatch:update()
	local deck = self:getMoaiDeck()

	local tex, uv = getTextureUV( self.texture )
	deck:setTexture( tex )
	deck:setUVRect( 1, unpack( uv ) )	

	local w, h = self.w, self.h
	deck:setRect( self.ox - w/2, self.oy - h/2, self.ox + w/2, self.oy + h/2 )

	deck:setRow( 1, self.top, false )
	deck:setRow( 3, self.bottom, false )
	deck:setRow( 2, 1 - (self.top+self.bottom), true )

	deck:setColumn( 1, self.left, false )
	deck:setColumn( 3, self.right, false )
	deck:setColumn( 2, 1-(self.left+self.right), true )

	deck.patchWidth = w
	deck.patchHeight = h
end


--------------------------------------------------------------------
CLASS: PolygonDeck ( Deck2D )
	:MODEL{
		Field 'polyline'   :array() :no_edit();		
		Field 'vertexList' :array() :no_edit();		
		Field 'indexList'  :array() :no_edit();		
	}

local vertexFormat = MOAIVertexFormat.new ()
vertexFormat:declareCoord ( 1, MOAIVertexFormat.GL_FLOAT, 2 )
vertexFormat:declareUV ( 2, MOAIVertexFormat.GL_FLOAT, 2 )
vertexFormat:declareColor ( 3, MOAIVertexFormat.GL_UNSIGNED_BYTE )

function PolygonDeck:__init()
	self.polyline   = false
	self.vertexList = {}
	self.indexList  = {}
end

function PolygonDeck:createMoaiDeck()
	local mesh = MOAIMesh.new ()	
	mesh:setPrimType ( MOAIMesh.GL_TRIANGLES )
	return mesh
end

function PolygonDeck:update()
	-- local w, h = self.w, self.h
	-- mesh:setRect( self.ox - w/2, self.oy - h/2, self.ox + w/2, self.oy + h/2 )
	local mesh = self:getMoaiDeck()

	local tex, uv = getTextureUV( self.texture )
	local u0,v0,u1,v1 = unpack( uv )
	mesh:setTexture( tex )
	
	local us = u1-u0
	local vs = v1-v0

	local vertexList  = self.vertexList
	local vertexCount = #vertexList
	local indexList   = self.indexList
	local indexCount  = #indexList

	local vbo = MOAIVertexBuffer.new ()
	vbo:setFormat ( vertexFormat )
	vbo:reserveVerts ( vertexCount )
	for i = 1, vertexCount, 4 do
		local x, y = vertexList[ i ], vertexList[ i + 1 ]
		local u, v = vertexList[ i + 2 ], vertexList[ i + 3 ]
		vbo:writeFloat ( x, y )
		vbo:writeFloat ( u*us + u0,  v*vs +v0 )
		vbo:writeColor32 ( 1, 1, 1 )
	end
	vbo:bless ()

	local ibo = MOAIIndexBuffer.new ()
	ibo:reserve ( indexCount )
	for i = 1, indexCount, 2 do
		local a, b = indexList[ i ], indexList[ i + 1 ]
		ibo:setIndex( i, a, b )
	end

	mesh:setVertexBuffer ( vbo )
	-- mesh:setIndexBuffer ( ibo )

end

--------------------------------------------------------------------
--PACK
--------------------------------------------------------------------
CLASS: Deck2DPack()
:MODEL{
	Field 'name'  :string();
	Field 'decks' :array( Deck2D ) :no_edit() :sub()
}

function Deck2DPack:__init()
	self.decks = {}
end

function Deck2DPack:getDeck( name )
	for i, deck in ipairs( self.decks ) do
		if deck.name == name then return deck end
	end
	return nil
end

function Deck2DPack:addDeck( name, dtype, src )
	local deck
	if dtype == 'quad' then
		local quad = mock.Quad2D()
		quad:setTexture( src )
		deck = quad
	elseif dtype == 'tileset' then
		local tileset = mock.Tileset()
		tileset:setTexture( src )
		deck = tileset
	elseif dtype == 'stretchpatch' then
		local patch = mock.StretchPatch()
		patch:setTexture( src )
		deck = patch
	elseif dtype == 'polygon' then
		local poly = mock.PolygonDeck()
		poly:setTexture( src )
		deck = poly
	end
	deck.type = dtype
	deck:setName( name )
	table.insert( self.decks, deck )
	return deck
end

function Deck2DPack:removeDeck( deck )
	local idx  = table.find( self.decks, deck )
	if idx then table.remove( self.decks, idx ) end
end

--------------------------------------------------------------------
function Deck2DPackLoader( node )
	local packData   = loadAssetDataTable( node:getObjectFile('def') )
	local pack = deserialize( nil, packData )
	return pack
end

local function Deck2DItemLoader( node )
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
registerAssetLoader ( 'deck2d', Deck2DPackLoader )

registerAssetLoader ( 'deck2d.quad',         Deck2DItemLoader )
registerAssetLoader ( 'deck2d.tileset',      Deck2DItemLoader )
registerAssetLoader ( 'deck2d.stretchpatch', Deck2DItemLoader )
registerAssetLoader ( 'deck2d.polygon', Deck2DItemLoader )
