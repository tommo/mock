--[[
* MOCK framework for Moai

* Copyright (C) 2012 Tommo Zhou(tommo.zhou@gmail.com).  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the
* "Software"), to deal in the Software without restriction, including
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to
* the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

--------------------------------------------------------------------
-- The game object.
-- It's the signleton for the main application control.
-- @classmod Game

module 'mock'

local gii = rawget( _G, 'gii' )
local collectgarbage = collectgarbage
local pairs,ipairs,setmetatable,unpack=pairs,ipairs,setmetatable,unpack

--------------------------------------------------------------------
----GAME MODULES
--------------------------------------------------------------------

require 'GameModule'
function loadAllGameModules( scriptLibrary )
	if scriptLibrary then
		local data = game:loadJSONData( scriptLibrary )
		if data then 
			for k,v in pairs( data ) do
				GameModule.addGameModuleMapping( k, v )
			end
		end
	end
	for k, node in pairs( getAssetLibrary() ) do
		if node:getType() == 'lua' then
			local modulePath = k:gsub( '/', '.' )
			modulePath = modulePath:sub( 1, #modulePath - 4 )
			GameModule.loadGameModule( modulePath )
		end
	end

	local errors = GameModule.getErrorInfo()
	if errors then
		print( 'Errors in loading game modules' )
		print( '------------------------------' )
		for i, info in ipairs( errors ) do
			if info.errtype == 'compile' then
				printf( 'error in compiling %s', info.fullpath )
			elseif info.errtype == 'load' then
				printf( 'error in loading %s', info.fullpath )
			end
			print( info.msg )
			print()
		end
		print( '------------------------------' )
		os.exit( -1 )
	end
	validateAllClasses()
end

--------------------------------------------------------------------
registerGlobalSignals{
	'msg',
	'app.start',
	'app.resume',
	'app.end',

	'game.init',
	'game.start',
	'game.pause',
	'game.resume',
	'game.stop',
	'game.update',

	'asset.init',

	'gfx.resize',
	'device.resize',

	'mainscene.open',
	'mainscene.refresh',
	'mainscene.close',

	'scene.init',
	'scene.update',
	'scene.clear',

	'layer.update',
	'layer.add',
	'layer.remove',

	'game_config.save',
	'game_config.load',
}


--------------------------------------------------------------------
CLASS: Game () 
	
--------------------------------------------------------------------
function Game:__init() --INITIALIZATION
	self.initialized          = false
	self.graphicsInitialized  = false
	self.currentRenderContext = 'game'    -- for editor integration

	self.version = ""
	self.editorMode = false
	self.scenes        = {}
	self.layers        = {}
	self.configObjects = {}
	self.gfx           = { w = 640, h = 480, viewportRect = {0,0,640,480} }
	self.time          = 0
	self.frame 				 = 0
	self.mainScene     = Scene()
	self.mainScene.main = true

	local l = self:addLayer( 'main' )
	l.default = true
	self.defaultLayer = l

	self.showCursorReasons = {}

end

local defaultGameConfig={
	title            = 'Hatrix Game',

	settingFileName  = '_settings',
	debugEnabled     = false,

	virtualDevice    = 'iphone',
	screenKeepAspect = true,

	globalFrameBuffer= false,
	forceResolution  = false
}

function Game:loadConfig( path, fromEditor )
	_stat( 'loading game config from :', path )
	local data = self:loadJSONData( path )
	if not data then
		_error( 'game configuration not parsed:', path )
		return
	end

	return self:init( data, fromEditor )
end

function Game:init( config, fromEditor )
	
	_stat( '...init game' )
	
	self.initialized = true
	self.editorMode  = fromEditor and true or false
	self.initOption  = config

	--META
	self.name    = config['name'] or 'GAME'
	self.version = config['version'] or '0.0.1'
	self.title   = config['title'] or self.name

	--Systems
	self:initGraphics   ( config, fromEditor )
	self:initDebugUI    ()
	self:applyPlaceHolderRenderTable()

	self:initSystem     ( config, fromEditor )
	self:initAsset      ( config, fromEditor )

	--postInit
	if not fromEditor then --initCommonData will get called after scanning asset modifications
		self:initCommonData( config, fromEditor )
	end
	

end


function Game:initSystem( config, fromEditor )
	_stat( '...init systems' )
	-------Setup Action Root
	_stat( '...setting up action root' )
	self.time     = 0
	self.throttle = 1
	self.isPaused = false

	local yield = coroutine.yield
	self.rootUpdateCoroutine=MOAICoroutine.new()
	self.rootUpdateCoroutine:run( function()
			while true do
				local dt = yield()
				self:onRootUpdate( dt ) --delta time get passed in
			end
		end
	)
	self.actionRoot = MOAISim.getActionMgr():getRoot()
	self:setThrottle( 1 )

	-------Setup Callbacks
	_stat( '...setting up session callbacks' )
	if rawget( _G, 'MOAIApp' ) then
		MOAIApp.setListener(
			MOAIApp.SESSION_END, 
			function() return emitSignal('app.end') end 
			)
		MOAIApp.setListener(
			MOAIApp.SESSION_START,
			function(resume) return emitSignal( resume and 'app.resume' or 'app.start' ) end 
			)
	end

	MOAIGfxDevice.setListener (
		MOAIGfxDevice.EVENT_RESIZE,
		function( width, height )	return self:onResize( width, height )	end
		)

	----extra
	_stat( '...extra init' )

	if fromEditor then
		collectgarbage( 'setpause',   70  )
		collectgarbage( 'setstepmul', 150 )	
	else
		collectgarbage( 'setpause',   70  )
		collectgarbage( 'setstepmul', 150 )	
	end

	MOAISim.setStep( 1/60 )
	MOAISim.clearLoopFlags()
	MOAISim.setLoopFlags( 
			0
			+ MOAISim.LOOP_FLAGS_MULTISTEP
			+ MOAISim.LOOP_FLAGS_DEFAULT
			-- + MOAISim.LOOP_FLAGS_SOAK
			-- + MOAISim.SIM_LOOP_ALLOW_BOOST
			-- + MOAISim.SIM_LOOP_ALLOW_SOAK
			+ MOAISim.SIM_LOOP_NO_DEFICIT
			+ MOAISim.SIM_LOOP_NO_SURPLUS
		)
	MOAISim.setLongDelayThreshold( 100 )
	-- MOAISim.setBoostThreshold( 0 )	
	-- MOAISim.setStepMultiplier( 2 )	
end

function Game:initSubSystems( config, fromEditor )
	--make inputs work
	_stat( 'init input handlers' )
	initDefaultInputEventHandlers()

	--audio
	_stat( 'init audio' )
	AudioManager.get():init()

	--physics
	--config for default physics world
	self.physicsOption = table.simplecopy( DefaultPhysicsWorldOption )
	if config['physics'] then
		table.extend( self.physicsOption, config['physics'] )
	end

	--
	self.globalManagers = getGlobalManagerRegistry()
	for i, manager in ipairs( self.globalManagers ) do
		manager:onInit( self )
	end

	local managerConfigs = config[ 'global_managers' ] or {}
	for i, manager in ipairs( self.globalManagers ) do
		local key = manager:getKey()
		local managerConfig = managerConfigs[ key ] or {}
		manager:loadConfig( managerConfig )
	end

end

function Game:initLayers( config, fromEditor )
	--load layers
	_stat( '...setting up layers' )
	for i, data  in ipairs( config['layers'] or {} ) do
		local layer 

		if data['default'] then
			layer = self.defaultLayer
			layer.name = data['name']
		else
			layer = self:addLayer( data['name'] )
		end
		layer:setSortMode( data['sort'] )
		layer:setVisible( data['visible'] ~= false )
		layer:setEditorVisible( data['editor_visible'] ~= false )
		layer.parallax = data['parallax'] or {1,1}
		layer.priority = i
		layer:setLocked( data['locked'] )
	end

	table.sort( self.layers, 
		function( a, b )
			local pa = a.priority or 0
			local pb = b.priority or 0
			return pa < pb
		end )
	
	if fromEditor then
		local layer = self:addLayer( '_GII_EDITOR_LAYER' )
		layer.priority = 1000000
	end
end

function Game:initAsset( config, fromEditor )
	
	self.assetLibraryIndex   = config['asset_library']
	self.textureLibraryIndex = config['texture_library']

	--misc
	setTextureThreadTaskGroupSize( 2 )

	--assetlibrary
	_stat( '...loading asset library' )
	loadAssetLibrary( self.assetLibraryIndex )
	loadTextureLibrary( self.textureLibraryIndex )
	
	--scriptlibrary
	_stat( '...loading game modules' )
	loadAllGameModules( config['script_library'] or false )

	emitSignal( 'asset.init' )

end

function Game:initCommonDataFromEditor()
	return self:initCommonData( self.initOption, true )
end

function Game:initCommonData( config, fromEditor )
	--init asset
	self:initSubSystems ( config, fromEditor )
	
	--init layers
	self:initLayers     ( config, fromEditor )

	--load setting data
	_stat( '...loading setting data' )
	self.settingFileName = config['setting_file'] or 'setting'
	self.userDataPath    = MOAIEnvironment.documentDirectory or '.'
	local settingData = self:loadSettingData( self.settingFileName )
	self.settingData  = settingData or {}

	--init global objects
	_stat( '...loading global game objects' )
	self.globalObjectLibrary = getGlobalObjectLibrary()
	self.globalObjectLibrary:load( config['global_objects'] )

	--load palette
	_stat( '...loading palette' )
	self.paletteLibrary = getPaletteLibrary()
	self.paletteLibrary:load( config['palettes'] )

	--ask other systems to initialize
	emitSignal( 'game.init', config )

	--load scenes
	if config['scenes'] then
		for alias, scnPath in pairs( config['scenes'] ) do
			self.scenes[ alias ] = scnPath
		end
	end

	self.entryScene = config['entry_scene']
	self.firstOpenedScene = false

	self.mainScene:init()
	_stat( '...init game done!' )

end


--------------------------------------------------------------------
function Game:saveConfigToTable()
	--save layer configs
	local layerConfigs = {}
	for i,l in pairs( self.layers ) do
		if l.name ~= '_GII_EDITOR_LAYER'  then
			layerConfigs[i] = {
				name     = l.name,
				sort     = l.sortMode,
				visible  = l.visible,
				default  = l.default,
				locked   = l.locked,
				parallax = l.parallax,
				editor_visible  = l.editorVisible,
			}
		end
	end

	--save global manager configs
	local globalManagerConfigs = {}
	for i, manager in ipairs( getGlobalManagerRegistry() ) do
		local key = manager:getKey()
		local data = manager:saveConfig()
		if data then
			globalManagerConfigs[ key ] = data
		end
	end

	local data = {
		name           = self.name,
		version        = self.version,
		title          = self.title,
		
		asset_library  = self.assetLibraryIndex,
		texture_library = self.textureLibraryIndex,

		graphics       = self.graphicsOption,
		physics        = self.physicsOption,
		layers         = layerConfigs,
		
		scenes         = self.scenes,
		entry_scene    = self.entryScene,

		palettes        = self.paletteLibrary:save(),
		global_managers = globalManagerConfigs,
		global_objects  = self.globalObjectLibrary:save(),
	}
	emitSignal( 'game_config.save', data )
	return data
end

function Game:saveConfigToString()
	local data = self:saveConfigToTable()
	return encodeJSON( data )
end

function Game:saveConfigToFile( path )
	local data = self:saveConfigToTable()
	return self:saveJSONData( data, path, 'game config' )
end

function Game:saveJSONData( data, path, dataInfo )
	dataInfo = dataInfo or 'json'
	local output = encodeJSON( data )
	local file = io.open( path, 'w' )
	if file then
		file:write(output)
		file:close()
		_stat( dataInfo, 'saved to', path )
	else
		_error( 'can not save ', dataInfo , 'to' , path )
	end
end

function Game:loadJSONData( path, dataInfo )
	local file = io.open( path, 'rb' )
	if file then
		local str = file:read('*a')
		-- local str = MOAIDataBuffer.inflate( str )
		local data = MOAIJsonParser.decode( str )
		if data then
			_stat( dataInfo, 'loaded from', path )
			return data
		end
		_error( 'invalid json data for ', dataInfo , 'at' , path )
	else
		_error( 'file not found for ', dataInfo , 'at' , path )
	end
end

--------------------------------------------------------------------
--------Graphics related
--------------------------------------------------------------------
function Game:initGraphics( option, fromEditor )
	self.graphicsOption = option['graphics'] or {}
	
	local gfxOption = self.graphicsOption
	self.deviceRenderTarget = DeviceRenderTarget( MOAIGfxDevice.getFrameBuffer(), 1, 1 )
	
	self.mainRenderTarget   = RenderTarget()
	self.mainRenderTarget:setFrameBuffer( self.deviceRenderTarget:getFrameBuffer() )
	self.mainRenderTarget:setParent( self.deviceRenderTarget )
	self.mainRenderTarget:setMode( 'relative' )

	--TODO
	local w, h = getDeviceResolution()
	if w * h == 0 then
		w, h  = gfxOption['device_width'] or 800, gfxOption['device_height'] or 600
	end
	self.targetDeviceWidth  = w
	self.targetDeviceHeight = h
	
	self.deviceRenderTarget:setPixelSize( w, h )

	self.width   = gfxOption['width']  or w
	self.height  = gfxOption['height'] or h
	self.fullscreen = gfxOption['fullscreen'] or false	

	self.viewportMode = gfxOption['viewport_mode'] or 'fit'

	self.mainRenderTarget:setAspectRatio( self.width/self.height )
	self.mainRenderTarget:setKeepAspect( true )
	self.mainRenderTarget:setFixedScale( self.width, self.height )

	_stat( 'opening window', self.title, w, h )
	if not fromEditor then
		--FIXME: crash here if no canvas shown up yet
		MOAISim.openWindow( self.title, w, h  )
	end

	self.graphicsInitialized = true
	if self.pendingResize then
		self.pendingResize = nil
		self:onResize( unpack( pendingResize ) )
	end

	self:showCursor()

	-- MOAIGfxResourceMgr.setResourceLoadingPolicy( 
	-- 	MOAIGfxResourceMgr.LOADING_POLICY_CPU_GPU_ASAP
	-- )
end

function Game:initDebugUI()
	local debugUIManager = getDebugUIManager()
	debugUIManager:init()
	debugUIManager:setEnabled( false )
end

function Game:setDebugUIEnabled( enabled )
	getDebugUIManager():setEnabled( enabled )
end

function Game:isDebugUIEnabled()
	return getDebugUIManager():isEnabled()
end

function Game:setDeviceSize( w, h )
	_stat( 'device.resize', w, h )
	self.deviceRenderTarget:setPixelSize( w, h )
	emitSignal( 'device.resize', self.width, self.height )
end

function Game:getDeviceResolution( )
	return self.deviceRenderTarget:getPixelSize()
end

function Game:getTargetDeviceResolution()
	return self.targetDeviceWidth, self.targetDeviceHeight
end

--- Get the scale( conent size ) of the main viewport
-- @ret float,float width, height
function Game:getViewportScale()
	return self.width, self.height
end

function Game:getViewportRect()
	return self.mainRenderTarget:getAbsPixelRect()
end

function Game:getDeviceRenderTarget()
	return self.deviceRenderTarget
end

function Game:getMainRenderTarget()
	return self.mainRenderTarget
end

function Game:onResize( w, h )
	if not self.graphicsInitialized then
		self.pendingResize = { w, h }
		return
	end	
	self:setDeviceSize( w, h )
end

--------------------------------------------------------------------
------Scene control
--------------------------------------------------------------------
function Game:openEntryScene()
	if self.entryScene then
		self:openSceneByPath( self.entryScene )
		self:start()
	end
end

function Game:openScene( id, additive, arguments, autostart )
	local scnPath = self.scenes[ id ]
	if not scnPath then
		return _error( 'scene not defined', id )
	end
	return self:openSceneByPath( scnPath, additive, arguments, autostart )
end

function Game:scheduleOpenScene( id, additive, arguments, autostart )
	local scnPath = self.scenes[ id ]
	if not scnPath then
		return _error( 'scene not defined', id )
	end
	return self:scheduleOpenSceneByPath( scnPath, additive, arguments, autostart ) 
end

function Game:openSceneByPath( scnPath, additive, arguments, autostart )
	_stat( 'openning scene:', scnPath )
	if not self.firstOpenedScene then
		self.firstOpenedScene = scnPath
	end
	local mainScene = self.mainScene
	autostart = autostart ~= false
	
	if not additive then
		mainScene:stop()
		mainScene:clear( true )
		collectAssetGarbage()
		mainScene:reset()
	end

	--load arguments first
	local args = mainScene.arguments or {}
	if not additive then args = {} end
	if arguments then
		for k,v in pairs( arguments ) do
			args[ k ] = v
		end
	end
	mainScene.assetPath = scnPath
	
	--todo: previous scene
	mainScene.arguments = args and table.simplecopy( args ) or {}

	--load entities
	local runningState = mainScene.running
	mainScene.running = false --start entity in batch
	local scn, node = loadAsset( scnPath, { scene = mainScene } )
	if not node then 
		return _error('scene not found', id, scnPath )
	end
	if node.type ~= 'scene' then
		return _error('invalid type of entry scene:', tostring( node.type ), scnPath )
	end
	mainScene.running = runningState
	emitSignal( 'mainscene.open', scn, arguments )
	
	mainScene:notifyLoad( scnPath )

	if autostart then
		scn:start()
	end
	return scn
end

function Game:scheduleOpenSceneByPath( scnPath, additive, arguments, autostart )
	autostart = true
	self.pendingLoading = { scnPath, additive, arguments, autostart }
end

function Game:onSceneExit( scn )
	assert( scn == self.mainScene )
	local pendingScene = self.pendingScene
	self.mainScene = false
	emitSignal( 'mainscene.close', scn )
	if pendingScene then
		self.pendingScene = false
		return self:openSceneByPath( pendingScene )
	end
end

function Game:getMainScene()
	return self.mainScene
end

function Game:reopenMainScene()
	if not self.mainScene then return false end
	local assetPath = self.mainScene.assetPath
	if assetPath then
		return self:openSceneByPath( assetPath )
	else
		return false
	end
end

function Game:scheduleReopenMainScene()
	if not self.mainScene then return false end
	local assetPath = self.mainScene.assetPath
	if assetPath then
		return self:scheduleOpenSceneByPath( assetPath )
	else
		return false
	end
end

--------------------------------------------------------------------
------Layer Control
--------------------------------------------------------------------
function Game:addLayer( name, addPos )
	addPos = addPos or 'last'
	local l = Layer( name )
	
	if addPos == 'last' then
		local s = #self.layers
		local last = s > 0 and self.layers[ s ]
		if last and last.name == '_GII_EDITOR_LAYER' then
			table.insert( self.layers, s, l )
		else
			table.insert( self.layers, l )
		end
	else
		table.insert( self.layers, 1, l )
	end
	return l
end

function Game:removeLayer( layer )
	local i = table.index( self.layers, layer )
	if not i then return end
	table.remove( self.layers, i )
end

function Game:getLayer( name )
	for i, l in ipairs( self.layers ) do
		if l.name == name then return l end
	end
	return nil
end

function Game:getLayers()
	return self.layers
end

--------------------------------------------------------------------
------Action related
--------------------------------------------------------------------
function Game:getTime()
	return self.time
end

function Game:getFrame()
	return self.frame
end

function Game:newSubClock()
	return newClock(function()
		return self.time
	end)
end

function Game:onRootUpdate( delta )
	self.time = self.time + delta
	self.frame = self.frame + 1
	emitSignal( 'game.update', delta )
	for i, manager in ipairs( self.globalManagers ) do
		manager:onUpdate( self, delta )
	end
	if self.pendingLoading then
		local loadingParams = self.pendingLoading
		self.pendingLoading = false
		self:openSceneByPath( unpack( loadingParams ) )
	end
end

function Game:resetClock()
	self.time = 0
end

function Game:setStep(step,stepMul)
	if step then MOAISim.setStep(step) end
	if stepMul then MOAISim.setStepMultiplier(stepMul) end
end

function Game:pause()
	if self.paused then return end 
	self.paused = true
	self.actionRoot:pause()
	self.mainScene:pause()
	emitSignal( 'game.pause', self )
end

function Game:stop()
	_stat( 'game stop' )
	self.mainScene:stop()
	self.mainScene:clear( true )
	self:resetClock()
	emitSignal( 'game.stop', self )
	_stat( 'game stopped' )
end

function Game:start()

	_stat( 'game start' )
	self.paused = false
	self.mainScene:start()
	if self.paused then
		emitSignal( 'game.resume', self )
	else
		emitSignal( 'game.start', self )
	end
	_stat( 'game started' )
end

function Game:isPaused()
	return self.paused
end

function Game:getActionRoot()
	return self.actionRoot
end

function Game:setThrottle(v)
	self.throttle = v
	return self.actionRoot:throttle( v * 1 )
end




--------------------------------------------------------------------
---------Global object( config? )
--------------------------------------------------------------------

function Game:getGlobalObjectLibrary()
	return self.globalObjectLibrary
end

function Game:getGlobalObject( path )
	return self.globalObjectLibrary:get( path )
end

--------------------------------------------------------------------
---------Palette
--------------------------------------------------------------------
function Game:getPaletteLibrary()
	return self.paletteLibrary
end

function Game:findPalette( id )
	return self.paletteLibrary:findPalette( id )
end

function Game:findColor( paletteId, itemId )
	local pal = self:findPalette( paletteId )
	if not pal then return nil end
	return pal:getColor( itemId )
end

--------------------------------------------------------------------
---------Data settings
--------------------------------------------------------------------
function Game:updateSetting( key, data, persistLater )
	self.settingData[key]=data
	if not persistLater then
		self:saveSettingData( self.settingData, self.settingFileName )
	end
end

function Game:getSetting(key)
	return self.settingData[key]
end

function Game:getUserDataPath( path )
	if not path then return self.userDataPath end
	return self.userDataPath .. '/' ..path
end

function Game:checkSettingFileExists( path )
	local fullPath = self:getUserDataPath( path )
	return MOAIFileSystem.checkFileExists( fullPath )
end

function Game:saveSettingData( data, filename )
	local str  = encodeJSON( data )
	local raw  = MOAIDataBuffer.deflate( str, 0 )
	local file = io.open( self.userDataPath..'/'..filename, 'wb' )
	file:write( raw )
	file:close()
	--todo: exceptions?
	return true
end

function Game:loadSettingData( filename )
	_stat( '...reading setting data from:', filename )
	local file = io.open( self.userDataPath..'/'..filename, 'rb' )
	if file then
		local raw = file:read('*a')
		local str = MOAIDataBuffer.inflate( raw )
		return MOAIJsonParser.decode( str )
	else
		return nil
	end
end

local function _getHash( raw, key )
	local hashWriter = MOAIHashWriter.new()
	hashWriter:openWhirlpool()
	hashWriter:write( raw )
	if key then hashWriter:write( key ) end
	hashWriter:close()
	local hash = hashWriter:getHash()
	return hash
end

function Game:saveSafeSettingData( data, filename, key )
	local str  = encodeJSON( data )
	local raw  = MOAIDataBuffer.deflate( str )
	local file = io.open( self.userDataPath..'/'..filename, 'wb' )
	file:write( _getHash( raw, key ) )
	file:write( raw )
	file:close()
	return true
end

function Game:loadSafeSettingData( filename, key )
	_stat( '...reading setting data from:', filename )
	local stream = MOAIFileStream.new()
	local path = self.userDataPath..'/'..filename
	if stream:open( path, MOAIFileStream.READ ) then
		local hash = stream:read( 64 )
		local raw  = stream:read()
		local str  = MOAIDataBuffer.inflate( raw )
		stream:close()
		if not str then
			_warn( 'cannot extract data', path )
			return nil
		end
		local hash1 = _getHash( raw, key )
		local match = hash == hash1
		local data = MOAIJsonParser.decode( str )
		return data, match
	else
		_warn( 'no file to open', path )
		return nil
	end
end 
-------------------------

function Game:setDebugEnabled( enabled )
	--todo
end

function Game:setClearDepth( clear )
	return MOAIGfxDevice.getFrameBuffer():setClearDepth(clear)
end

function Game:setClearColor( r,g,b,a )
	self.clearColor = r and {r,g,b,a}	 or false
	if gii then
		local renderContext = gii.getRenderContext( 'game' )
		renderContext.clearColor = self.clearColor
	end
	return MOAIGfxDevice.getFrameBuffer():setClearColor( r,g,b,a )
end

--------------------------------------------------------------------
--Context Related
--------------------------------------------------------------------
function Game:setRenderStack( context, deviceRenderTable, bufferTable, renderTableMap )
	if gii then
		local renderContext = gii.getRenderContext( context )
		assert( renderContext, 'render context not found:' .. context )
		-- local renderTableMap1 = {}
		-- for fb, rt in pairs( renderTableMap ) do --copy
		-- 	renderTableMap1[ fb ] = rt
		-- end
		renderContext.renderTableMap    = renderTableMap
		renderContext.bufferTable       = bufferTable
		renderContext.deviceRenderTable = deviceRenderTable
	elseif context ~= 'game' then
		_error( 'no gii module found for render context functions')
	end

	if context == self.currentRenderContext then
		if bufferTable then
			if #bufferTable > 0 then 
				emptyRenderStack = false
				local finalTable = table.simplecopy( bufferTable )
				if context == 'game' then
					table.insert( finalTable, getDebugUIManager():getRenderCommand() )
				end
				MOAIRenderMgr.setBufferTable( finalTable )
			end
		end
	end
end


function Game:applyPlaceHolderRenderTable()
	local t = self.placeHolderRenderTable
	if not t then
		local renderLayer = MOAILayer.new()
		local placeHolderRect = MOAIGraphicsProp.new()
		local deck = MOAIScriptDeck.new()
		deck:setDrawCallback( function()
			MOAIGfxDevice.setPenColor( .1,1,.1,1 )
			MOAIDraw.fillRect( -10000,-10000,10000,10000)
		end)
		deck:setRect( -10000,-10000,10000,10000 )
		placeHolderRect:setDeck( deck )
		renderLayer:insertProp( placeHolderRect )
		local frameRenderCommand = MOAIFrameBufferRenderCommand.new()
		frameRenderCommand:setClearColor( .1,1,.1,1 )
		frameRenderCommand:setFrameBuffer( MOAIGfxDevice.getFrameBuffer() )
		frameRenderCommand:setRenderTable( { renderLayer } )--, getDebugUIManager():getRenderCommand() } )
		t = self.placeHolderRenderTable
	end
	MOAIRenderMgr.setBufferTable( t )
end

function Game:setCurrentRenderContext( key )
	self.currentRenderContext = key or 'game'
end

function Game:getCurrentRenderContext()
	return self.currentRenderContext or 'game'
end

function Game:isEditorMode()
	return self.editorMode
end

function Game:collectgarbage( ... )
	collectgarbage( ... )
end

function Game:isFullscreenMode()
	return self.fullscreen
end

function Game:enterFullscreenMode()
	if self.fullscreen then return end
	MOAISim.enterFullscreenMode()
	self.fullscreen = true
end

function Game:exitFullscreenMode()
	if not self.fullscreen then return end
	MOAISim.exitFullscreenMode()
	self.fullscreen = false
end

function Game:hideCursor( reason )
	reason = reason or 'default'
	self.showCursorReasons[ reason ] = nil
	if not next( self.showCursorReasons ) then
		MOAISim.hideCursor()
	end
end

function Game:showCursor( reason )
	reason = reason or 'default'
	self.showCursorReasons[ reason ] = true
	MOAISim.showCursor()
end

game = Game()

