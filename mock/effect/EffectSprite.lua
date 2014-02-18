module 'mock'

--------------------------------------------------------------------
CLASS: EffectSprite ( EffectNode )
	:MODEL{
		Field 'deck'  :asset('deck2d\\..*');
		Field 'index' :int() :range(0);
		Field 'blend' :enum( EnumBlendMode );
	}


--------------------------------------------------------------------

CLASS: EffectAuroraSprite ( EffectNode )
	:MODEL{
		Field 'sprite' :asset( 'aurora_sprite' );
		Field 'blend' :enum( EnumBlendMode ) :getset('Blend');
	}

