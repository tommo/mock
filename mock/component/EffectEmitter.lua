module 'mock'
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
	local state = EffectState( self, self.effectConfig )
	self.effectConfig:loadIntoState( state )
	self.activeStates[ state ] = true
end

function EffectEmitter:stop()
	-- local state = self.effectConfig
	for state in pairs( self.activeStates ) do
		state:stop()
	end
	self.activeStates = {}
end

function EffectEmitter:onUpdate( dt )	
	for state in pairs( self.activeStates ) do
		state:update( dt )
	end
end
