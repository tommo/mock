module 'mock'

local _defaultUISkin = false
function getDefaultUISkin()
	if not _defaultUISkin then
		_defaultUISkin = UISkin()
	end
	return _defaultUISkin
end

--------------------------------------------------------------------
CLASS: UISkin ()

function UISkin:__init()
	self.instances = table.weak_k()
	self.resources = {}
	self.styleSheets = {}
	self.styleSheetCache = UIStyleSheetCache()
	self.basePath = false
end

function UISkin:load( data )
	local basePath = self.basePath
	local cache = self.styleSheetCache
	for i, styleSheetName in ipairs( data[ 'style_sheet' ] ) do
		local path = basePath and ( basePath .. styleSheetName ) or styleSheetName
		local sheet = loadUIStyleSheet( path )
		if sheet then
			cache:addSheet( sheet )
		else
			_warn( 'style sheet not found', path )
		end
	end
	cache:update()
end

function UISkin:getStyleSheetCache()
	return self.styleSheetCache
end

function UISkin:createInstance()
	local instance = UISkinInstance( self )
	self.instances[ instance ] = true
	return instance
end

--------------------------------------------------------------------
CLASS: UISkinInstance ()
	:MODEL{}

function UISkinInstance:__init( skin )
	self.skin = skin
end


--------------------------------------------------------------------
local function SkinLoader()
	
end

registerAssetLoader( 'ui_skin', SkinLoader )