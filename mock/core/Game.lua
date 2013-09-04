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

module 'mock'


local pairs,ipairs,setmetatable,unpack=pairs,ipairs,setmetatable,unpack


registerSignals{
	'msg',
	'app.start',
	'app.resume',
	'app.end',

	'game.init',
	'game.update',
	'gfx.resize',
	'device.resize',

	'scene.update',
	'scene.enter',
	'scene.exit',

	'layer.update',
	'layer.add',
	'layer.remove',

}


--------------------------------------------------------------------
CLASS: Game () 
	
--------------------------------------------------------------------
--- INITIALIZATION
--------------------------------------------------------------------

function Game:__init()
	self.initialized          = false
	self.graphicsInitialized  = false
	self.currentRenderContext = 'game'    -- for editor integration

	self.version = ""

	self.scenes        = {}
	self.layers        = {}
	self.gfx           = { w = 640, h = 480, viewportRect = {0,0,640,480} }
	self.time          = 0

	local l = self:addLayer( 'main' )
	l.default = true
	self.defaultLayer = l
end

local defaultGameOption={
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
	assert ( path, 'no config path!' )
	local file = io.open( path, 'r' )
	if not file then 
		_error( 'game configuration not found:', path )
		return 
	end

	local text = file:read('*a')
	file:close()
	local data = MOAIJsonParser.decode( text )
	if not data then
		_error( 'game configuration not parsed:', path )
		return
	end

	return self:init( data, fromEditor )
end


function Game:init( option, fromEditor )
	self.initialized = true
	loadAssetLibrary( option['asset_library'])
	self.assetLibraryIndex = option['asset_library']
	self.name    = option['name'] or 'GAME'
	self.version = option['version'] or '0.0.1'
	self.title   = option['title'] or self.name

	--grahpics profile( only for desktop version? )
	self.graphicsOption = option['graphics']
	self:initGraphics( fromEditor )

	--load layers
	for i, data  in ipairs( option['layers'] or {} ) do
		local layer 

		if data['default'] then
			layer = self.defaultLayer
			layer.name = data['name']
		else
			layer = self:addLayer( data['name'] )
		end
		layer:setSortMode( data['sort'] )
		layer:setVisible( data['visible'] ~= false )
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

	--load setting data
	self.settingFileName = option['setting_file'] or 'setting'
	self.userDataPath    = MOAIEnvironment.documentDirectory or '.'
	local settingData = self:loadSettingData( self.settingFileName )
	self.settingData  = settingData or {}

	-------Setup Action Root
	self.time     = 0
	self.throttle = 1
	self.isPaused = false

	local actionRoot=MOAICoroutine.new()
	actionRoot:run( function()
			while true do
				self:onRootUpdate( coroutine.yield() ) --delta time get passed in
			end
		end
	)
	MOAIActionMgr.setRoot( actionRoot )
	-- MOAISim.setLoopFlags( 
	-- 		MOAISim.LOOP_FLAGS_FIXED
	-- 	)
	-- MOAISim.setLoopFlags( 
	-- 		MOAISim.SIM_LOOP_FORCE_STEP
	-- 	)

	self.actionRoot = actionRoot
	self:setThrottle( 1 )

	-------Setup Callbacks
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
	collectgarbage('setpause',80)
	collectgarbage('setstepmul',200)

	----make inputs work
	initDefaultInputEventHandlers()

	----audio
	initFmodDesigner()

	----physics
	self.b2world = MOAIBox2DWorld.new()
	self:setupBox2DWorld()
	self.b2world:start()
	
	----ask other systems to initialize
	emitSignal( 'game.init' )

end


function Game:saveConfig( path )
	local layerConfigs = {}
	for i,l in pairs( self.layers ) do
		if l.name ~= '_GII_EDITOR_LAYER'  then
			layerConfigs[i] = {
				name     = l.name,
				sort     = l.sortMode,
				visible  = l.visible,
				default  = l.default,
				locked   = l.locked,
				-- priority = l.priority
			}
		end
	end

	local data = {
		name          = self.name,
		version       = self.version,
		title         = self.title,
		asset_library = self.assetLibraryIndex,
		graphics      = self.graphicsOption,
		layers        = layerConfigs,
	}

	local output = MOAIJsonParser.encode( data )
	local file = io.open( path, 'w' )
	if file then
		file:write(output)
		file:close()
		_stat( 'game config saved to', path )
	else
		_error( 'can not save game config to', path )
	end
end

--------------------------------------------------------------------
--------Graphics related
--------------------------------------------------------------------
function Game:initGraphics( fromEditor )
	local option = self.graphicsOption or {}
	local w, h = getDeviceResolution()
	if w*h == 0 then
		w, h  = option['device_width'] or 800, option['device_height'] or 600
	end
	self.deviceWidth  = w
	self.deviceHeight = h

	self.width   = option['width'] or w
	self.height  = option['height'] or h

	self.viewportMode = option['viewport_mode'] or 'fit'

	local fullscreen = option['fullscreen'] or false
	self.fullscreen = fullscreen	

	_stat( 'opening window', self.title, w, h)
	if not fromEditor then
		--FIXME: crash here if no canvas shown up yet
		MOAISim.openWindow( self.title, self.deviceWidth, self.deviceHeight  )
	end
	self.graphicsInitialized = true
end

function Game:setViewportScale( w, h )
	self.width  = w
	self.height = h
	emitSignal( 'gfx.resize', w, h )
end

function Game:getViewportScale()
	return self.width, self.height
end

function Game:setDeviceSize( w, h )
	self.deviceWidth  = w
	self.deviceHeight = h
	emitSignal( 'device.resize', self.width, self.height )
end

function Game:getDeviceResolution( )
	return self.deviceWidth, self.deviceHeight
end

function Game:getViewportRect()
	local mode = self.viewportMode or 'fit'
	if mode == 'fit' then
		local aspect = self.width / self.height
		local w = math.min( self.deviceWidth, self.deviceHeight * aspect )
		local h = math.min( self.deviceWidth / aspect, self.deviceHeight )
		local x0,y0,x1,y1
		x0 = ( self.deviceWidth - w ) / 2
		y0 = ( self.deviceHeight - h ) / 2
		x1 = x0 + w
		y1 = y0 + h
		return x0,y0,x1,y1
	end
	return 0,0,self.deviceWidth,self.deviceHeight
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
function Game:addScene( name, scn, initNow )
	assert( not self.scenes[ name ], 'Duplicated scene:'..name )

	self.scenes[ name ] = scn
	scn.name = name
	scn.game = self
	
	if initNow then	return scn:init() end
end

function Game:getScene( name )
	return self.scenes[ name ]
end

function Game:enterScene(name,option)
	local scn=self.scenes[ name ]
	assert( scn, 'scene not found:'..name )
	if scn.active then return end
	return scn:enter( option or {} )
end

function Game:getActiveScenes()
	local l = {}
	for k, scn in pairs( self.scenes ) do
		if scn.active then l[k] = scn end
	end
	return l
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
	local i = table.find( self.layers, layer )
	if not i then return end
	table.remove( self.layers, i )
end

function Game:getLayer( name )
	for i, l in ipairs( self.layers ) do
		if l.name == name then return l end
	end
	return nil
end

--------------------------------------------------------------------
------Action related
--------------------------------------------------------------------
function Game:getTime()
	return self.time
end

function Game:newSubClock()
	return newClock(function()
		return self.time
	end)
end

function Game:onRootUpdate( delta )
	self.time = self.time + delta
	-- emitSignal('game.update', delta)
end

function Game:resetClock()
	self.time = 0
end

function Game:setStep(step,stepMul)
	if step then MOAISim.setStep(step) end
	if stepMul then MOAISim.setStepMultiplier(stepMul) end
end

function Game:pause()
	self.paused = true
	return self.actionRoot:pause()
end

function Game:stop()
	os.exit() --TODO:  ????
end

function Game:start( entryScene )
	entryScene = entryScene or self.entryScene
	self.paused = false
	return self.actionRoot:stop()
end

function Game:isPaused()
	return self.paused
end

function Game:pushActionRoot( action )
	action.prev = self.actionRoot
	self.actionRoot = action
	MOAIActionMgr.setRoot( self.actionRoot )
end

function Game:popActionRoot()
	local r=self.actionRoot.prev
	if r then 
		self.actionRoot=r 
		MOAIActionMgr.setRoot(self.actionRoot)
	end
end

function Game:getActionRoot()
	return self.actionRoot
end

function Game:setThrottle(v)
	self.throttle=v
	return self.actionRoot:throttle(v*1)
end

--------------------------------------------------------------------
---------Data settings
--------------------------------------------------------------------
function Game:updateSetting(key,data, persistLater)
	self.settingData[key]=data
	if not persistLater then
		self:saveData(self.settingFileName,self.settingData)
	end
end

function Game:getSetting(key)
	return self.settingData[key]
end

function Game:getUserDataPath( path )
	if not path then return self.userDataPath end
	return self.userDataPath .. '/' ..path
end

function Game:saveSettingData( filename, data )
	local str  = MOAIJsonParser.encode( data )
	local raw  = MOAIDataBuffer.deflate( str, 0 )
	local file = io.open( self.userDataPath..'/'..filename, 'wb' )
	file:write( raw )
	file:close()
	--todo: exceptions?
	return true
end

function Game:loadSettingData(filename)
	local file=io.open( self.userDataPath..'/'..filename, 'rb' )
	if file then
		local raw = file:read('*a')
		local str = MOAIDataBuffer.inflate( raw )
		return MOAIJsonParser.decode( str )
	else
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
	return MOAIGfxDevice.getFrameBuffer():setClearColor( r,g,b,a )
end

--------------------------------------------------------------------
--PHYSICS
--------------------------------------------------------------------
local defaultWorldSettings = {
	gravity               = { 0, -100 },
	unitsToMeters         = 1,
	velocityIterations    = 4,
	positionIterations    = 6,

	angularSleepTolerance = 0,
	linearSleepTolerance  = 0,
	timeToSleep           = 0,

	autoClearForces       = true,

}

function Game:setupBox2DWorld( settings )
	settings = settings or defaultWorldSettings 
	local world = self.b2world
	
	if settings.unitsToMeters then
		world:setUnitsToMeters ( settings.unitsToMeters )
	end
	
	if settings.gravity then
		world:setGravity ( unpack(settings.gravity) )
	end
	
	local velocityIterations, positionIterations = settings.velocityIterations, settings.positionIterations
	velocityIterations = velocityIterations or defaultWorldSettings.velocityIterations
	positionIterations = positionIterations or defaultWorldSettings.positionIterations
	world:setIterations ( velocityIterations, positionIterations )

	world:setAutoClearForces ( settings.autoClearForces )

	-- world:setTimeToSleep           ( settings.timeToSleep )
	-- world:setAngularSleepTolerance ( settings.angularSleepTolerance )
	-- world:setLinearSleepTolerance  ( settings.linearSleepTolerance )

end

function Game:getBox2DWorld()
	return self.b2world
end

function Game:startBox2DWorld()
	self.b2world:start()
end

function Game:pauseBox2DWorld( paused )
	self.b2world:pause( paused )
end

--------------------------------------------------------------------
--Context Related
--------------------------------------------------------------------
function Game:setRenderStack( context, deviceRenderTable, bufferTable, renderTableMap )
	--render context helper for GII
	local gii = rawget( _G, 'gii' )
	if gii then
		local renderContext = gii.getRenderContext( context )
		assert( renderContext, 'render context not found:' .. context )
		local renderTableMap1 = {}
		for fb, rt in pairs( renderTableMap ) do
			table.insert( renderTableMap1, { fb, rt } )
		end
		renderContext.renderTableMap    = renderTableMap1
		renderContext.bufferTable       = bufferTable
		renderContext.deviceRenderTable = deviceRenderTable
	elseif context ~= 'game' then
		_error( 'no gii module found for render context functions')
	end

	if context == self.currentRenderContext then
		for framebuffer, renderTable in pairs( renderTableMap ) do
			framebuffer:setRenderTable( renderTable )
		end
		MOAIGfxDevice.getFrameBuffer():setRenderTable( deviceRenderTable )	
		MOAIRenderMgr.setBufferTable( bufferTable )
	end
end

function Game:setCurrentRenderContext( key )
	self.currentRenderContext = key or 'game'
end

function Game:getCurrentRenderContext()
	return self.currentRenderContext or 'game'
end




game = Game()
