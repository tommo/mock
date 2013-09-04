module 'mock'
CLASS: Behaviour ( Actor )
 	:MODEL{}

function Behaviour:onAttach( b )
	if self.onThread then
		self:addCoroutine( 'onThread' )
	end
end

function Behaviour:onDetach( b )
	self:unsubscribeAll()
	self:disconnectAll()
	self:clearCoroutines()
	self:removeInputListener()
end

function Behaviour:getEntity()
	return self._entity
end

function Behaviour:findEntity( name )
	return self._entity:findEntity( name )
end

function Behaviour:enableInputListener( option )
	enableInputListener( self, option )
end

function Behaviour:removeInputListener()
	removeInputListener( self )
end