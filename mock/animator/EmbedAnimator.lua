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
CLASS: ExportAnimatorParam ()
:MODEL {
	Field 'animatorData'	 :asset( 'animator_data' );
}

--------------------------------------------------------------------
CLASS: EmbedAnimator ( Animator )
	:MODEL{
		Field 'serializedData' :string() :no_edit() :getset( 'SerializedData' );
		Field 'data' :asset('animator_data')  :no_edit() :no_save();
		Field 'uniqueKey' :string() :no_edit();
		'----';
		Field 'exportData' :action( 'toolActionExportData' );
	}

registerComponent( 'EmbedAnimator', EmbedAnimator )

function EmbedAnimator:__init()
	self.data = AnimatorData()
	self.serializedData = ''
	self.uniqueKey = ''
end

function EmbedAnimator:onEditorInit()
	--add default clip
	self.data:createClip( 'default' )
	self.default = 'default'
	self.uniqueKey = MOAIEnvironment.generateGUID()
end

function EmbedAnimator:getSerializedData()
	local serialized = serializeToString( self.data, true )
	return serialized
end

function EmbedAnimator:setSerializedData( strData )
	local animatorData = loadEmbdedAnimatorData( strData )
	self.data = animatorData
end

function EmbedAnimator:toolActionExportData()
	local param = ExportAnimatorParam()
	if mock_edit.requestProperty( 'exporting animator data', param ) then
		if not param.animatorData then
			mock_edit.alertMessage( 'message', 'no animator data specified', 'info' )
			return false
		end
		local node = getAssetNode( param.animatorData )
		mock.serializeToFile( self.data, node:getObjectFile( 'data' )  )
		mock_edit.alertMessage( 'message', 'animator data exported!', 'info' )
	end
end
