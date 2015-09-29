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
		Field 'serializedData' :string() :no_edit() :getset( 'SerializedData');
		Field 'data' :asset('animator_data')  :no_edit() :no_save();
	}

registerComponent( 'EmbedAnimator', EmbedAnimator )

function EmbedAnimator:__init()
	self.data = AnimatorData()
	self.serializedData = 'shit'
end

function EmbedAnimator:onEditorInit()
	--add default clip
	self.data:createClip( 'default' )
	self.default = 'default'
end

function EmbedAnimator:getSerializedData()
	local serialized = serializeToString( self.data, true )
	return serialized
end

function EmbedAnimator:setSerializedData( strData )
	local animatorData = loadEmbdedAnimatorData( strData )
	self.data = animatorData
end
