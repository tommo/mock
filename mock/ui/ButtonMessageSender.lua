CLASS: ButtonMessageSender (mock.Component)
	:MODEL{
		Field 'messageOnClick' :string();
		Field 'sendUpward' :boolean();
	}

mock.registerComponent( 'ButtonMessageSender', ButtonMessageSender )
--mock.registerEntityWithComponent( 'ButtonMessageSender', ButtonMessageSender )
function ButtonMessageSender:__init( ent )
	self.messageOnClick = 'button.clicked'
	self.sendUpward = true
end

function ButtonMessageSender:onStart( ent )
	local button = affirmInstance( ent, 'TBButton' )
	if not button then 
		_warn( 'no button found for messeage redirection' )
		return
	end
	self:connect( button.clicked, 'onButtonClicked' )
end

function ButtonMessageSender:onButtonClicked()
	local ent = self:getEntity()
	ent:tell( self.messageOnClick, self )
	if self.sendUpward then
		local p = ent.parent
		while p do
			p:tell( self.messageOnClick, self )
			p = p.parent
		end
	end
end
