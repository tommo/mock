module 'mock'

CLASS: TBButton ( TBWidget )
	:MODEL{
		Field 'text' :string() :getset( 'Text' );
	}


function TBButton:createInternalWidget()
	local button = MOAITBButton.new()
	button:setSize( 50, 20 )
	button:setText( 'Submit' )
	return button
end

function TBButton:getText()
	return self:getInternalWidget():getText()
end

function TBButton:setText( text )
	return self:getInternalWidget():setText( text )
end

registerEntity( 'TBButton', TBButton )
