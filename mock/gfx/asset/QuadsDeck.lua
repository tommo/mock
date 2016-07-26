module 'mock'

--------------------------------------------------------------------
CLASS: QuadsDeck ( Deck2D )
	:MODEL {
	}

function QuadsDeck:__init()
	self.data = false

end

function QuadsDeck:createMoaiDeck()
	local deck = MOAIGfxQuadDeck2D.new()
	return deck
end

function QuadsDeck:load( deckData )
	self.data = deckData
end

function QuadsDeck:update()
	local data = self.data
	if not data then return end
	local deck = self:getMoaiDeck()
	local tex = self.pack.texMulti
	deck:setTexture( tex )
	local count = #data.quads
	deck:reserve( count )
	for i, quadData in ipairs( data.quads ) do
		local index = quadData.index
		deck:setRect( index, unpack( quadData.rect ) )
		deck:setUVRect( index, unpack( quadData.uv ) )
	end

end

