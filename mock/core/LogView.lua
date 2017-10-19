module 'mock'

CLASS: LogViewManager ( GlobalManager )

function LogViewManager:__init()
	self.lineCount = 0
	self.lines = {}
	self.enabled = true
end

function LogViewManager:getKey()
	return 'LogViewManager'
end

function LogViewManager:init()
	connectGlobalSignalMethod( 'device.resize', self, 'onDeviceResize' )
	local layer = MOAILayer.new()
	local viewport = MOAIViewport.new ()
	layer:setViewport( viewport )
	self.viewport = viewport

	local textBox = MOAITextLabel.new()
	textBox:setStyle( getFallbackTextStyle() )
	textBox:setYFlip( true )
	textBox:setAlignment( MOAITextLabel.LEFT_JUSTIFY, MOAITextLabel.BOTTOM_JUSTIFY )
	textBox:setRectLimits( false, false )

	self.textBox = textBox
	self.text = ''
	self.renderLayer = layer 

	layer:insertProp( textBox )
	local renderCommand = MOAIFrameBufferRenderCommand.new()
	renderCommand:setClearColor()
	renderCommand:setFrameBuffer( MOAIGfxDevice.getFrameBuffer() )
	renderCommand:setRenderTable( {
		layer
	} )
	self.renderCommand = renderCommand
	self.textBox:setText( '' )
	self:updateViewport()

	addLogListener( function( ... )
			return self:onLog( ... )
		end
	)

end

function LogViewManager:setEnabled( enabled )
	enabled = enabled~=false
	self.enabled = enabled
	self.renderLayer:setVisible( enabled )
end

function LogViewManager:isEnabled()
	return self.enabled
end

function LogViewManager:clear()
	self.lines = {}
	self.textBox:setText( '' )
end

function LogViewManager:updateViewport()
	local w, h = game:getDeviceResolution()
	self.viewport:setSize ( w,h )
	self.viewport:setScale ( w,h )
	self.textBox:setLoc( -w/2 + 5, -h/2 + 5 )
end

function LogViewManager:onDeviceResize( w, h )
	self:updateViewport()
end

function LogViewManager:getRenderCommand()
	return self.renderCommand
end

function LogViewManager:_insertLine( l, color )
	if color then
		l = string.format( '<c:%s>%s</>', color, l )
	end

	local lines = self.lines
	table.insert( lines, l )
	local count = #lines
	if count > 10 then
		table.remove( lines, 1 )
	end
	self.textBox:setText( string.join( lines, '\n' ) )
end

function LogViewManager:onLog( token, msg, text )
	if token:startwith( 'ERROR' ) then
		self:_insertLine( msg, 'f00' )
	elseif token:startwith( 'WARN' ) then
		self:_insertLine( msg, 'fa0' )
	end
end

--------------------------------------------------------------------
local _logViewManager = LogViewManager()
function getLogViewManager()
	return _logViewManager
end
