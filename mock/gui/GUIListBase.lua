module 'mock'

registerSignals{
	'ui.list.select',	
}

--------------------------------------------------------------------
CLASS: GUIListBase     ( GUIScrollArea )
CLASS: GUIListItemBase ( GUIButtonBase )
--------------------------------------------------------------------


--------------------------------------------------------------------
---List
--------------------------------------------------------------------
function GUIListBase:__init()
	self.selection = false
end

function GUIListBase:onLoad()
	local items = {}
	for i = 0, 20 do
		local item = self:addInternalChild( GUIListItemBase() ):setLoc(0,-85*i)
		table.insert( items, item )
	end
	self:selectItem( items[1] )
end

function GUIListBase:selectItem( item )
	local pitem = self.selection
	self.selection = item
	if pitem then
		pitem.selected = false
		pitem:onDeselect()
	end
	if item then
		item.selected= true
		item:onSelect()
	end	
end

function GUIListBase:getSelection()
	return self.selection
end

--TODO: multiple selection?
-- function GUIListBase:clearSelection()
-- 	--todo
-- end

--------------------------------------------------------------------
---ITEM
--------------------------------------------------------------------
function GUIListItemBase:__init()
	self.selected = false
end

function GUIListItemBase:onPress( pointer, x, y )
	self.dragY0 = y
	self.dragDiff = 0
	if self.parent:isScrolling() then
		self.parent:grabScroll( true )
	else
		self.parent:grabScroll( false )
	end
end

function GUIListItemBase:onDrag( pointer, x, y )
	local dy = y - self.dragY0
	self.dragY0 = y
	self.dragDiff = self.dragDiff + dy
	if not self.parent:isScrollGrabbed() then
		local diff = self.dragDiff 
		if diff*diff > 50 then 
			self.parent:grabScroll( true )
		else
			return
		end
	end
	self.parent:addTargetScrollY( dy )
end

function GUIListItemBase:onRelease( pointer, x, y )
	if self.parent:isScrollGrabbed() then
		self.parent:grabScroll( false )
	else
		self:emit( 'ui.list.select', self.parent, self )
		self.parent:selectItem( self )
	end
end

function GUIListItemBase:onSelect()
end

function GUIListItemBase:onDeselect()
end
