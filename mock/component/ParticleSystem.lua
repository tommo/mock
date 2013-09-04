module 'mock'


--------------------------------------------------------------------
CLASS: ParticleSystem ()
	:MODEL {
	}

-- wrapWithMoaiPropMethods( ParticleSystem, '_system' )

function ParticleSystem:__init( config )
	self._system = false
	self:setConfig( config )	
	self.emitters = {}
end

function ParticleSystem:onAttach( owner )
	if self._system then 
		owner:_insertPropToLayer( self._system )
	end
	self._owner = owner
end

function ParticleSystem:onDetach( owner )
	self:stop()
	for em in pairs( self.emitters ) do
		em:stop()
	end
end

function ParticleSystem:setConfig( config )
	if self.config then
		self:stop()
	end	
	self.config = config
	if config then
		self._system = config:requestSystem()
		if self._owner then
			self.owner:_insertPropToLayer( self._system )
		end
	end
end

--------------------------------------------------------------------
function ParticleSystem:start()
	if self._system then
		return self._system:start()
	end
end

function ParticleSystem:stop()
	if self._system then
		self._owner:_detachProp( self._system )
		self.config:_pushToPool( self._system )
		self._system = false
	end
end

--------------------------------------------------------------------
function ParticleSystem:addEmitter( emitterName )
	--check dead emitter
	local toRemove = {}
	local emitters = self.emitters
	for em in pairs( emitters ) do
		if em:isDone() then
			toRemove[ em ] = true
		end
	end
	for em in pairs(toRemove) do
		emitters[ em ] = nil			
	end

	if not emitterName then
		local em = MOAIParticleTimedEmitter.new()
		self._owner:_attachTransform( em )
		em:forceUpdate()
		em:setSystem( self._system )		
		em:start()
		self.emitters[ em ] = true
		return em
	end

	local em = self.config:buildEmitter( emitterName )
	self._owner:_attachTransform( em )
	em:forceUpdate()
	em:setSystem( self._system )
	em:start()
	self.emitters[ em ] = true
	--TODO: attach as new component?
	return em
end

function ParticleSystem:clearEmitters()
	for em in pairs( self.emitters ) do
		em:stop()
	end
	self.emitters = {}
end

function ParticleSystem:addForceToAll( force )
end

function ParticleSystem:addForceToState( stateName, force )
end

--------------------------------------------------------------------
registerComponent( 'ParticleSystem', ParticleSystem )

function Entity:addParticleSystem( option )
	return self:attach( ParticleSystem( option ) )
end

updateAllSubClasses( Entity )

