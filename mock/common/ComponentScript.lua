module 'mock'

--------------------------------------------------------------------
CLASS: ComponentScript ()
	:MODEL{}

function ComponentScript:__init()
	self.source     = false
	self.loaderFunc = false
	self.dataClass  = false
end

function ComponentScript:load( source, path )
	self.source = source
	self.loaderFunc = false
	if not source then return end
	local name = path and '@'..path or 'script'
	local loaderFunc, err = loadstring( source, name )
	if not loaderFunc then
		_warn( 'failed loading component script' )
		_log( '[ERROR:Lua]', err )
		return false
	end
	self.loaderFunc = loaderFunc
	self:buildClass()
	return true
end

function ComponentScript:buildClass()
	local loaderFunc = self.loaderFunc
	if not loaderFunc then return false end

	local dataClass = _rawClass()
	local delegate = setmetatable( {}, { __index = _G } )
	delegate._M = delegate
	delegate.MODEL = function( t )
		local m = Model( dataClass )
		m:update( t )
	end
	delegate.fsm = FSMController.__createStateMethodCollector( {} )

	setfenv( loaderFunc, delegate )
	
	local errMsg, tracebackMsg
	local function _onError( msg )
		errMsg = msg
		tracebackMsg = debug.traceback(2)
	end
	local succ = xpcall( 
		function()
			loaderFunc( self, self._entity )
		end,
		_onError
	)

	if not succ then
		print( errMsg )
		print( tracebackMsg )
		_warn( 'failed build component script instance' )
		self.dataClass = false
		return false
	end
	
	self.dataClass = dataClass
	return true
	
end


function ComponentScript:buildInstance( obj, env )
	local loaderFunc = self.loaderFunc
	local dataClass  = self.dataClass
	if not loaderFunc then return false end
	if not dataClass then return false end

	local dataInstance = dataClass()
	local delegate = setmetatable( env or {
			onStart  = false,
			onThread = false,
			onMsg    = false,
			onUpdate = false,
			onAttach = false,
			onDetach = false
		}, { __index = _G } )
	delegate._M = delegate
	delegate.MODEL = function( t ) end --do nothing
	
	delegate.data  = dataInstance
	delegate.self  = obj

	setfenv( loaderFunc, delegate )
	
	local errMsg, tracebackMsg
	local function _onError( msg )
		errMsg = msg
		tracebackMsg = debug.traceback(2)
	end
	local succ = xpcall( 
		function()
			loaderFunc( self, self._entity )
		end,
		_onError
	)

	if not succ then
		print( errMsg )
		print( tracebackMsg )
		_warn( 'failed build component script instance' )
		return false
	end
	local __init = rawget( delegate, '__init' )
	if __init then
		__init()
	end
	return delegate, dataInstance
end


function ComponentScriptLoader( node )
	local path = node:getObjectFile( 'script' )
	local f = io.open( path, 'r' )
	if f then
		local src = f:read( '*a' )
		local script = ComponentScript()
		if script:load( src, path ) then
			return script
		end
	end
	return false
end

registerAssetLoader( 'com_script',  ComponentScriptLoader )

