module 'mock'

--------------------------------------------------------------------
--Common Routine
--------------------------------------------------------------------
-- CLASS: EffectPropNode ( EffectNode )
-- 	:MODEL{}

-- function EffectPropNode:createProp( fxState )

-- end

-- function EffectPropNode:onLoad( fxState )
-- 	local prop = self:createProp( fxState )

-- end

--------------------------------------------------------------------
--Static Sprite
--------------------------------------------------------------------
CLASS: EffectStaticSprite ( EffectTransformNode )
	:MODEL{
		Field 'deck'  :asset('deck2d\\..*');
		Field 'index' :int() :range(0);
		Field 'blend' :enum( EnumBlendMode );
	}

function EffectStaticSprite:onLoad( fxState )
	local sprite = MOAIProp.new()
	local deck = loadAsset( self.deck )
	sprite:setDeck( deck )
	setPropBlend( sprite, self.blend )
	--todo: shader	
	self:applyTransformToProp( sprite )
	fxState:linkTransform( sprite.prop )
	fxState:linkPartition( sprite.prop )
	fxState[ self ] = sprite
end

--------------------------------------------------------------------
--Aurora Sprite
--------------------------------------------------------------------
CLASS: EffectAuroraSprite ( EffectTransformNode )
	:MODEL{
		Field 'spritePath' :asset( 'aurora_sprite' );
		Field 'clip'  :string() :selection( 'getClipNames' );
		Field 'mode'  :enum( EnumTimerMode );
		Field 'FPS'   :int() :range( 0,200 ) :widget( 'slider' );
		'----';
		Field 'blend' :enum( EnumBlendMode );
	}

function EffectAuroraSprite:__init()
	self.blend = 'alpha'
	self.mode  = MOAITimer.NORMAL
	self.FPS   = 10
end

function EffectAuroraSprite:onLoad( fxState )
	local sprite = AuroraSprite()
	sprite:setSprite( self.spritePath )
	sprite:setFPS( self.FPS )
	sprite:play( self.clip, self.mode )
	sprite:setBlend( self.blend )
	self:applyTransformToProp( sprite )
	fxState:linkTransform( sprite.prop )
	fxState:linkPartition( sprite.prop )
	fxState[ self ] = sprite	
end

function EffectAuroraSprite:getClipNames()
	local data = mock.loadAsset( self.spritePath )
	if not data then return nil end
	local result = {}
	for k,i in pairs( data.animations ) do
		table.insert( result, { k, k } )
	end
	return result
end

--------------------------------------------------------------------
registerTopEffectNodeType(
	'sprite-static',
	EffectStaticSprite,
	EffectCategoryTransform	
)


registerTopEffectNodeType(
	'sprite-aurora',
	EffectAuroraSprite,
	EffectCategoryTransform
)

