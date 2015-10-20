module 'mock'

CLASS: TBLayout ( TBWidget )
	:MODEL{
		Field 'loc' :type('vec2') :no_edit();
	}

function TBLayout:__init()
end

function TBLayout:setLoc( x, y )
	--DO nothing
end

-- function TBLayout:setSize( w, h )
-- 	--DO nothing
-- end

function TBLayout:createInternalWidget()
	local layout = MOAITBLayout.new()
	layout:setAxis( MOAITBWidget.AXIS_Y )
	layout:setGravity(MOAITBWidget.WIDGET_GRAVITY_ALL)
	return layout
end

function TBLayout:onAttachToParent( parent )
	self:setRect( parent:getPaddingRect() )
end

function TBLayout:isLayouting()
	return true
end


registerEntity( 'TBLayout', TBLayout )
