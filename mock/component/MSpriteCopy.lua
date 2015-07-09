module 'mock'

CLASS: MSpriteCopy ( mock.GraphicsPropComponent )
	:MODEL{
		Field 'sourceSprite' :type( MSprite ) :set( 'setSourceSprite');
		-- Field 'copyScl'      :boolean();
		-- Field 'copyRot'      :boolean();
		-- Field 'copyLoc'      :boolean();
		-- Field 'flipX' :boolean() :onset( 'updateFlip' );
		-- Field 'flipY' :boolean() :onset( 'updateFlip' );
	}

registerComponent( 'MSpriteCopy', MSpriteCopy )

function MSpriteCopy:__init()
	self.sourceSprite = false
	self.flipX = false
	self.flipY = false
end

function MSpriteCopy:onAttach( ent )
	MSpriteCopy.__super.onAttach( self, ent )
	self:setSourceSprite( self.sourceSprite )
end

function MSpriteCopy:setSourceSprite( sprite )
	self.sourceSprite = sprite
	if not sprite then return end
	self.prop:setDeck( sprite.deckInstance )
	self.prop:setAttrLink( MOAIProp.ATTR_INDEX, sprite.prop, MOAIProp.ATTR_INDEX )
	linkTransform( self.prop, sprite.prop )
end

-- function MSpriteCopy:updateFlip()
-- 	self.prop:setScl( self.flipX and -1 or 1, self.flipY and -1 or 1, 1 )
-- end
