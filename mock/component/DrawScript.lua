module 'mock'

CLASS: DrawScript ()
function DrawScript:__init( option )
	local prop = MOAIProp.new()

	-- if option and option.transform then
	-- 	prop:setupTransform( option.transform )
	-- end
	self.prop = prop
	local deck = MOAIScriptDeck.new()
	self.prop:setDeck( deck )	
	self.deck = deck

	if option then
		setupMoaiProp( prop, option )		
	end

	local rect = option and option['rect']
	self:setRect( rect and unpack( rect ) )
end

function DrawScript:setScissorRect( rect )
	return self.prop:setScissorRect( rect )
end

function DrawScript:inside( x,y,z,pad )
	return self.prop:inside( x,y,z,pad )
end

function DrawScript:onAttach( entity )	
	
	if entity.onDraw then
		local onDraw = entity.onDraw
		self.deck:setDrawCallback( 
			function(...) return onDraw(entity, ... ) end
		)
	end

	if entity.onGetRect then
		local onGetRect = entity.onGetRect
		self.deck:setDrawCallback( 
			function(...) return onGetRect(entity, ... ) end
		)
	end
		
	return entity:_attachProp( self.prop )
end

function DrawScript:setRect( x0, y0, x1, y1 )
	if not x0 then
		self.deck:setRect( 10000, 10000, -10000, -10000 ) 
	else
		self.deck:setRect(  x0, y0, x1, y1 )
	end
end

function DrawScript:onDetach( entity )
	entity:_detachProp( self.prop )
end
