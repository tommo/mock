module 'mock'

--------------------------------------------------------------------
CLASS: EffectNodeParticleSystem  ( EffectNode )
CLASS: EffectNodeParticleState   ( EffectNode )
CLASS: EffectNodeParticleEmitter ( EffectNode )
CLASS: EffectNodeParticleForce   ( EffectNode )

----------------------------------------------------------------------
--CLASS: EffectNodeParticleSystem
--------------------------------------------------------------------
EffectNodeParticleSystem :MODEL{
		
}

function EffectNodeParticleSystem:__init()
end

function EffectNodeParticleSystem:getDefaultName()
	return 'particle'
end

function EffectNodeParticleSystem:build()

end


--------------------------------------------------------------------
--CLASS:  EffectNodeParticleState
--------------------------------------------------------------------
EffectNodeParticleState :MODEL{
		Field 'name'         :string() ;
		Field 'active'       :boolean() ;
		Field 'life'         :type('vec2') :range(0) :getset('Life');
		Field 'script'       :string() :no_edit();
		-- Field 'scriptParam'  :
	}

function EffectNodeParticleState:__init()
	self.name         = 'state'
	self.active       = true
	self.life         = { 1, 1 }
	self.script = [[
--#init

--#render
proc.p.moveAlong()
sprite()
]]
end

function EffectNodeParticleState:buildScript()

	regs = regs or {}

	local iscript, rscript = false, false
	local init,render
	init   = self.initScript and string.trim(self.initScript) or ''
	render = self.renderScript and string.trim(self.renderScript) or ''

	if  init ~= '' then
		local initFunc = loadstring( init )
		if initFunc then iscript = makeParticleScript( initFunc, regs ) end
	end
	if render ~= '' then
		renderFunc = loadstring( render )
		if renderFunc then	rscript = makeParticleScript( renderFunc, regs ) end
	end

	local regCount = 0
	if regs.named then
		for k,r in pairs(regs.named) do
			if r.referred then 
				regCount = math.max( r.number, regCount )
			end
		end
	end

	builtScripts = { iscript, rscript }
	
	local state = MOAIParticleState.new()

	if self.damping  then state:setDamping( self.damping ) end
	if self.mass     then state:setMass( _unpack(self.mass) ) end
	if self.life     then state:setTerm( _unpack(self.life) ) end
		
	if builtScripts[1] then state:setInitScript   ( builtScripts[1] ) end
	if builtScripts[2] then state:setRenderScript ( builtScripts[2] ) end
		
	return state
end

function EffectNodeParticleState:setLife( l1, l2 )
	self.life         = { l1, l2 or l1 }
end

function EffectNodeParticleState:getLife()
	return unpack( self.life )
end



----------------------------------------------------------------------
--CLASS: EffectNodeParticleEmitter
--------------------------------------------------------------------
EffectNodeParticleEmitter :MODEL{
		
}

function EffectNodeParticleEmitter:__init()
end

function EffectNodeParticleEmitter:getDefaultName()
	return 'emitter'
end


----------------------------------------------------------------------
--CLASS: EffectNodeParticleForce
--------------------------------------------------------------------
EffectNodeParticleForce :MODEL{
	Field 'loc'       :type('vec3') :getset('Loc') :label('Loc'); 
	Field 'forceType' :enum( EnumParticleForceType ) :set( 'setForceType' );
}

function EffectNodeParticleForce:__init()
	self.force = MOAIParticleForce.new()
end

function EffectNodeParticleForce:getDefaultName()
	return 'force'
end

function EffectNodeParticleForce:setForceType( t )
	self.force:setType( t )
end

function EffectNodeParticleForce:setLoc( x,y,z )
	self.force:setLoc( x,y,z )
end

function EffectNodeParticleForce:getLoc()
	return self.force:getLoc()
end

--------------------------------------------------------------------
CLASS: EffectNodeAttractorForce ( EffectNodeParticleForce )
	:MODEL{
		Field 'radius';
		Field 'magnitude';
}

function EffectNodeAttractorForce:__init()
	self.radius = 100
	self.magnitude = 1	
end

function EffectNodeAttractorForce:onUpdate()
	self.force:initAttractor( self.radius, self.magnitude )
end

--------------------------------------------------------------------
CLASS: EffectNodeForceBasin ( EffectNodeParticleForce )
	:MODEL{
		Field 'radius';
		Field 'magnitude';
}

function EffectNodeForceBasin:__init()
	self.radius = 100
	self.magnitude = 1	
end

function EffectNodeForceBasin:onUpdate()
	self.force:initBasin( self.radius, self.magnitude )
end

--------------------------------------------------------------------
CLASS: EffectNodeForceLinear ( EffectNodeParticleForce )
	:MODEL{
		Field 'vector'       :type('vec3') :getset('Vector') :label('Loc'); 
}

function EffectNodeForceLinear:__init()
	self.vector = {1,0,0}
end

function EffectNodeForceLinear:setVector( x,y,z )
	self.vector = {x,y,z}
	self:update()	
end

function EffectNodeForceLinear:getVector()
	return unpack( self.vector )
end

function EffectNodeForceLinear:onUpdate()
	self.force:initLinear( unpack( self.vector ) )
end


--------------------------------------------------------------------
CLASS: EffectNodeRadialForce ( EffectNodeParticleForce )
	:MODEL{
		Field 'magnitude';
}

function EffectNodeRadialForce:__init()
	self.magnitude = 1	
end

function EffectNodeRadialForce:onUpdate()
	self.force:initRadial( self.radius, self.magnitude )
end
