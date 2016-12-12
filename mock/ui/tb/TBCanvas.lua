module 'mock'

--------------------------------------------------------------------
CLASS: TBCanvas ( Entity )
	:MODEL{
		Field 'skin' :asset( 'tb_skin' );
		'----';
		Field "size" :type( 'vec2' ) :getset( 'Size' );

}

function TBCanvas:__init()
	self.mousePos = { false, false }
	self.width  = 400
	self.height = 300

	self.skin = false
	self.canvas = MOAITBCanvas.new()
	self.canvas:setBlendMode( MOAIProp.GL_SRC_ALPHA, MOAIProp.GL_ONE_MINUS_SRC_ALPHA ) 
	self.rootWidget = self.canvas:getRootWidget()

end

function TBCanvas:onLoad()
	self:_attachProp( self.canvas )
end

function TBCanvas:onDestroy()
	self:_detachProp( self.canvas )
end

function TBCanvas:onStart()
	installInputListener( self, {
		category = 'ui',
		sensors = {'joystick', 'mouse', 'keyboard', 'touch' },
	} )

	self.canvas:start()
end

--
function TBCanvas:getSize()
	return self.width, self.height
end

function TBCanvas:refresh()
	self.canvas:getRootWidget():invalidateLayout()
	self.canvas:doStep( 0, 0 )
end

function TBCanvas:setSize( w, h )
	self.width = w
	self.height = h
	return self.canvas:setSize( w, h )
end

function TBCanvas:getRootInternalWidget()
	return self.canvas:getRootWidget()
end

--hook input
local specialKeys = {
	-- ['undefined'] = MOAITBWidget.KEY_UNDEFINED ;
	['up']        = MOAITBWidget.KEY_UP        ;
	['down']      = MOAITBWidget.KEY_DOWN      ;
	['left']      = MOAITBWidget.KEY_LEFT      ;
	['right']     = MOAITBWidget.KEY_RIGHT     ;
	['pageup']    = MOAITBWidget.KEY_PAGE_UP   ;
	['pagedown']  = MOAITBWidget.KEY_PAGE_DOWN ;
	['home']      = MOAITBWidget.KEY_HOME      ;
	['end']       = MOAITBWidget.KEY_END       ;
	['tab']       = MOAITBWidget.KEY_TAB       ;
	['backspace'] = MOAITBWidget.KEY_BACKSPACE ;
	['insert']    = MOAITBWidget.KEY_INSERT    ;
	['delete']    = MOAITBWidget.KEY_DELETE    ;
	['enter']     = MOAITBWidget.KEY_ENTER     ;
	['esc']       = MOAITBWidget.KEY_ESC       ;
	['f1']        = MOAITBWidget.KEY_F1        ;
	['f2']        = MOAITBWidget.KEY_F2        ;
	['f3']        = MOAITBWidget.KEY_F3        ;
	['f4']        = MOAITBWidget.KEY_F4        ;
	['f5']        = MOAITBWidget.KEY_F5        ;
	['f6']        = MOAITBWidget.KEY_F6        ;
	['f7']        = MOAITBWidget.KEY_F7        ;
	['f8']        = MOAITBWidget.KEY_F8        ;
	['f9']        = MOAITBWidget.KEY_F9        ;
	['f10']       = MOAITBWidget.KEY_F10       ;
	['f11']       = MOAITBWidget.KEY_F11       ;
	['f12']       = MOAITBWidget.KEY_F12       ;
}
function TBCanvas:onKeyEvent( key, down )
	local spcode = specialKeys[ key ]
	if spcode then
		return self.rootWidget:sendSpecialKeyEvent( spcode, down )
	else
		if key == 'space' then
			return self.rootWidget:sendKeyEvent( string.byte(' '), down )
		else
			local code = string.byte(key)
			return self.rootWidget:sendKeyEvent( code, down )
		end
	end
end

function TBCanvas:onMouseEvent( ev, x, y, btn, mockup )
	local mx, my = unpack( self.mousePos )
	if ev == 'down' then
		if btn == 'left' then
			return self.rootWidget:sendMouseButtonEvent( 1, true )
		end
	elseif ev == 'up' then
		if btn == 'left' then
			return self.rootWidget:sendMouseButtonEvent( 1, false )
		end
	elseif ev == 'move' then
		x, y = self:wndToModel( x, y )
		y = -y
		local dx, dy
		if mx and my then
			dx = x - mx
			dy = y - my
		else
			dx, dy = 0,0
		end
		self.mousePos = { x, y }
		return self.rootWidget:sendMouseMoveEvent( x, y, dx, dy )
	elseif ev == 'scroll' then
		local dx, dy = x, y
		return self.rootWidget:sendMouseScrollEvent( mx, my, dx, dy )
	end
end

function TBCanvas:onJoyButtonDown( jid, btn )
	local w = MOAITBWidget.getFocusedWidget()
	if btn == 'up' then
		MOAITBWidget.setAutoFocusState( true )
		if w then w:moveFocus( false ) end
	elseif btn == 'down' then
		MOAITBWidget.setAutoFocusState( true )
		if w then w:moveFocus( true ) end
	elseif btn == 'a' then
		if w then
			w:sendSpecialKeyEvent( MOAITBWidget.KEY_ENTER, true )
		end
	end
end

function TBCanvas:onJoyButtonUp( jid, btn )
	if btn == 'a' then
		local w = MOAITBWidget.getFocusedWidget()
		if w then
			w:sendSpecialKeyEvent( MOAITBWidget.KEY_ENTER, false )
		end
	end
end

function TBCanvas:_attachChildEntity( ent )
	if ent.__TBWIDGET then
		return self:attachWidgetEntity( ent )
	end
	return TBCanvas.__super._attachChildEntity( ent )
end

function TBCanvas:attachWidgetEntity( widget )
	local rootTBWidget = self:getRootInternalWidget()
	rootTBWidget:addChild( widget:affirmInternalWidget() )
	self:_attachLoc( widget:getProp() )
	self:refresh()
end

mock.registerEntity( 'TBCanvas', TBCanvas )

