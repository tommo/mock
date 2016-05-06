module 'mock'

CLASS: MSpriteCopy ( mock.GraphicsPropComponent )
	:MODEL{
		Field 'sourceSprite' :type( MSprite ) :set( 'setSourceSprite');
		Field 'overrideFeatures' :boolean();
		Field 'hiddenFeatures' :collection( 'string' ) :selection( 'getAvailFeatures' ) :getset( 'HiddenFeatures' );
		-- Field 'copyScl'      :boolean();
		-- Field 'copyRot'      :boolean();
		-- Field 'copyLoc'      :boolean();
		-- Field 'flipX' :boolean() :onset( 'updateFlip' );
		-- Field 'flipY' :boolean() :onset( 'updateFlip' );
	}

registerComponent( 'MSpriteCopy', MSpriteCopy )

function MSpriteCopy:__init()
	self.sourceSprite = false
	self.linked = false
	self.flipX = false
	self.flipY = false
	self.overrideFeatures = false
	self.deckInstance = MOAIGfxMaskedQuadListDeck2DInstance.new()
	self.prop:setDeck( self.deckInstance )
end

function MSpriteCopy:onAttach( ent )
	MSpriteCopy.__super.onAttach( self, ent )
	self:setSourceSprite( self.sourceSprite )
end

function MSpriteCopy:setSourceSprite( sprite )
	self.sourceSprite = sprite
	if not sprite then return end
	local spriteData = sprite.spriteData
	if not spriteData then return end
	-- if self.sourceSprite == sprite and self.linked then return end
	self.deckInstance:setSource( spriteData.frameDeck )
	self.prop:setAttrLink( MOAIProp.ATTR_INDEX, sprite.prop, MOAIProp.ATTR_INDEX )
	linkTransform( self.prop, sprite.prop )
	self:updateFeatures()
	-- self.linked = true
end

function MSpriteCopy:getTargetData()
	local source = self.sourceSprite
	return source and source.spriteData
end

function MSpriteCopy:setHiddenFeatures( hiddenFeatures )
	self.hiddenFeatures = hiddenFeatures or {}
	--update hiddenFeatures
	if self.sourceSprite then return self:updateFeatures() end
end

function MSpriteCopy:getHiddenFeatures()
	return self.hiddenFeatures
end

function MSpriteCopy:updateFeatures()
	local sprite = self.sourceSprite
	if not sprite then return end
	local data   = sprite.spriteData 
	if not data then return end
	local features = sprite.hiddenFeatures
	if self.overrideFeatures then
		features = self.hiddenFeatures
	end

	if not self.deckInstance then return end
	local featureTable = data.features
	if not featureTable then return end
	local instance = self.deckInstance
	for i = 0, 64 do --hide all
		instance:setMask( i, false )
	end
	for i, featureName in ipairs( features ) do
		local bit
		if featureName == '__base__' then
			bit = 0
		else
			bit = featureTable[ featureName ]
		end
		if bit then
			instance:setMask( bit, true ) --show target feature
		end
	end
end

function MSpriteCopy:getAvailFeatures()
	local result = {
		{ '__base__', '__base__' }
	}
	local data = self:getTargetData()
	if data then
		for i, n in ipairs( data.featureNames ) do
			result[ i+1 ] = { n, n }
		end
	end
	return result
end
