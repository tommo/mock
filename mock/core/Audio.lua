module 'mock'

--------------------------------------------------------------------
CLASS: AudioManager ()
	:MODEL{}

local _singleton = false
function AudioManager.get()
	return _singleton
end

function AudioManager:__init()
	assert( not _singleton, 'duplicated AudioManager registration' )
	_singleton = self	
end

function AudioManager:init()
	initFmodDesigner()
end

function AudioManager:getListener()
	return nil
end

function AudioManager:getMasterVolume()
	return self:getCategoryVolume( 'master' )
end

function AudioManager:setMasterVolume( v )
	return self:setCategoryVolume( 'master', v )
end

function AudioManager:seekMasterVolume( v, delta, easeType )
	return self:seekCategoryVolume( 'master', v, delta, easeType )
end

function AudioManager:moveMasterVolume( dv, delta, easeType )
	return self:moveCategoryVolume( 'master', dv, delta, easeType )
end

function AudioManager:getCategoryVolume( category )
	_error( 'need implementation' )
end

function AudioManager:setCategoryVolume( category, volume )
	_error( 'need implementation' )
end

function AudioManager:seekCategoryVolume( category, v, delta, easeType )
	_error( 'need implementation' )
end

function AudioManager:moveCategoryVolume( category, dv, delta, easeType )
	_error( 'need implementation' )
end

function AudioManager:pauseCategory( category, paused )
	_error( 'need implementation' )
end

function AudioManager:isCategoryPaused( category )
	_error( 'need implementation' )
end

function AudioManager:muteCategory( category, muted )
	_error( 'need implementation' )
end

function AudioManager:isCategoryMuted( category )
	_error( 'need implementation' )
end
