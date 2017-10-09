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
	self.hasActiveState    = false
	self.prop       = MOAIProp.new()
	self.activeStates    = {}
	self.mirrorX    = false
	self.mirrorY    = false
	self.actionOnStop = 'default'
	self.delay = 0
	self.transformRole = 'render'
	
	self.defaultState = false

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
		if self.delay > 0 then
			self:addCoroutine( function () 
				self:wait( self.delay )
				self:start()
			end)
		else
			self:start()
		end
	end
end

function EffectEmitter:restart()
	self:stop()
	self:start()
end

function EffectEmitter:loadEffect( effectConfig )
	if type( effectConfig ) == 'string' then
		effectConfig = loadAsset( effectConfig )
	end
	if not effectConfig then
		_error( 'nil effectConfig' )
		return false
	end
	local state = EffectState( self, effectConfig )
	self.activeStates[ state ] = true
	state:load()
	if not self.hasActiveState then
		self._entity.scene:addUpdateListener( self )
		self.hasActiveState = true
	end
	return state
end

function EffectEmitter:start()
	if self.defaultState then return end
	local effect = self.effect or self.effectConfig
	if not effect then
		return
	end	
	local state = self:loadEffect( effect )
	self.defaultState = state
	if self.duration then
		state:setDuration( self.duration )
	end
	state:start()
	return state
end

function EffectEmitter:stop( actionOnStop )
	if not self.hasActiveState then return end
	self._entity.scene:removeUpdateListener( self )
	for state in pairs( self.activeStates ) do
		state:stop()
	end
	self.defaultState = false
	self.activeStates = {}
	self.hasActiveState = false
	local actionOnStop = actionOnStop or self.actionOnStop
	if actionOnStop == 'default' then
		if self.effectConfig then
			actionOnStop = self.effectConfig:getRootNode().actionOnStop
		end
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
	local stoppedStates = false
	for state in pairs( self.activeStates ) do
		state:update( dt )
		if not state:isPlaying() then
			stoppedStates = stoppedStates or {}
			stoppedStates[ state ] = true
		end
	end
	local activeStates = self.activeStates
	if stoppedStates then
		for s in pairs( stoppedStates ) do
			if s == self.defaultState then self.defaultState = false end
			activeStates[ s ] = nil
		end
		if not next( activeStates ) then
			self:stop()
			return
		end
	end
	
end

function EffectEmitter:setEffect( e )
	local tt = type( e )
	if tt == 'string' then --path
		self.effect = e
		self.effectConfig = mock.loadAsset( e )
	else
		self.effect = false
		self.effectConfig = e
	end
end


function EffectEmitter:setActionOnStop( f )
	self.actionOnStop = f or 'default'
end

function EffectEmitter:setDuration( d )
	self.duration = d
	if self.defaultEffectState then
		self.defaultEffectState:setDuration( d )
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