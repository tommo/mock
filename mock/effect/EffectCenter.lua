module 'mock'
--------------------------------------------------------------------
CLASS: EffectCenter ( Entity )
	:MODEL{}

registerEntity( 'EffectCenter', EffectCenter )

function EffectCenter:emit( path, options )
	local emitter = EffectEmitter()
	local emitterEntity = options and options.entity or Entity()
	if not getAssetType( path ) == 'effect' then 
		_warn( 'no effect named:', path )
		return
	end
	local parent = options and options.parent or self
	local layer  = options and options.layer
	emitterEntity:attach( emitter )
	parent:addChild( emitterEntity, layer )
	emitter.actionOnStop = 'destroy'
	emitter:setEffect( path )
	if options then
		if options.loc then
			emitter:setLoc( unpack( options.loc ) )
		end
		if options.rot then
			emitter.prop:setRot( 0,0, options.rot )
		end
		
		if options.mirror then
			if options.scl then
				emitter:setScl( - options.scl, options.scl )
			else
				emitter:setSclX( -1 )
			end
		elseif options.scl then
			emitter:setScl( options.scl, options.scl )
		end
		
	end
	emitter:start()
	return emitter, emitterEntity
end

function EffectCenter:emitAt( path, x,y,z, rot )
	return self:emit( path, { loc = {x,y,z}, rot = rot } )
end	

function EffectCenter:clear()
end