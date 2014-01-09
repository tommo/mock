module 'mock'

CLASS: GUIWidget ( Entity )
	:MODEL{}

function GUIWidget:__init()
	self.__WIDGET     = true
	self.__rootWidget = false
	self.childWidgets = {}

	self:setSize( self:getDefaultSize() ) --default

end

function GUIWidget:_setRootWidget( root )
	if self.__rootWidget == root then return end
	self.__rootWidget = root
	for i, child in ipairs( self.childWidgets ) do
		child:_setRootWidget( root )
	end
end

------Public API

function GUIWidget:addChild( entity, layerName )
	if entity.__WIDGET then
		table.insert( self.childWidgets, entity )
		if self.__rootWidget then
			entity:_setRootWidget( self.__rootWidget )
		end
	end
	return Entity.addChild( self, entity, layerName )	
end

function GUIWidget:destroyNow()
	local parent = self.parent
	local childWidgets = parent and parent.childWidgets
	if childWidgets then
		for i, child in ipairs( self.childWidgets ) do
			if child == self then
				table.remove( i )
				break
			end
		end
	end
	
	Entity.destroyNow( self )
end

--geometry
function GUIWidget:inside( x, y, z, pad )
	x,y = self:worldToModel( x, y )
	local w, h = self:getSize()
	local x0,y0,x1,y1 = 0,0,w,h
	if x0 > x1 then x1,x0 = x0,x1 end
	if y0 > y1 then y1,y0 = y0,y1 end
	if pad then
		return x >= x0-pad and x <= x1+pad and y >= y0-pad and y<=y1+pad
	else
		return x>=x0 and x<=x1 and y>=y0 and y<=y1
	end
end


function GUIWidget:setSize( w, h )
	if not w then
		w, h = self:getDefaultSize()
	end
	self.width, self.height = w, h
	--todo: update layout in the root widget
	-- self:updateLayout()
end

function GUIWidget:getDefaultSize()
	return 0,0
end

function GUIWidget:getSize()
	return self.width, self.height
end

function GUIWidget:setRect( x, y, w, h )
	self.x = x
	self.y = y
end

function GUIWidget:getRect()
	local w, h = self:getSize()
	return 0,0,w,h
end

function GUIWidget:getRootWidget()
	return self.__rootWidget
end

--layout
function GUIWidget:setLayout( l )
	if l then
		assert( not l.widget )
		self.layout = l
		l.widget = self
		self:updateLayout()
		return l
	else
		self.layout = false
	end
end

function GUIWidget:updateLayout()
	if self.layout then
		self.layout:onLayout( self )
	end
end


--Virtual Interfaces

function GUIWidget:onPress( pointer, x, y )
end

function GUIWidget:onRelease( pointer, x, y )
end

function GUIWidget:onDrag( pointer, x, y, dx, dy )
end

function GUIWidget:onSizeHint()
	return 0, 0
end

--------------------------------------------------------------------
CLASS: GUILayout ()
	:MODEL{}
function GUILayout:__init()
	self.widget = false
end

function GUILayout:onLayout( widget )
end

--------------------------------------------------------------------
CLASS: GUIWidgetGroup ( GUIWidget )
	:MODEL{}

function GUIWidgetGroup:inside()
	return 'group'
end


--------------------------------------------------------------------
function registerGUIWidget( name, class )
	registerEntity( '[UI]'..name, class )
end

--------------------------------------------------------------------
registerGUIWidget( 'Group', GUIWidgetGroup )