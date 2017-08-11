module 'mock'

CLASS: SceneSession ()
	:MODEL{}

function SceneSession:__init()
	self.scene = Scene()
	self.scene.session = self
	self.initialized = false
	self.initialScene = false
	self.name = false
	self.main = false
end

function SceneSession:getName()
	return self.name
end

function SceneSession:init()
	if self.initialized then return end
	self.initialized = true
	self.scene:init()
end

function SceneSession:openSceneByPath( scnPath, additive, arguments, autostart )
	_stat( 'openning scene:', scnPath )
	if not self.initialScene then
		self.initialScene = scnPath
	end
	local scene = self.scene
	scene.assetPath = scnPath
	autostart = autostart ~= false
	
	local fromEditor = arguments and arguments[ 'fromEditor' ] or false
	
	if not additive then
		scene:stop()
		scene:clear( true )
		collectAssetGarbage()
		scene:reset()
	end

	--load arguments first
	local args = scene.arguments or {}
	if not additive then args = {} end
	if arguments then
		for k,v in pairs( arguments ) do
			args[ k ] = v
		end
	end

	--todo: previous scene
	scene.arguments = args and table.simplecopy( args ) or {}

	--load entities
	local runningState = scene.running
	scene.running = false --start entity in batch
	local scn, node = loadAsset(
		scnPath, 
		{ 
			scene = scene,
			allowConditional = not fromEditor
		}
	)
	if not node then 
		return _error('scene not found', scnPath )
	end
	if node.type ~= 'scene' then
		return _error('invalid type of entry scene:', tostring( node.type ), scnPath )
	end
	scene.running = runningState

	emitGlobalSignal( 'scene.open', scn, arguments )
	if self.main then
		emitGlobalSignal( 'mainscene.open', scn, arguments )
	end

	scene:notifyLoad( scnPath )

	if autostart then
		scn:start()
	end
	emitGlobalSignal( 'scene.start', scn, arguments )
	if self.main then
		emitGlobalSignal( 'mainscene.start', scn, arguments )
	end
	return scn
end

function SceneSession:scheduleOpenSceneByPath( scnPath, additive, arguments, autostart )
	_stat( 'schedule openning scene:', scnPath )
	autostart = true
	self.pendingLoading = { 
		['path']      = scnPath,
		['additive']  = additive,
		['arguments'] = arguments,
		['autostart'] = autostart
	}
	emitGlobalSignal( 'scene.schedule_open', self.pendingLoading )
	if self.main then
		emitGlobalSignal( 'mainscene.schedule_open', self.pendingLoading )
	end
end

function SceneSession:reopenScene()
	_stat( 're-openning scene' )
	if not self.scene then return false end
	local assetPath = self.scene.assetPath
	if assetPath then
		return self:openSceneByPath( assetPath )
	else
		return false
	end
end

function SceneSession:scheduleReopenScene()
	_stat( 'schedule re-openning scene' )
	if not self.scene then return false end
	local assetPath = self.scene.assetPath
	if assetPath then
		return self:scheduleOpenSceneByPath( assetPath )
	else
		return false
	end
end

function SceneSession:clearPendingScene()
	self.pendingLoading = false
end

function SceneSession:getPendingSceneData()
	return self.pendingLoading
end

function SceneSession:getScene()
	return self.scene
end

function SceneSession:update()
	if self.pendingLoading then
		local loadingParams = self.pendingLoading
		self.pendingLoading = false
		self:openSceneByPath( 
			loadingParams['path'],
			loadingParams['additive'],
			loadingParams['arguments'],
			loadingParams['autostart']
		)
	end
end

function SceneSession:start()
	return self.scene:start()
end


function SceneSession:stop()
	return self.scene:stop()
end

function SceneSession:clear( keepEditorObjects )
	return self.scene:clear( keepEditorObjects )
end

function SceneSession:pause( paused )
	return self.scene:pause( paused )
end

function SceneSession:isPaused()
	return self.scene:isPaused()
end
