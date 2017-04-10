module 'mock'

---------------------------------------------------------------------
CLASS: TBManager ( GlobalManager )
	:MODEL{}

function TBManager:getKey()
	return 'TBManager'
end

function TBManager:__init()
end

function TBManager:onInit()
	-- MOAITBMgr.init()
	-- --TEST UI Data
	
	-- MOAITBMgr.loadSkin( 'resources/default_skin/skin.tb.txt', false, false )
	-- MOAITBMgr.loadSkin( 'skin/skin.tb.txt', true, true )

	-- local font = mock.loadAsset( 'font/zipex.fnt' )
	-- MOAITBMgr.registerFont( 'zipex', font )
	-- MOAITBMgr.setDefaultFontFace( 'zipex', 13 )
	
end


--------------------------------------------------------------------
local _tbManager = TBManager()
function getTBManager()
	return _tbManager
end
