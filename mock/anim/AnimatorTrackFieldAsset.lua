module 'mock'

function _getTargetFieldAssetType( key )
	return key:getTargetFieldAssetType()
end

CLASS: AnimatorKeyFieldAsset ( AnimatorKey )
	:MODEL{
		Field 'value' :asset( _getTargetFieldAssetType )
	}

function AnimatorKeyFieldAsset:__init()
	self.value = false
end

function AnimatorKeyFieldAsset:setValue( assetPath )
	self.value = assetPath
end

function AnimatorKeyFieldAsset:getTargetFieldAssetType()
	local field = self:getTrack().targetField
	local assetType = field.__assettype
	if type( assetType ) == 'function' then
		local target = self:getTrack():getEditorTargetObject()
		return assetType( target )
	else
		return assetType
	end
end

--------------------------------------------------------------------
CLASS: AnimatorTrackFieldAsset ( AnimatorTrackFieldDiscrete )

function AnimatorTrackFieldAsset:createKey( pos, context )
	local key = AnimatorKeyFieldAsset()
	key:setPos( pos )
	local target = context.target
	key:setValue( self.targetField:getValue( target ) )
	return self:addKey( key )
end

function AnimatorTrackFieldAsset:getIcon()
	return 'track_asset'
end
