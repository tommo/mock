module 'mock'

CLASS: BehaviourScript ( mock.Behaviour )
	:MODEL{
		Field 'comment' :string();
		Field 'script'  :string() :widget('codebox') :meta{ code_ext = 'lua' };
		Field 'OpenExternalEdit' :action('openExternalEdit')
}

registerComponent( 'BehaviourScript', BehaviourScript )

local defaultScript = [[
-- adhoc script
-- usable variable: self( mock.Behaviour ),  entity( mock.Entity )
--

-- function onThread()
-- end

function onMsg( msg, data )
	print(entity:getName(),msg,data)
end

-- function onUpdate( dt )
-- end

]]

local scriptHeader = [[local self, entity = ...;]]

local scriptTail = [[
]]

function BehaviourScript:__init()
	self.comment = ''
	self.script = defaultScript
	self.loadedScript = false
end

function BehaviourScript:onAttach( ent )
	BehaviourScript.__super.onAttach( self, ent )
	self:updateScript( ent )
end

function BehaviourScript:onStart( ent )
	self:updateScript( ent )
	local delegate = self.delegate
	if delegate then
		local onStart = delegate.onStart
		if onStart then
			onStart( ent )
		end
		self.onThread = delegate.onThread
		if delegate.onUpdate then
			ent.scene:addUpdateListener( self )
		end
	end
	BehaviourScript.__super.onStart( self, ent )
end

function BehaviourScript:updateScript( ent )
	if self.loadedScript == self.script then return end
	self.loadedScript = self.script

	self.delegate = false
	if self.msgListener then 
		ent:removeMsgListener( self.msgListener )
		self.msgListener = false
	end

	local finalScript = scriptHeader .. self.script .. scriptTail
	local loader, err = loadstring( finalScript, 'Script@'..ent:getName() )
	if not loader then return _error( err ) end
	local delegate = setmetatable( {}, { __index = _G } )
	setfenv( loader, delegate )
	
	local errMsg, tracebackMsg
	local function _onError( msg )
		errMsg = msg
		tracebackMsg = debug.traceback(2)
	end
	local succ = xpcall( function() loader( self, ent ) end, _onError )

	if delegate.onMsg then
		self.msgListener = delegate.onMsg
		ent:addMsgListener( self.msgListener )
	end

	if succ then
		self.delegate = delegate
	else
		print( errMsg )
		print( tracebackMsg )
		return _error( 'failed loading behaviour script' )
	end
end


function BehaviourScript:onUpdate( dt )
	return self.delegate.onUpdate( dt )
end

function BehaviourScript:onDetach( ent )
	if self.delegate then
		local onDetach = self.delegate.onDetach
		if onDetach then onDetach( ent ) end
	end
	if self.msgListener then
		ent:removeMsgListener( self.msgListener )
		self.msgListener = false
	end
	ent.scene:removeUpdateListener( self )
	BehaviourScript.__super.onDetach( self, ent )
	self.delegate = false
	self.onThread = false
end

function BehaviourScript:openExternalEdit()
	local options = gii.tableToDict( { ext = '.lua' } )
	self.session = gii.app:getModule( 'external_edit_manager' ):requestSession( self.__guid, 'behaviour_script', options )
	self.session:openExternalEdit()
end

--------------------------------------------------------------------
function BehaviourScript:installInputListener( option )
	return installInputListener( self.delegate, option )
end

function BehaviourScript:uninstallInputListener()
	if self.delegate then
		return uninstallInputListener( self.delegate )
	end
end

