module 'mock'

EnumListGrowDirection = _ENUM_V {
	'+x','+y','-x','-y'
}

--------------------------------------------------------------------
CLASS: UIListItemDelegate ()
	:MODEL{}

function UIListItemDelegate:__init()

end


--------------------------------------------------------------------
CLASS: UIListItem ()
	:MODEL{
	}

function UIListItem:__init()
	self.delegate = false
end

function UIListItem:setDelegate( delegate )
	self.delegate = delegate
end

--------------------------------------------------------------------
CLASS: UIListView ( UIScrollArea )
	:MODEL{
		Field 'layoutRow' :int() :label('row');
		Field 'layoutCol' :int() :label('column');
		Field 'gridSize' :type( 'vec2' ) :getset( 'GridSize' );
		Field 'growDirection'	 :enum( EnumListGrowDirection );
	}
	:SIGNAL{
		selection_changed = '';
	}

registerEntity( 'UIListView', UIListView )

function UIListView:__init()
	self.selection  = false
	self.items      = {}
	self.gridWidth  = 100
	self.gridHeight = 100
	self.growDirection = '-y'
end

function UIListView:onLoad()
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
	self.selection = item
	if pitem then
		pitem.selected = false
		pitem:onDeselect()
	end
	if item then
		item.selected = true
		item:onSelect()
	end	
	self:onSelectionChanged( self.selection )
end

function UIListView:getSelection()
	return self.selection
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

function UIListView:removeItem( item )
	for i, it in ipairs( self.items ) do
		if it == item then
			table.remove( self.items, i )
			item:destroy()
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
	table.insert( self.items, item )
	local id = #self.items
	local x,y = self:calcItemLoc( id )
	item:setLoc( x, y, 1 )
	return item
end

function UIListView:createItem( option )
	local i = self:addInternalChild( UIListItem() )
	return i
end

function UIListView:getItemId( item )
	for i, it in ipairs( self.items ) do
		if it == item then return i end
	end
	return nil
end

function UIListView:calcItemLoc( id )
	id = id - 1
	local row = math.max( self.layoutRow, 1 )
	local col = math.max( self.layoutCol, 1 )
	local dir = self.growDirection
	local gridWidth = self.gridWidth
	local gridHeight = self.gridHeight
	if dir == '-y' then		
		local y = math.floor( id/col )
		local x = id % col
		return x * gridWidth, - y*gridHeight
	elseif dir == '+y' then
		local y = math.floor( id/col )
		local x = id % col
		return x * gridWidth, y*gridHeight
	elseif dir == '-x' then
		local x = math.floor( id/row )
		local y = id % row 
		return -x * gridWidth, y*gridHeight
	elseif dir == '+x' then
		local x = math.floor( id/row )
		local y = id % row 
		return x * gridWidth, y*gridHeight
	end
end

function UIListView:resetLayout()
	self:resetItemLoc()
end

function UIListView:resetItemLoc()
	for i, item in ipairs( self.items ) do
		item:setLoc( self:calcItemLoc( i ) )
	end
end

function UIListView:onSelectionChanged()
end
