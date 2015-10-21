module 'mock'

CLASS: TBContainer ( TBWidget )
	:MODEL{
		Field 'title' :string();
	}

function TBContainer:__init()
	self.title = 'window'
end

function TBContainer:createInternalWidget()
	local window = MOAITBContainer.new()
	window:setSize( 100, 100 )
	window:setText( 'Window' )
	return window
end

registerEntity( 'TBContainer', TBContainer )
