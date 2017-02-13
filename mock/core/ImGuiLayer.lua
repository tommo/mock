module 'mock'

CLASS: ImGuiLayer ()
	:MODEL{}

function ImGuiLayer:__init()
	self.imgui = MOAIImGui.new()
	self.imgui:setScl( 1, -1, 1 )
	self.imgui:setSize( 1280, 720 )
	self.imgui:setLoc( -640, 360 )

	self.imguiLayer = MOAILayer.new()
	self.imguiLayer:insertProp( self.imgui )
	
	local renderCommand = MOAIFrameBufferRenderCommand.new()
	renderCommand:setClearColor()
	renderCommand:setFrameBuffer( MOAIGfxDevice.getFrameBuffer() )
	renderCommand:setRenderTable( { self.imguiLayer } )

	self.renderCommand = renderCommand
end

function ImGuiLayer:init( inputCategory )
	self.imgui:init()
	installInputListener( self, { category = inputCategory or 'imgui' } )
end

function ImGuiLayer:setVisible( vis )
	self.imguiLayer:setVisible( vis )
end

function ImGuiLayer:getRenderCommand()
	return self.renderCommand
end

function ImGuiLayer:setViewport( vp )
	self.imguiLayer:setViewport( vp )
end

function ImGuiLayer:setSize( w, h )
	self.imgui:setSize( w, h )
end

function ImGuiLayer:getMoaiLayer()
	return self.imguiLayer
end

function ImGuiLayer:setCallback( callback )
	self.imgui:setCallback( callback )
end

local btnNameToId = {
	left = 0,
	middle = 2,
	right = 1,
}


function ImGuiLayer:onMouseEvent ( ev, x, y, btn, mock )
	local gui = self.imgui
	local layer = self.imguiLayer
	if ev == 'down' then
		gui:sendMouseButtonEvent( btnNameToId[ btn ] or -1, true )
	elseif ev == 'up' then
		gui:sendMouseButtonEvent( btnNameToId[ btn ] or -1, false )
	elseif ev == 'move' then
		x, y = layer:wndToWorld( x, y )
		x, y = gui:worldToModel( x, y )
		return gui:sendMouseMoveEvent( x, y )
	elseif ev == 'scroll' then
		-- print( y )
		return gui:sendMouseWheelEvent( y*0.1 )
	end
end

local key2ImguiKey = {
	[ 'tab'      ] = MOAIImGui.Key_Tab,
	[ 'left'     ] = MOAIImGui.Key_LeftArrow,
	[ 'right'    ] = MOAIImGui.Key_RightArrow,
	[ 'up'       ] = MOAIImGui.Key_UpArrow,
	[ 'down'     ] = MOAIImGui.Key_DownArrow,
	[ 'pageup'   ] = MOAIImGui.Key_PageUp,
	[ 'pagedown' ] = MOAIImGui.Key_PageDown,
	[ 'home'     ] = MOAIImGui.Key_Home
}

local key2Text = {
	[ 'space' ] = ' ';
	[ 'tab' ] = '\t';
}

function ImGuiLayer:onKeyEvent( key, down )
	local code = key2ImguiKey[ key ]
	if code then
		print( code )
		return self.imgui:sendKeyEvent( code, down )
	elseif down then
		--FIXME: this is just a quick workaround, use text input event from host instead
		if key:match( '^[%w%.%-=\\,/]$') then
			if isShiftDown() then
				return self.imgui:sendTextEvent( key:upper() )
			else
				return self.imgui:sendTextEvent( key )
			end
		end
		local t = key2Text[ key ]
		if t then
			return self.imgui:sendTextEvent( t )
		end
	end
end
