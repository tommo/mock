module 'mock'


--------------------------------------------------------------------
CLASS: UISliderHandle ( UIButton )
	:MODEL{}

function UISliderHandle:onEvent( ev )
	if ev.type == UIEvent.POINTER_MOVE then
		local dx, dy = ev.dx, ev.dy
		self:addLoc( dx, dy )
	end
end

--------------------------------------------------------------------
CLASS: UISliderSlot ( UIButton )
	:MODEL{}

function UISliderSlot:onEvent( ev )
	if ev.type == UIEvent.POINTER_DOWN then
		local x, y = ev.x, ev.y
		local lx, ly = self:worldToModel( x, y )
		local value = self:locToValue( lx, ly )
		self:getParentWidget():setValue( value )
	end
end

function UISliderSlot:locToValue( x, y )
	--TODO
	return 0
end

--------------------------------------------------------------------
CLASS: UISlider ( UIWidget )
	:MODEL{
		Field 'value' :getset( 'Value' );
	}
	:SIGNAL{
		valueChanged = ''
	}

local function EventFilterSliderHandle( handle, ev )
	local etype = ev.type
end

function UISlider:onLoad()
	UISlider.__super.onLoad( self )
	self.slot = self:addInternalChild( UISliderSlot() )
	self.slot:setName( 'slot' )
	self.handle = self:addInternalChild( UISliderHandle() )
	self.handle:setName( 'handle' )

	-- self.slot:addEventFilter( EventFilterSliderSlot )
	-- self.handle:addEventFilter( EventFilterSliderHandle )
	self.slot:setZOrder( 0 )
	self.handle:setZOrder( 1 )

end

function UISlider:getValue()
	return self.value
end

function UISlider:setValue( v )
	local v0 = self.value
	if v0 == v then return end
	self.valueChanged( v, v0 ) --signal
	self:onValueChanged( v, v0 )
end


registerEntity( 'UISlider', UISlider )
