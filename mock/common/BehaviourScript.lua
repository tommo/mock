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
end

function BehaviourScript:onStart( ent )
	self:loadScript( ent )
	BehaviourScript.__super.onStart( self, ent )
end

function BehaviourScript:loadScript( ent )
	self.delegate = false
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
	if succ then
		self.delegate = delegate
	else
		return _error( 'failed loading behaviour script' )
	end

	local onStart = delegate.onStart
	if onStart then
		onStart( ent )
	end

	self.onThread = delegate.onThread

	if delegate.onMsg then
		-- self.msgListener = function( msg, ... )
		-- 	print( 'inside onMsg of', ent:getName(), msg )
		-- 	return delegate.onMsg( msg, ... )
		-- end
		self.msgListener = delegate.onMsg
		ent:addMsgListener( self.msgListener )
	end
	if delegate.onUpdate then
		ent.scene:addUpdateListener( self )
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

