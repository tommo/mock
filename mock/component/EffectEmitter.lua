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
	self.duration   = false
	self.effect     = false
	self.autoPlay   = false
	self.effectConfig = false
	self.destroyOnStop = false
	self.playing    = false
	self.prop       = MOAIProp.new()
	self.activeStates    = {}
	self.mirrorX    = false
	self.mirrorY    = false
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
	self:stop()
	entity:_detachProp( self.prop )
	self.prop:forceUpdate()
end
 
function EffectEmitter:onStart()
	if self.autoPlay then
		self:start()
	end
end

function EffectEmitter:setMirrorX( mirror )
	self.mirrorX = mirror
end

function EffectEmitter:setMirrorY( mirror )
	self.mirrorY = mirror
end

function EffectEmitter:start()
	if self.playing then return end
	self.playing = true
	if not self.effectConfig then return end	
	local state = EffectState( self, self.effectConfig )
	self.effectConfig:loadIntoState( state )
	--state:start()
	self.activeStates[ state ] = true
	self.time0 = os.clock()
	if self.duration then
		self.time1 = self.time0 + self.duration	
	else
		self.time1 = false
	end
	self._entity.scene:addUpdateListener( self )
	return state
end

function EffectEmitter:stop()
	if not self.playing then return end
	self.playing = false
	-- local state = self.effectConfig
	self._entity.scene:removeUpdateListener( self )
	for state in pairs( self.activeStates ) do
		state:stop()
	end
	self.activeStates = {}
	if self.destroyOnStop then
		self._entity:detach( self )
	end
end

function EffectEmitter:onUpdate( dt )	
	for state in pairs( self.activeStates ) do
		state:update( dt )
	end
	local t = os.clock()
	if self.time1 and t >= self.time1 then
		self:stop()
	end
end

function EffectEmitter:setDestroyOnStop( f )
	self.destroyOnStop = false
end

function EffectEmitter:setDuration( d )
	self.duration = d
	if self.plaing then
		self.time1 = self.time0 + self.duration	
	end
end
