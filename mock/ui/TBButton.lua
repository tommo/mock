module 'mock'

CLASS: TBButton ( TBWidget )
	:MODEL{
		Field 'text' :string() :getset( 'Text' );
	}
	:SIGNAL{
		clicked = ''
	}

function TBButton:createInternalWidget()
	local button = MOAITBButton.new()
	button:setSize( 50, 20 )
	button:setText( 'Button' )
	return button
end

function TBButton:getText()
	return self:getInternalWidget():getText()
end

function TBButton:setText( text )
	return self:getInternalWidget():setText( text )
end

function TBButton:onWidgetEvent( etype, widget, event )
	if etype == MOAITBWidgetEvent.EVENT_TYPE_CLICK then
		return self:clicked()
	end
end

registerEntity( 'TBButton', TBButton )
