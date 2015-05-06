module 'mock'

local _animatorEditorTarget = nil
local _animatorEditorTargetScene = nil
function setAnimatorEditorTarget( entity )
	_animatorEditorTarget = entity
	_animatorEditorTargetScene = entity and entity.scene or nil
end

function getAnimatorEditorTarget()
	return _animatorEditorTarget, _animatorEditorTargetScene
end
