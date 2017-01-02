module 'mock'

CLASS: DeckComponent( GraphicsPropComponent )
	:MODEL{
		Field 'deck'  :asset_pre('deck2d\\..*;mesh') :getset('Deck');
	}

registerComponent( 'DeckComponent', DeckComponent )
registerEntityWithComponent( 'DeckComponent', DeckComponent)

--------------------------------------------------------------------
function DeckComponent:__init()
	self._moaiDeck = false	
end

--------------------------------------------------------------------
function DeckComponent:setMoaiDeck( deck )
	self.prop:setDeck( deck )
end

function DeckComponent:setDeck( deckPath )
	self.deckPath = deckPath
	local deck = mock.loadAsset( deckPath )
	local moaiDeck = deck and deck:getMoaiDeck()
	self._deck = deck
	self._moaiDeck = moaiDeck
	self.prop:setDeck( moaiDeck )
	self.prop:forceUpdate()
end

function DeckComponent:getDeck( deckPath )
	return self.deckPath	
end

function DeckComponent:getBounds()
	return self.prop:getBounds()
end

function DeckComponent:getTransform()
	return self.prop
end

function DeckComponent:getSourceSize()
	local deck = self._deck
	if deck then
		local w, h = deck:getSize()
		return w, h, 1
	else
		return 1, 1, 1
	end
end

--------------------------------------------------------------------
function DeckComponent:drawBounds()
	GIIHelper.setVertexTransform( self.prop )
	local x1,y1,z1, x2,y2,z2 = self.prop:getBounds()
	MOAIDraw.drawRect( x1,y1,x2,y2 )
end

--------------------------------------------------------------------
local defaultDeck2DShader = MOAIShaderMgr.getShader( MOAIShaderMgr.DECK2D_SHADER )

function DeckComponent:getDefaultShader()
	return defaultDeck2DShader
end

