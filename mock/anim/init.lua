module 'mock'

EnumAnimCurveTweenMode = {
	{ 'constant'          , MOAIAnimCurveEX.SPAN_MODE_CONSTANT          };
	{ 'linear'            , MOAIAnimCurveEX.SPAN_MODE_LINEAR            };
	{ 'bezier'            , MOAIAnimCurveEX.SPAN_MODE_BEZIER            };
}

--------------------------------------------------------------------
require 'mock.anim.AnimatorTargetId'
require 'mock.anim.AnimatorState'
require 'mock.anim.AnimatorClip'
require 'mock.anim.AnimatorData'
require 'mock.anim.Animator'

--------------------------------------------------------------------
require 'mock.anim.AnimatorKeyCommon'

--------------------------------------------------------------------
require 'mock.anim.AnimatorTrackField'
require 'mock.anim.AnimatorTrackAttr'

--------------------------------------------------------------------
require 'mock.anim.tracks.AnimatorTrackMessage'
