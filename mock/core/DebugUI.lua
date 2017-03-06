module 'mock'

--------------------------------------------------------------------
CLASS: DebugUIManager ( GlobalManager )
	:MODEL{}

function DebugUIManager:__init()
	self.imgui = ImGuiLayer()
	self.imgui:setCallback( function( gui )
		return self:onGUI( gui )
	end
	)
	self.uiModules = {}
	self.enabled = true
end

function DebugUIManager:getRenderCommand()
	return self.imgui:getRenderCommand()
end

function DebugUIManager:init()
	connectGlobalSignalMethod( 'device.resize', self, 'onDeviceResize' )
	self.imgui:init( 'DebugUI' )
	self.imgui:setViewport( game:getMainRenderTarget():getMoaiViewport() )
	self:onDeviceResize( game:getDeviceResolution() )
end

function DebugUIManager:getKey()
	return 'DebugUIManager'
end

function DebugUIManager:hasModule( key )
	return self.uiModules[ key ] and true or false
end

function DebugUIManager:registerModule( key, uiModule )
	self.uiModules[ key ] = uiModule
end

function DebugUIManager:removeModule( key, uiModule )
	self.uiModules[ key ] = nil
end

function DebugUIManager:onDeviceResize( w, h )
	self.imgui:setSize( w, h )
end

function DebugUIManager:onGUI( gui )
	if not self.enabled then return end
	local scn = game:getMainScene()
	for key, uiModule in pairs( self.uiModules ) do
		uiModule:_onDebugGUI( gui, scn )
	end
end

function DebugUIManager:setEnabled( enabled )
	self.enabled = enabled
	-- self.imgui:setVisible( enabled )
	setInputListenerCategoryActive( 'DebugUI', enabled )
	if enabled then
		game:showCursor( 'DebugUI' )
	else
		game:hideCursor( 'DebugUI' )
	end
	if enabled then
		for key, uiModule in pairs( self.uiModules ) do
			uiModule:onEnabled()
		end
	else
		for key, uiModule in pairs( self.uiModules ) do
			uiModule:onDisabled()
		end
	end
end

function DebugUIManager:isEnabled()
	return self.enabled
end


---------------------------------------------------------------------
CLASS: DebugUIModule ()

function DebugUIModule:__init()
	self.name = ""
end

function DebugUIModule:register( key )
	getDebugUIManager():registerModule( key, self )
end

function DebugUIModule:_onDebugGUI( gui, scn )
	self:onDebugGUI( gui, scn )
end

function DebugUIModule:onDebugGUI( gui, scn )
end

function DebugUIModule:onEnabled()
end

function DebugUIModule:onDisabled()
end

--------------------------------------------------------------------
CLASS: DebugUIListenerModule ()
	:MODEL{}

function DebugUIListenerModule:__init( owner )
	self.owner = owner
	self.callback = owner.onDebugGUI or false
end

function DebugUIListenerModule:onDebugGUI( gui, scn )
	if not self.callback then return end
	self.callback( self.owner, gui, scn )
end

--------------------------------------------------------------------
local _debugUIManager = DebugUIManager()
function getDebugUIManager()
	return _debugUIManager
end

function addDebugUIModule( key, module )
	_debugUIManager:registerModule( key, module )
end

function setDebugUIEnabled( enabled )
	_debugUIManager:setEnabled( enabled )
end

--------------------------------------------------------------------
function installDebugUIListener( owner )
	uninstallDebugUIListener( owner )
	if type( owner.onDebugGUI ) ~= 'function' then return end
	local m = DebugUIListenerModule( owner )
	owner.__debugUIModule = m
	_debugUIManager:registerModule( owner, m )
	return m
end

function uninstallDebugUIListener( owner )
	if owner.__debugUIModule then
		_debugUIManager:removeModule( owner, owner.__debugUIModule )
		owner.__debugUIModule = nil
	end
end
