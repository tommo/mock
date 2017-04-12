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
	self.texColor :load( path..'/decks.png'  , MOAIImage.TRUECOLOR )
	self.texColor :setFilter( MOAITexture.GL_NEAREST )
	self.texNormal:load( path..'/decks_n.png', MOAIImage.TRUECOLOR )
	self.texNormal:setFilter( MOAITexture.GL_NEAREST )
	-- self.texNormal:setFilter( MOAITexture.GL_LINEAR )
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
			deck.name = name
			deck:load( deckData )

		elseif deckType == 'deck2d.mtileset' then
			deck = MTileset()
			deck.pack = self
			deck.name = name
			deck:load( deckData )

		elseif deckType == 'deck2d.quads' then
			deck = QuadsDeck()
			deck.pack = self
			deck.name = name
			deck:load( deckData )
			
		end
		self.items[ name ] = deck
	end

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
		return item
	end
	return nil
end

--------------------------------------------------------------------


registerAssetLoader ( 'deck_pack',        DeckPackloader )
registerAssetLoader ( 'deck2d.mquad',     DeckPackItemLoader )
registerAssetLoader ( 'deck2d.mtileset',  DeckPackItemLoader )
registerAssetLoader ( 'deck2d.quads',     DeckPackItemLoader )
