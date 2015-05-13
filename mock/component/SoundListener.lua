module 'mock'
--------------------------------------------------------------------
--SOUND Listener
--------------------------------------------------------------------
--TODO: add multiple listener support (need host works) ?
CLASS: SoundListener ()
:MODEL{
	Field 'forward'    :type('vec3') :getset('VectorForward');
	Field 'up'         :type('vec3') :getset('VectorUp') ;
	Field 'syncRot'    :boolean();
	
}
wrapWithMoaiTransformMethods( SoundListener, '_listener' )

function SoundListener:__init()
	local listener = MOAIFmodEventMgr.getMicrophone()
	self._listener = listener
	self.syncRot = true
	self:setVectorForward( 0,0,-1 )
	self:setVectorUp( 0,1,0 )
	self.transformHookNode = MOAIScriptNode.new()
end

function SoundListener:onAttach( entity )
	if self.syncRot then
		entity:_attachTransform( self._listener )
	else
		entity:_attachLoc( self._listener )
	end
end

function SoundListener:onDetach( entity )
	-- do nothing...
end

function SoundListener:getVectorForward()
	return unpack( self.forward )
end

function SoundListener:setVectorForward( x,y,z )
	self.forward = { x,y,z }
	self._listener:setVectorForward( x,y,z )
end

function SoundListener:getVectorUp()
	return unpack( self.up )
end

function SoundListener:setVectorUp( x,y,z )
	self.up = { x,y,z }
	self._listener:setVectorUp( x,y,z )
end

registerComponent( 'SoundListener', SoundListener )

