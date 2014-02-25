module 'mock'

-- --------------------------------------------------------------------
-- CLASS: EffectSprite ( EffectNode )
-- 	:MODEL{
-- 		Field 'deck'  :asset('deck2d\\..*');
-- 		Field 'index' :int() :range(0);
-- 		Field 'blend' :enum( EnumBlendMode );
-- 	}


--------------------------------------------------------------------

CLASS: EffectAuroraSprite ( EffectNode )
	:MODEL{
		Field 'spriteData' :asset( 'aurora_sprite' ) :onset( 'refresh' );
		Field 'clip'  :string();
		Field 'blend' :enum( EnumBlendMode ) :onset( 'refresh' );
	}

function EffectAuroraSprite:__init()
	self.blend = 'alpha'
	self.sprite = AuroraSprite()
end

function EffectAuroraSprite:refresh()
	self.sprite:setBlend( self.blend )
	self.sprite.sprite = self.spriteData
end

--------------------------------------------------------------------
registerEffectNodeType(
	'sprite-aurora',
	EffectAuroraSprite,
	'root'
)
