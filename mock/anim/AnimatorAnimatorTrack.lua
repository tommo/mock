module 'mock'


--------------------------------------------------------------------
CLASS: AnimatorAnimatorKey ( AnimatorKey )
	:MODEL{
		Field 'clip'  :string() :selection( 'getClipNames' ) :set( 'setClip' );
		Field 'playMode' :enum( EnumTimerMode );
		Field 'FPS'   :int();
	}


--------------------------------------------------------------------
CLASS: AnimatorAnimatorTrack ( CustomAnimatorTrack )
	:MODEL{
	}

