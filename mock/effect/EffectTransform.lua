module 'mock'

CLASS: EffectMove ( EffectNode )
	:MODEL{
		Field 'speed'  :type('vec3') :tuple_getset('speed') :label('speed.move');
	}

function EffectMove:__init()
	self.speed = { 0,0,0 }
end

function EffectMove:getDefaultName()
	return 'move'
end

function EffectMove:getTypeName()
	return 'move'
end

function EffectMove:onLoad( fxState )
	local parent = self.parent
	local trans = parent:getTransformNode( fxState )
	fxState[ self ] = trans
	--assert trans
	fxState:addUpdateListener( self )
end

function EffectMove:onUpdate( fxState, dt )
	local trans = fxState[ self ]
	local speed = self.speed
	trans:addLoc( 
		speed[1] * dt,
		speed[2] * dt,
		speed[3] * dt 
	)
end

--------------------------------------------------------------------
CLASS: EffectRotate ( EffectNode )
	:MODEL{
		Field 'speed'   :type('vec3') :tuple_getset('speed') :label('speed.rotate');
	}

function EffectRotate:__init()
	self.speed = { 0,0,0 }
end

function EffectRotate:getDefaultName()
	return 'rotate'
end

function EffectRotate:getTypeName()
	return 'rotate'
end

function EffectRotate:onLoad( fxState )
	local parent = self.parent
	local trans = parent:getTransformNode( fxState )
	fxState[ self ] = trans
	--assert trans
	fxState:addUpdateListener( self )

end

function EffectRotate:onUpdate( fxState, dt )
	local trans = fxState[ self ]
	local speed = self.speed
	if not trans then return end
	ent:addRot( 
		speed[1] * dt,
		speed[2] * dt,
		speed[3] * dt 
	)
end


-- CLASS: EffectTransform   ( EffectNode )

-- ----------------------------------------------------------------------
-- --CLASS: EffectTransform
-- --------------------------------------------------------------------
-- EffectTransform :MODEL{
-- 	Field 'loc'       :type('vec3') :tuple_getset('loc') :label('Loc'); 
-- 	'----';
-- }

-- function EffectTransform:__init()
-- 	self.forceType = MOAIParticleForce.OFFSET
-- 	self.loc = {0,0,0}
-- end

-- function EffectTransform:getDefaultName()
-- 	return 'force'
-- end

-- function EffectTransform:getTypeName()
-- 	return 'force'
-- end

-- function EffectTransform:buildForce()
-- 	local f = MOAIParticleForce.new()
-- 	f:setLoc( unpack( self.loc ) )
-- 	self:updateForce( f )
-- 	return f
-- end

-- function EffectTransform:updateForce( f )
-- end

--------------------------------------------------------------------
registerTopEffectNodeType(
	'movement',
	EffectMove	
)

registerTopEffectNodeType(
	'rotation',
	EffectRotate	
)
