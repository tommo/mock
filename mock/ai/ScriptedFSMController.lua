module 'mock'

CLASS: ScriptedFSMController ( FSMController )
	:MODEL{
		Field 'script' :asset( 'com_script' ) :getset( 'Script' );
	}

registerComponent( 'ScriptedFSMController', ScriptedFSMController )

function ScriptedFSMController:__init()
	self.scriptPath   = false
	self.delegate     = false
	self.dataInstance = false
end

function ScriptedFSMController:getScript()
	return self.scriptPath
end

function ScriptedFSMController:setScript( path )
	self.scriptPath = path
	self:updateComponentScript()
end

function ScriptedFSMController:updateComponentScript()
	local path = self.scriptPath
	local scriptObj = loadAsset( path )
	local delegate, dataInstance
	for k, v in pairs( self ) do --clear collected method
		if k:startwith( '_FSM_' ) then
			self[ k ] = false
		end
	end
	if scriptObj then
		local fsmCollector = FSMController.__createStateMethodCollector( self )
		delegate, dataInstance =  scriptObj:buildInstance( self, { fsm = fsmCollector } )
	end
	local prevInstance = self.dataInstance
	self.delegate     = delegate or false
	self.dataInstance = dataInstance or false
	if prevInstance and dataInstance then
		_cloneObject( prevInstance, dataInstance )
	end
end

function ScriptedFSMController:onStart( ent )
	--Update delegate
	local delegate = self.delegate
	if delegate then
		--insert global variables
		delegate.entity = ent
		-- delegate.scene  = ent:getScene()

		local onStart = delegate.onStart
		if onStart then	onStart()	end

		self.onThread = delegate.onThread

		local onMsg = delegate.onMsg
		if onMsg then
			self.msgListener = onMsg
			ent:addMsgListener( self.msgListener )
		end

		if delegate.onUpdate then
			ent.scene:addUpdateListener( self )
		end
	end

	return FSMController.onStart( self, ent )
end

function ScriptedFSMController:onUpdate( dt )
	return self.delegate.onUpdate( dt )
end

function ScriptedFSMController:onDetach( ent )
	if self.delegate then
		local onDetach = self.delegate.onDetach
		if onDetach then onDetach( ent ) end
		if self.msgListener then
			ent:removeMsgListener( self.msgListener )
		end
		ent.scene:removeUpdateListener( self )
	end
end

function ScriptedFSMController:installInputListener( option )
	return installInputListener( self.delegate, option )
end

function ScriptedFSMController:uninstallInputListener()
	return uninstallInputListener( self.delegate )
end

function ScriptedFSMController:__serialize( objMap )
	local dataInstance = self.dataInstance
	if not dataInstance then return end
	return _serializeObject( dataInstance, objMap )
end

function ScriptedFSMController:__deserialize( data, objMap )
	if not data then return end
	local dataInstance = self.dataInstance
	if not dataInstance then return end
	return _deserializeObject( dataInstance, data, objMap )
end

function ScriptedFSMController:__clone( src, objMap )
	local dataInstance = self.dataInstance
	if not dataInstance then return end
	return _cloneObject( src, dataInstance, objMap )	
end


