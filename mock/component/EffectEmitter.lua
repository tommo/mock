module 'mock'

CLASS: EffectEmitter ( Component )
	:MODEL{
		Field 'effect' :asset('effect') :set('setEffect');
		Field 'autoPlay' :boolean();
}

function EffectEmitter:__init()
	self.effect     = false
	self.autoPlay   = true
	self.effectConfig = false
	self.prop       = MOAIProp.new()
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

function EffectEmitter:onAttach( ent )
	ent:_attachProp( self.prop )
end

function EffectEmitter:onDetach( ent )
	ent:_detachProp( self.prop )
end

function EffectEmitter:onStart()
	if self.autoPlay then
		self:start()
	end
end

function EffectEmitter:start()
	if not self.effectConfig then return end
	self.effectConfig:loadIntoEmitter( self )
end

