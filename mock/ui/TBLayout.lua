module 'mock'

CLASS: TBLayout ( TBWidget )
	:MODEL{
	}

function TBLayout:__init()
end

function TBLayout:createInternalWidget()
	local layout = MOAITBLayout.new()
	layout:setSize( 100, 100 )
	layout:setAxis( MOAITBWidget.AXIS_Y )
	layout:setGravity(MOAITBWidget.WIDGET_GRAVITY_LEFT + MOAITBWidget.WIDGET_GRAVITY_RIGHT);
	return layout
end


registerEntity( 'TBLayout', TBLayout )
