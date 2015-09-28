module 'mock'

local _clipDataCache = {}
local function loadEmbdedAnimatorData( strData )
	local loadedData = _clipDataCache[ strData ]
	if loadedData then return loadedData end
	local animatorData = loadAnimatorDataFromString( strData )
	_clipDataCache[ strData ] = animatorData
	return animatorData
end

--------------------------------------------------------------------
CLASS: EmbedAnimator ( Animator )
	:MODEL{
		Field 'data' :no_edit();
		Field 'serializedData' :no_edit() :string() :getset( 'SerializedData' )
	}

registerComponent( 'EmbedAnimator', EmbedAnimator )

function EmbedAnimator:__init()
	self.data = AnimatorData()
end

function EmbedAnimator:getSerializedData()
	local serialized = serializeToString( self.data )
	return serialized
end

function EmbedAnimator:setSerializedData( strData )
	local animatorData = loadEmbdedAnimatorData( strData )
	self.data = animatorData
end
