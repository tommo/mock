module 'mock'

--------------------------------------------------------------------
CLASS: ScriptedBehaviour ( Behaviour )
	:MODEL{
		Field 'script' :asset( 'com_script' ) :getset( 'Script' );
	}

registerComponent( 'ScriptedBehaviour', ScriptedBehaviour )

function ScriptedBehaviour:__init()
	self.scriptPath   = false
	self.delegate     = false
	self.dataInstance = false
end

function ScriptedBehaviour:getScript()
	return self.scriptPath
end

function ScriptedBehaviour:setScript( path )
	self.scriptPath = path
	self:updateComponentScript()
end

function ScriptedBehaviour:updateComponentScript()
	local path = self.scriptPath
	local scriptObj = loadAsset( path )
	local delegate, dataInstance
	if scriptObj then
		delegate, dataInstance =  scriptObj:buildInstance( self )
	end
	local prevInstance = self.dataInstance
	self.delegate     = delegate or false
	self.dataInstance = dataInstance or false
	if prevInstance and dataInstance then
		_cloneObject( prevInstance, dataInstance )
	end
end

function ScriptedBehaviour:onStart( ent )
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

	return Behaviour.onStart( self, ent )
end

function ScriptedBehaviour:onUpdate( dt )
	return self.delegate.onUpdate( dt )
end

function ScriptedBehaviour:onDetach( ent )
	if self.delegate then
		local onDetach = self.delegate.onDetach
		if onDetach then onDetach( ent ) end
		if self.msgListener then
			ent:removeMsgListener( self.msgListener )
		end
		ent.scene:removeUpdateListener( self )
	end
end

function ScriptedBehaviour:installInputListener( option )
	return installInputListener( self.delegate, option )
end

function ScriptedBehaviour:uninstallInputListener()
	return uninstallInputListener( self.delegate )
end

function ScriptedBehaviour:__serialize( objMap )
	local dataInstance = self.dataInstance
	if not dataInstance then return end
	return _serializeObject( dataInstance, objMap )
end

function ScriptedBehaviour:__deserialize( data, objMap )
	if not data then return end
	local dataInstance = self.dataInstance
	if not dataInstance then return end
	return _deserializeObject( dataInstance, data, objMap )
end

function ScriptedBehaviour:__clone( src, objMap )
	local dataInstance = self.dataInstance
	if not dataInstance then return end
	return _cloneObject( src, dataInstance, objMap )	
end


