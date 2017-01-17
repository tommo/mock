module 'mock'

if not MOAIFmodEventMgr then return end

--------------------------------------------------------------------
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

	MOAIFmodEventMgr.setNear2DBlend( 100, 300, 1 )
	if not MOAIFmodEventMgrReady then
		--TODO:LOG alert?
		_error('Fmod not initialized...')
		return false
	else
		_stat('Fmod ready...')
		return true
	end

end



local event2IDCache = table.weak_k()

local function _affirmFmodEvent( event )
	if not event then return nil end
	local id = event2IDCache[ event ]
	if id ~= nil then return id end
	if type( event ) == 'string' then
		event, node = loadAsset( event ) 
		if event then
			id = event:getSystemID()
		else
			return nil
		end
	else
		id = event:getSystemID()
	end
	event2IDCache[ event ] = id or false
	return id
end


--------------------------------------------------------------------
CLASS: FMODDeisgnerAudioManager ( AudioManager )
	:MODEL{}

function FMODDeisgnerAudioManager:init( option )
	local succ = initFmodDesigner()
	return succ
end

function FMODDeisgnerAudioManager:getListener( id )
	return MOAIFmodEventMgr.getMicrophone()
end

function FMODDeisgnerAudioManager:playEvent3D( eventPath, x, y, z )
	local eventId = _affirmFmodEvent( eventPath )
	return MOAIFmodEventMgr.playEvent3D( eventId, x,y,z )
end

function FMODDeisgnerAudioManager:playEvent2D( eventPath, looped )
	local eventId = _affirmFmodEvent( eventPath )
	return MOAIFmodEventMgr.playEvent2D( eventId, looped )
end

function FMODDeisgnerAudioManager:getCategoryVolume( category )
	return MOAIFmodEventMgr.getSoundCategoryVolume( category )
end

function FMODDeisgnerAudioManager:setCategoryVolume( category, volume )
	return MOAIFmodEventMgr.setSoundCategoryVolume( category, volume or 1 )
end

function FMODDeisgnerAudioManager:seekCategoryVolume( category, v, delta, easeType )
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

function FMODDeisgnerAudioManager:moveCategoryVolume( category, dv, delta, easeType )
	category = category or 'master'
	
	local v0 = self:getCategoryVolume( category )
	if not v0 then return nil end
	return self:seekCategoryVolume( category, v0 + dv, delta, easeType )
end

function FMODDeisgnerAudioManager:pauseCategory( category, paused )
	MOAIFmodEventMgr.pauseSoundCategory( category, paused ~= false )
end

function FMODDeisgnerAudioManager:muteCategory( category, muted )
	MOAIFmodEventMgr.muteSoundCategory( category, muted ~= false )
end

function FMODDeisgnerAudioManager:isCategoryMuted( category )
	return MOAIFmodEventMgr.isSoundCategoryMuted( category )
end

function FMODDeisgnerAudioManager:isCategoryPaused( category )
	return MOAIFmodEventMgr.isSoundCategoryPaused( category )
end

--------------------------------------------------------------------
_stat( 'using FMOD Designer audio manager' )
FMODDeisgnerAudioManager()

