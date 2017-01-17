module 'mock'
--------------------------------------------------------------------
--SOUND Listener
--------------------------------------------------------------------
--TODO: add multiple listener support (need host works) ?
CLASS: SoundListener ( Component )
:MODEL{
	Field 'idx'            :int();
	'----';
	Field 'forward'        :type('vec3') :getset('VectorForward');
	Field 'up'             :type('vec3') :getset('VectorUp') ;
	Field 'syncRot'        :boolean();
	Field 'updateVelocity' :boolean();
}
:META{
	category = 'audio'
}
wrapWithMoaiTransformMethods( SoundListener, '_listener' )

function SoundListener:__init()
	self.idx = 1
	self._listener = false
	self.syncRot = true
	self.updateVelocity = false
	self:setVectorForward( 0,0,-1 )
	self:setVectorUp( 0,1,0 )
end

function SoundListener:onAttach( entity )
	local audioManager = AudioManager.get()
	local listener = audioManager:getListener( self.idx )
	if not listener then
		_warn( 'failed to get system sound listener' )
		return
	end
	if self.syncRot then
		entity:_attachTransform( listener, 'physics' )
	else
		entity:_attachLoc( listener, 'physics' )
	end
	self._listener = listener
	self:updateVectors()
	if self.updateVelocity then
		self:addCoroutine( 'actionUpdateVelocity' )
	end
end

function SoundListener:updateVectors()
	local _listener = self._listener
	if not _listener then return end
	local x, y, z = unpack( self.forward )
	_listener:setVectorForward( x,y,z )
	local x, y, z = unpack( self.up )
	_listener:setVectorUp( x,y,z )
end

function SoundListener:onDetach( entity )
	-- do nothing...
end

function SoundListener:getVectorForward()
	return unpack( self.forward )
end

function SoundListener:setVectorForward( x,y,z )
	self.forward = { x,y,z }
	self:updateVectors()
end

function SoundListener:getVectorUp()
	return unpack( self.up )
end

function SoundListener:setVectorUp( x,y,z )
	self.up = { x,y,z }
	self:updateVectors()
end

function SoundListener:actionUpdateVelocity()
	local ent = self:getEntity()
	local x, y, z = ent:getWorldLoc()
	local _listener = self._listener
	while true do
		local dt = coroutine.yield()
		ent:forceUpdate()
		local x1, y1, z1 = ent:getWorldLoc()
		if dt > 0 then
			local vx = (x1 - x)/dt
			local vy = (y1 - y)/dt
			local vz = (z1 - z)/dt
			_listener:setVelocity( vx, vy, vz )
		end
	end
end

registerComponent( 'SoundListener', SoundListener )

