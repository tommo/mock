module 'mock'

CLASS: EffectScript ( EffectNode )
	:MODEL{
		Field 'script' :string();
	}

function EffectScript:__init()
	self.script = [[
function onUpdate( emitter, dt )
	--update script
end
	]]
	self._onUpdate = false
end

function EffectScript:onBuild()
	local chunk, err = loadstring( self.script )
	if chunk then
		local env = {}
		setfenv( chunk, env )
		chunk()
		self._onUpdate = env.onUpdate
	end
end

function EffectScript:onUpdate( emitter, dt )
	if self._onUpdate then
		return self._onUpdate( emitter, dt )
	end
end

registerEffectNodeType(
	'script',
	EffectScript,
	'*'
)
