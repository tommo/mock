module 'mock'
CLASS: Behaviour ( Actor )
 	:MODEL{}

function Behaviour:onAttach( b )
end

function Behaviour:onDetach( b )
	self:unsubscribeAll()
	self:disconnectAll()
	self:clearCoroutines()
	self:removeInputListener()
end

function Behaviour:onStart( entity )	
	self:subscribe( entity )
	if self.onThread then
		self:addCoroutine( 'onThread' )
	end
end

--------------------------------------------------------------------
function Behaviour:getEntity()
	return self._entity
end

function Behaviour:findEntity( name )
	return self._entity:findEntity( name )
end

function Behaviour:findChild( name )
	return self._entity:findChild( name )
end

function Behaviour:getParent()
	return self._entity.parent
end

--------------------------------------------------------------------
function Behaviour:enableInputListener( option )
	enableInputListener( self, option )
end

function Behaviour:removeInputListener()
	removeInputListener( self )
end

--------------------------------------------------------------------
function Behaviour:getComponent( comType )
	return self._entity:getComponent( comType )
end

function Behaviour:getComponentByName( comTypeName )
	return self._entity:getComponentByName( comTypeName )
end

function Behaviour:com( id )
	return self._entity:com( id )
end

function Behaviour:getScene()
	return self._entity.scene
end

--------------------------------------------------------------------
function Behaviour:broadcast( ... )
	return self._entity:broadcast( ... )
end
