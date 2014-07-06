module 'mock'

--------------------------------------------------------------------
--Effect Sub Effect
--------------------------------------------------------------------
CLASS: EffectSubEffect ( EffectTransformNode )
	:MODEL{
		Field 'effect'  :asset('effect');
	}


function EffectSubEffect:onLoad( fxState )
	local parentEmitter = fxState._emitter
	local subEmitter = EffectEmitter()	
	parentEmitter:getEntity():attach( subEmitter )
	subEmitter.actionOnStop = 'detach'
	subEmitter:setEffect( self.effect )
	self:applyTransformToProp( subEmitter )
	fxState:linkTransform( subEmitter.prop )
	--TODO: avoid cyclic effect reference
	local subState = subEmitter:start()
	if subState then
		fxState:attachAction( subState:getTimer() )
		fxState[ self ] = subEmitter
	else
		fxState:removeActiveNode( self )
	end
end

function EffectSubEffect:getDefaultName()
	return 'sub-effect'
end

function EffectSubEffect:getTypeName()
	return 'effect'
end

registerTopEffectNodeType(
	'sub-effect',
	EffectSubEffect,
	EffectCategoryTransform
)

