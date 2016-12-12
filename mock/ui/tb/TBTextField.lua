module 'mock'

CLASS: TBTextField ( TBWidget )
	:MODEL{
		Field 'text' :string() :getset( 'Text' );
	}

function TBTextField:createInternalWidget()
	local textField = MOAITBTextField.new()
	textField:setSize( 50, 20 )
	textField:setText( 'Submit' )
	return textField
end

function TBTextField:getText()
	return self:getInternalWidget():getText()
end

function TBTextField:setText( text )
	return self:getInternalWidget():setText( text )
end

registerEntity( 'TBTextField', TBTextField )
