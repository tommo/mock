module 'mock'
CLASS: Behaviour ( Component )
 	:MODEL{}

--------------------------------------------------------------------
function Behaviour:installInputListener()
	return installInputListener( self )
end

function Behaviour:uninstallInputListener()
	return uninstallInputListener( self )
end

--------------------------------------------------------------------
function Behaviour:onAttach( entity )
end

function Behaviour:onDetach( entity )
	self:uninstallInputListener()
	self:clearCoroutines()
end

function Behaviour:onStart( entity )	
	if self.onThread then
		self:addCoroutine( 'onThread' )
	end
end
