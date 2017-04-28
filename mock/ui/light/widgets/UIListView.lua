module 'mock'

EnumListGrowDirection = _ENUM_V {
	'+x','+y','-x','-y'
}

-------------------------------------------------------------------
CLASS: UIListItem ( UIButton )
	:MODEL{
	}

function UIListItem:__init()
	self.selected = false
	self.selectable = true
end

function UIListItem:isSelected()
	return self.selected
end

function UIListItem:getListView()
	return self:findParentWidgetOf( UIListView )
end

function UIListItem:setSelected( selected )
	return self:getListView():selectItem( self )
end

function UIListItem:onPressed()
	self:getListView():setFocus()
	self:getListView():selectItem( self )
end

function UIListItem:onDeselect()
end

function UIListItem:onSelect()
end

function UIListItem:updateStyleState()
	if self.selected then
		return self:setState( 'selected' )
	end
	return UIListItem.__super.updateStyleState( self )
end

--------------------------------------------------------------------
CLASS: UIListView ( UIWidget )
	:MODEL{
		Field 'layoutRow' :int() :label('row');
		Field 'layoutCol' :int() :label('column');
		Field 'gridSize' :type( 'vec2' ) :getset( 'GridSize' );
		Field 'growDirection'	 :enum( EnumListGrowDirection ) :onset( 'resetLayout' );
	}
	:SIGNAL{
		selection_changed = 'onSelectionChanged';
		item_activated = 'onItemActivated';
	}

registerEntity( 'UIListView', UIListView )

function UIListView:__init()
	self.selection  = false
	self.items      = {}
	self.gridWidth  = 100
	self.gridHeight = 100
	self.growDirection = '-y'
	self.layoutRow = 5
	self.layoutCol = 5
	self.frame = UIScrollArea()
end

function UIListView:onLoad()
	UIListView.__super.onLoad( self )
	self:addInternalChild( self.frame )
end

function UIListView:setGridSize( w, h )
	self.gridWidth = w
	self.gridHeight = h
	self:resetLayout()
end

function UIListView:getGridSize()
	return self.gridWidth, self.gridHeight
end

function UIListView:selectItem( item )
	local pitem = self.selection
	if pitem == item then return end

	if item then
		if not item.selectable then
			_warn( 'item not selectable' )
			return false
		end
		if item:getListView() ~= self then
			_warn( 'item doesnt belong to the list' )
			return false
		end	
	end
	self.selection = item
	if pitem then
		pitem.selected = false
		pitem:onDeselect()
		pitem:updateStyleState()
	end

	if item then
		item.selected = true
		item:onSelect()
		item:updateStyleState()
	end	
	self.selection_changed:emit( self.selection )
	return
end

function UIListView:getSelection()
	return self.selection
end

function UIListView:activateItem( item )
	if self.selection ~= item then
		if self:selectItem( item ) == false then
			return false
		end
	end
	assert( self.selection == item )
	self.item_activated:emit( self.selection )
end

function UIListView:clear()
	self:selectItem( false )
	for i, item in ipairs( self.items ) do
		item:destroy()		
	end
	self.items = {}
end

function UIListView:getItemCount()
	return #self.items
end

function UIListView:getItem( idx )
	return self.items[ idx ]
end

function UIListView:removeItem( item )
	if self.selection == item then
		self:selectItem( false )
	end
	for i, it in ipairs( self.items ) do
		if it == item then
			table.remove( self.items, i )
			item:destroyAllNow()
			break
		end
	end
	self:resetItemLoc()
end

function UIListView:sortItems( cmpFunc )
	table.sort( self.items, cmpFunc )
	self:resetItemLoc()
end

function UIListView:addItem( option )
	local item = self:createItem( option )
	self.frame:addInternalChild( item )
	table.insert( self.items, item )
	local id = #self.items
	local x,y = self:calcItemLoc( id )
	item:setLoc( x, y, 1 )
	return item
end

function UIListView:createItem( option )
	return UIListItem()
end

function UIListView:createEmptyItem()
	local item = UIListItem()
	item.selectable = false
	return item
end

function UIListView:getItemId( item )
	for i, it in ipairs( self.items ) do
		if it == item then return i end
	end
	return nil
end

function UIListView:getItemGridLoc( item )
	local id = self:getItemId( item )
	if not id then return nil end
	return self:calcGridLoc( id )
end

function UIListView:calcItemLoc( id )
	local x, y = self:calcGridLoc( id )
	local gridWidth = self.gridWidth
	local gridHeight = self.gridHeight
	return x * gridWidth, y*gridHeight
end

function UIListView:getItemAtGridLoc( x, y )
	local id = self:calcGridId( x, y )
	if not id then return nil end
	return self.items[ id ]	
end

function UIListView:calcGridLoc( id )
	id = id - 1
	local row = math.max( self.layoutRow, 1 )
	local col = math.max( self.layoutCol, 1 )
	local dir = self.growDirection
	if dir == '-y' then		
		local y = math.floor( id/col )
		local x = id % col
		return x, -y
	elseif dir == '+y' then
		local y = math.floor( id/col )
		local x = id % col
		return x, y
	elseif dir == '-x' then
		local x = math.floor( id/row )
		local y = id % row 
		return -x, y
	elseif dir == '+x' then
		local x = math.floor( id/row )
		local y = id % row 
		return x, y
	end
end

function UIListView:calcGridId( x, y )
	local row = math.max( self.layoutRow, 1 )
	local col = math.max( self.layoutCol, 1 )
	-- if x < 1 or x > col then return false end
	-- if y < 1 or y > row then return false end
	local id
	local dir = self.growDirection
	if dir == '-y' then
		y = -y
		id = y * col + x + 1

	elseif dir == '+y' then
		id = y * col + x + 1

	elseif dir == '-x' then
		x = -x
		id = x * row + y + 1

	elseif dir == '+x' then
		id = x * row + y + 1

	end
	if x < 0 or x >= col then return false end
	if y < 0 or y >= row then return false end
	return id
end

function UIListView:resetLayout()
	local w, h = self:getSize()
	local gridWidth = self.gridWidth
	local gridHeight = self.gridHeight
	if self.growDirection == '-y' then
		self.frame.innerTransform:setPiv( 0, -h )
	elseif self.growDirection == '+y' then
		self.frame.innerTransform:setPiv( 0, -gridHeight )
	elseif self.growDirection == '-x' then
		self.frame.innerTransform:setPiv( -w, 0 )
	end
	self:resetItemLoc()
end

function UIListView:resetItemLoc()
	for i, item in ipairs( self.items ) do
		item:setLoc( self:calcItemLoc( i ) )
	end
end

function UIListView:onSelectionChanged()
end

function UIListView:onItemActivated( item )
end

function UIListView:setSize( w, h, ... )
	UIListView.__super.setSize( self, w,h, ... )
	self.frame:setSize( w, h, ... )
end

function UIListView:procEvent( ev )
	local etype = ev.type
	if etype == UIEvent.FOCUS_IN then
		if not self.selection then
			local first = self:getItem( 1 )
			if first then
				self:selectItem( first )
			end
		end
	elseif etype == UIEvent.FOCUS_OUT then
	end
	return UIListView.__super.procEvent( self, ev )
end
