module 'mock'

--[[
	FMOD Designer Only
]]

local function initFmodDesigner()
	if not MOAIFmodEventMgr then return end
	--TODO: accept config from startup script
	local MOAIFmodEventMgrReady = MOAIFmodEventMgr.init{
			["soundMemoryMB"]              =  16 ;
			["rsxMemoryMB"]                =  0 ;
			["voiceLRUBufferMB"]           =  0 ;
			["voiceLRUMaxMB"]              =  0 ;
			["nVirtualChannels"]           =  256 ;
			["nRealChannels"]              =  32 ;
			["nPCMCodecs"]                 =  16 ;
			["nADPCMCodecs"]               =  32 ;
			["nCompressedCodecs"]          =  32 ;
			["nMaxInputChannels"]          =  6 ;
			["enableSoundSystem"]          =  true ;
			["enableDistantLowpass"]       =  true ;
			["enableEnvironmentalReverb"]  =  true ;
			["enableNear2DBlend"]          =  true ;
			["enableAuditioning"]          =  false ;
			["enableProfiling"]            =  false ;
			["enableFsCallbacks"]          =  false ;
			["disableSound"]               =  false ;
			["dopplerScale"]               =  0 ;
		}

	if not MOAIFmodEventMgrReady then
		--TODO:LOG alert?
		_error('Fmod not initialized...')
	else
		_stat('Fmod ready...')
	end

end


CLASS: AudioManager ()
	:MODEL{}

local _singleton = false
function AudioManager.get()
	return _singleton
end

function AudioManager:__init()
	assert( not _singleton )
	_singleton = self	
end

function AudioManager:init()
	initFmodDesigner()
end

function AudioManager:getMasterVolume()
	return self:getCategoryVolume( 'master' )
end

function AudioManager:setMasterVolume( v )
	return self:setCategoryVolume( 'master', v )
end

function AudioManager:getCategoryVolume( category )
	return MOAIFmodEventMgr.getSoundCategoryVolume( category )
end

function AudioManager:setCategoryVolume( category, volume )
	return MOAIFmodEventMgr.setSoundCategoryVolume( category, volume or 1 )
end


function AudioManager:seekCategoryVolume( category, v, delta, easeType )
	category = category or 'master'
	delta = delta or 0
	if delta <=0 then return self:setCategoryVolume( category, v ) end

	local v0 = self:getCategoryVolume( category )
	if not v0 then return nil end

	v = clamp( v, 0, 1 )

	easeType = easeType or MOAIEaseType.EASE_OUT

	local tmpNode = MOAIScriptNode.new()
	tmpNode:reserveAttrs( 1 )
	tmpNode:setCallback( function( node )
		local value = node:getAttr( 0 )
		MOAIFmodEventMgr.setSoundCategoryVolume( category, value )
	end )
	tmpNode:setAttr( 0, v0 )
	return tmpNode:seekAttr( 0, v, delta, easeType )
end

function AudioManager:moveCategoryVolume( category, dv, delta, easeType )
	category = category or 'master'
	
	local v0 = self:getCategoryVolume( category )
	if not v0 then return nil end
	return self:seekCategoryVolume( category, v0 + dv, delta, easeType )
end

function AudioManager:seekMasterVolume( v, delta, easeType )
	return self:seekCategoryVolume( 'master', v, delta, easeType )
end

function AudioManager:moveMasterVolume( dv, delta, easeType )
	return self:moveCategoryVolume( 'master', dv, delta, easeType )
end

--------------------------------------------------------------------
AudioManager()
