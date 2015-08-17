module 'mock'
CLASS: Behaviour ( Component )
 	:MODEL{}

--------------------------------------------------------------------
function Behaviour:installInputListener( option )
	return installInputListener( self, option )
end

function Behaviour:uninstallInputListener()
	return uninstallInputListener( self )
end

--------------------------------------------------------------------
function Behaviour:installMsgListener()
	local onMsg = self.onMsg
	if onMsg then
		self._msgListener = self._entity:addMsgListener( function( msg, data, src )
			return onMsg( self, msg, data, src )
		end )
	end
end

function Behaviour:uninstallMsgListener()
	if self._msgListener then
		self._entity:removeMsgListener( self._msgListener )
		self._msgListener = false
	end
end

--------------------------------------------------------------------
function Behaviour:onAttach( entity )
	if self.onMsg then
		self:installMsgListener()
	end
end

function Behaviour:onDetach( entity )
	self:uninstallInputListener()
	self:uninstallMsgListener()
	self:clearCoroutines()
end

function Behaviour:onStart( entity )	
	if self.onThread then
		self:addCoroutine( 'onThread' )
	end	
end
