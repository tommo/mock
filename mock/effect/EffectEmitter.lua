module 'mock'

EnumActionOnStop = _ENUM_V{
	'default', --inherit from effect
	'detach',
	'destroy',
	'none'
}
--------------------------------------------------------------------
CLASS: EffectEmitter ( Component )
	:MODEL{
		Field 'effect'        :asset('effect') :set('setEffect');
		Field 'autoPlay'      :boolean();
		Field 'actionOnStop'  :enum( EnumActionOnStop );
		Field 'delay'					:number();
		'----';
		Field 'transformRole' :string();
	}
	:META{
		category = 'FX'
	}
	
mock.registerComponent( 'EffectEmitter', EffectEmitter )
--------------------------------------------------------------------

function EffectEmitter:__init()
	self.duration   = false
	self.effect     = false
	self.autoPlay   = true
	self.effectConfig = false
	self.playing    = false
	self.prop       = MOAIProp.new()
	self.activeStates    = {}
	self.mirrorX    = false
	self.mirrorY    = false
	self.actionOnStop = 'default'
	self.delay = 0
	self.transformRole = 'render'
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
	entity:_attachProp( self.prop, self.transformRole or 'render' )
end

function EffectEmitter:onDetach( entity )
	self:stop()
	entity:_detachProp( self.prop )
end

function EffectEmitter:onStart()
	if self.autoPlay then
		self:addCoroutine( function () 
			self:wait( self.delay )
			self:start()
		end)
	end
end

function EffectEmitter:setMirrorX( mirror )
	self.mirrorX = mirror
	setSclX( self.prop, (mirror and -1) or 1 )
end

function EffectEmitter:setMirrorY( mirror )
	self.mirrorY = mirror
	setSclY( self.prop, (mirror and -1) or 1 )
	
end

function EffectEmitter:restart()
	self:stop()
	self:start()
end

function EffectEmitter:createEffectState( effectConfig )
	if type( effectConfig ) == 'string' then
		effectConfig = loadAsset( effectConfigPath )
	end
	if not effectConfig then
		_error( 'nil effectConfig' )
		return false
	end
	local state = EffectState( self, effectConfig )
	self.activeStates[ state ] = true
	return state
end

function EffectEmitter:start( waitStart )
	if self.playing then return end
	if not self.effectConfig then return end	
	local state = self:createEffectState( self.effectConfig )
	state:load()
	self.activeStates[ state ] = true
	self.time0 = os.clock()
	if self.duration then
		self.time1 = self.time0 + self.duration	
	else
		self.time1 = false
	end
	self._entity.scene:addUpdateListener( self )
	self.playing = true
	if not waitStart then
		state:start()
	end
	return state
end

function EffectEmitter:stop( actionOnStop )
	if not self.playing then return end
	self.playing = false
	-- local state = self.effectConfig
	self._entity.scene:removeUpdateListener( self )
	for state in pairs( self.activeStates ) do
		state:stop()
	end
	self.activeStates = {}
	local actionOnStop = actionOnStop or self.actionOnStop
	if actionOnStop == 'default' then
		actionOnStop = self.effectConfig:getRootNode().actionOnStop
	end

	if actionOnStop == 'detach' then
		self._entity:detach( self )
	elseif actionOnStop == 'destroy' then
		self._entity:destroy()
	else
		-- do nothing
	end
end

function EffectEmitter:onUpdate( dt )
	local stopped = false
	for state in pairs( self.activeStates ) do
		state:update( dt )
		if not state:isPlaying() then
			stopped = stopped or {}
			stopped[ state ] = true
		end
	end
	if stopped then
		for s in pairs( stopped ) do
			self.activeStates[ s ] = nil
		end
		if not next( self.activeStates ) then
			self:stop()
			return
		end
	end
	
	local t = os.clock()
	if self.time1 and t >= self.time1 then
		self:stop()
	end

end

function EffectEmitter:setActionOnStop( f )
	self.actionOnStop = f or 'default'
end

function EffectEmitter:setDuration( d )
	self.duration = d
	if self.playing then
		self.time1 = self.time0 + self.duration	
	end
end


--------------------------------------------------------------------
--EDITOR Support
if mock_edit then
	function EffectEmitter:onBuildGizmo()
		local giz = mock_edit.IconGizmo( 'effect.png' )
		return giz
	end

	function EffectEmitter:onBuildPreviewer()
		return EffectEmitterPreviewer( self )
	end

	--------------------------------------------------------------------
	CLASS: EffectEmitterPreviewer ( ComponentPreviewer )
		:MODEL{}

	function EffectEmitterPreviewer:__init( emitter )
		self.targetEmitter = emitter
	end

	function EffectEmitterPreviewer:onStart()
		self.targetState = self.targetEmitter:start()
	end

	function EffectEmitterPreviewer:onUpdate( dt )
		-- self.targetState:update( dt )
	end

	function EffectEmitterPreviewer:onDestroy()
		if self.targetState then
			self.targetEmitter:stop( 'skip' )
			self.targetState = false
		end
	end

	function EffectEmitterPreviewer:onReset()
		self:onDestroy()
		self:onStart()
	end

end