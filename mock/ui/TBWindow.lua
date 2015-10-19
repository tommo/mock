module 'mock'

CLASS: TBWindow ( TBWidget )
	:MODEL{
		Field 'title' :string();
	}

function TBWindow:__init()
	self.title = 'window'
end

function TBWindow:createInternalWidget()
	local window = MOAITBWindow.new()
	window:setSize( 100, 100 )
	window:setText( 'Window' )
	window:resizeToFitContent()
	return window
end

registerEntity( 'TBWindow', TBWindow )
