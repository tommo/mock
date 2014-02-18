module 'mock'
--------------------------------------------------------------------
CLASS: EffectEmitterState ()
	:MODEL{}

function EffectEmitterState:__init()
end

function EffectEmitterState:start()
end

function EffectEmitterState:stop()
end



--------------------------------------------------------------------
CLASS: EffectEmitter ( Component )
	:MODEL{
		Field 'effect' :asset('effect') :set('setEffect');
		Field 'autoPlay' :boolean();
}

mock.registerComponent( 'EffectEmitter', EffectEmitter )
--------------------------------------------------------------------

function EffectEmitter:__init()
	self.effect     = false
	self.autoPlay   = true
	self.effectConfig = false
	self.started    = false
	self.prop       = MOAIProp.new()
	self.updatingEffects = {}
	self.activeStates    = {}
end

function EffectEmitter:setEffect( e )
	local tt = type( e )
	if tt == 'string' then --path
		self.effect = e
		self.effectConfig = mock.loadAsset( e )
	else
		self.effectConfig = e
	end
end

function EffectEmitter:onAttach( entity )
	entity:_attachProp( self.prop )
end

function EffectEmitter:onDetach( entity )
	entity:_detachProp( self.prop )
	self.prop:forceUpdate()
	entity.scene:removeUpdateListener( self )
end
 
function EffectEmitter:onStart()
	if self.autoPlay then
		self:start()
	end
	self._entity.scene:addUpdateListener( self )
end

function EffectEmitter:start()
	if self.started then return end
	self.started = true
	if not self.effectConfig then return end	
	self.effectConfig:loadIntoEmitter( self )
end

function EffectEmitter:stop()
	local state = self.effectConfig
end

function EffectEmitter:onUpdate( dt )	
	for eff in pairs( self.updatingEffects ) do
		eff:onUpdate( self, dt )
	end
end

function EffectEmitter:addUpdatingEffect( e )
	self.updatingEffects[ e ] = true
end

function EffectEmitter:removeUpdatingListener( e )
	self.updatingEffects[ e ] = nil
end


