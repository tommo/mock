module 'mock'

EnumAnimCurveTweenMode = {
	{ 'constant'          , MOAIAnimCurveEX.SPAN_MODE_CONSTANT          };
	{ 'linear'            , MOAIAnimCurveEX.SPAN_MODE_LINEAR            };
	{ 'bezier'            , MOAIAnimCurveEX.SPAN_MODE_BEZIER            };
}

--------------------------------------------------------------------
require 'mock.animator.AnimatorTargetId'
require 'mock.animator.AnimatorState'
require 'mock.animator.AnimatorClip'
require 'mock.animator.AnimatorData'
require 'mock.animator.Animator'
require 'mock.animator.EmbedAnimator'
require 'mock.animator.AnimatorEditorSupport'

--------------------------------------------------------------------
--value tracks
require 'mock.animator.AnimatorEventTrack'
require 'mock.animator.AnimatorValueTrack'
require 'mock.animator.CustomAnimatorTrack'

require 'mock.animator.AnimatorKeyVec'
require 'mock.animator.AnimatorKeyColor'

--------------------------------------------------------------------
require 'mock.animator.AnimatorTrackAttr'

--------------------------------------------------------------------
require 'mock.animator.AnimatorTrackField'
	require 'mock.animator.AnimatorTrackFieldNumber'	
	require 'mock.animator.AnimatorTrackFieldInt'	
	require 'mock.animator.AnimatorTrackFieldVec'
	require 'mock.animator.AnimatorTrackFieldColor'
	require 'mock.animator.AnimatorTrackFieldDiscrete'
	require 'mock.animator.AnimatorTrackFieldBoolean'
	require 'mock.animator.AnimatorTrackFieldString'
	require 'mock.animator.AnimatorTrackFieldEnum'
	require 'mock.animator.AnimatorTrackFieldAsset'
	-- require 'mock.animator.AnimatorTrackFieldObjRef'

	function getAnimatorTrackFieldClass( ftype )
		if ftype == 'number' then
			return AnimatorTrackFieldNumber
		elseif ftype == 'int' then
			return AnimatorTrackFieldInt	
		elseif ftype == 'boolean' then
			return AnimatorTrackFieldBoolean
		elseif ftype == 'string' then
			return AnimatorTrackFieldString
		elseif ftype == 'vec2' then
			return AnimatorTrackFieldVec2
		elseif ftype == 'vec3' then
			return AnimatorTrackFieldVec3
		elseif ftype == 'color' then
			return AnimatorTrackFieldColor
		elseif ftype == '@asset' then
			return AnimatorTrackFieldAsset
		elseif ftype == '@enum' then
			return AnimatorTrackFieldEnum
		end
		return false
	end
--------------------------------------------------------------------

--------------------------------------------------------------------
--builtin custom track
--------------------------------------------------------------------
require 'mock.animator.tracks.AnimatorAnimatorTrack'
require 'mock.animator.tracks.EntityMsgAnimatorTrack'
require 'mock.animator.tracks.ScriptAnimatorTrack'
