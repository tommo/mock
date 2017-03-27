module 'mock'
--------------------------------------------------------------------
CLASS: UIPointer ()
function UIPointer:__init( view )
	self.view         = view
	self.state        = {}
	self.activeWidget = false
	self.hoverWidget  = false
	self.touch        = false
	self.grabOwner    = false     
end

function UIPointer:getTouch()
	return self.touch
end

function UIPointer:updateHover( view, x, y )
	--find hover
	local hoverWidget0  = self.hoverWidget
	local hoverWidget1 = view:findTopWidget( x, y )
	if hoverWidget0 == hoverWidget1 then return hoverWidget0 end
	self.hoverWidget = hoverWidget1 or false
	if hoverWidget0 then
		local evExit = UIEvent(
			UIEvent.POINTER_EXIT, 
			{ pointer = self }
		)
		view:postEvent( hoverWidget0, evExit )
	end
	if hoverWidget1 then
		local evEnter = UIEvent(
			UIEvent.POINTER_ENTER, 
			{ pointer = self }
		)
		view:postEvent( hoverWidget1, evEnter )
	end
	return hoverWidget1
end

function UIPointer:onMove( view, x, y )
	local activeWidget = self.activeWidget
	if activeWidget then
		local ev = UIEvent(
			UIEvent.POINTER_MOVE, 
			{ x = x, y = y, pointer = self }
		)
		return view:postEvent( activeWidget, ev )
	end
	local hover = self:updateHover( view, x, y )
	if hover then
		local ev = UIEvent(
			UIEvent.POINTER_MOVE, 
			{ x = x, y = y, pointer = self }
		)
		return view:postEvent( hover, ev )
	end
end

function UIPointer:onDown( view, x, y, button )
	button = button or 'left'
	self.state[ button ] = true
	local hover = self:updateHover( view, x, y )
	if hover then
		self.activeWidget = hover
		local ev = UIEvent(
			UIEvent.POINTER_DOWN, 
			{ x = x, y = y, button = button, pointer = self }
		)
		view:postEvent( hover, ev )
	end
end

function UIPointer:onUp( view, x, y, button )
	button = button or 'left'
	self.state[ button ] = false
	local activeWidget = self.activeWidget
	if activeWidget then
		local ev = UIEvent(
			UIEvent.POINTER_UP, 
			{ x = x, y = y, button = button, pointer = self }
		)
		self.activeWidget = false
		view:postEvent( activeWidget, ev )
	end
end
