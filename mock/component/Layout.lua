module 'mock'

EnumLayoutAlignment  = _ENUM_V{
	'left',
	'center',
	'right',
}

EnumLayoutAlignmentV = _ENUM_V{
	'top',
	'center',
	'bottom',
}


EnumLayoutRelativeOrigin = _ENUM_V{
	'center';
	'top-left';
	'top-right';
	'top-center';
	'bottom-left';
	'bottom-right';
	'bottom-center';
	'middle-left';
	'middle-right';
}

EnumSizePolicy = _ENUM_V{
	'normal',
	'expand',
	'fit',
}

local function _sortLayoutItem( i1, i2 )

	local o1 = i1.order
	local o2 = i2.order
	if o1 == o2 then
		local e1, e2  = i1._entity, i2._entity
		return e1 and e2 and e1.name < e2.name or false
	else
		return o1 < o2
	end
end

--------------------------------------------------------------------
--------------------------------------------------------------------

---------------------------------------------------------------------
CLASS: LayoutItem ( mock.Component )
	:MODEL{
		Field 'order' :int();
		'----';
		Field 'size' :type('vec2') :getset( 'Size' );
		Field 'margin' ;
		Field 'policyH' :enum( EnumSizePolicy );
		Field 'policyV' :enum( EnumSizePolicy );
	}

function LayoutItem:__init()
	self.w, self.h = 100, 100
	self.order   = 1
	self.margin  = 5
	self.policyH = 'normal'
	self.policyV = 'normal'
end

function LayoutItem:getSize()
	return self.w, self.h
end

function LayoutItem:setSize( w, h )
	self.w, self.h = w, h
end

function LayoutItem:getLayoutSize()
	local w,h = self:getSize()
	return w + self.margin*2, h + self.margin*2
end

function LayoutItem:setLayoutLoc( x, y )
	local ent = self._entity
	ent:setLocX( x )
	ent:setLocY( y )
end

function LayoutItem:updateLayout()
end

--------------------------------------------------------------------
CLASS: LayoutFloatPin ( LayoutItem )
	:MODEL {
		Field 'offset' :type('vec2') :getset( 'Offset' );
		Field 'relative' :enum( EnumLayoutRelativeOrigin );
}

function LayoutFloatPin:__init()
	self.relative = 'top-left'
	self.ox = 0
	self.oy = 0
end

function LayoutFloatPin:getOffset()
	return self.ox, self.oy
end

function LayoutFloatPin:setOffset( ox, oy )
	self.ox, self.oy = ox, oy
end

function LayoutFloatPin:getLayoutSize() --not in layout calculation
	return false
end

function LayoutFloatPin:updateLayout()
end

--------------------------------------------------------------------
CLASS: LayoutScreenPin ( LayoutItem )
	:MODEL{
		Field 'refCamera' :type( Camera );
	}

function LayoutScreenPin:__init()
	self.refCamera = false	
end


--------------------------------------------------------------------
CLASS: LayoutGroup ( LayoutItem )

LayoutGroup:MODEL{
	'----';
	Field 'spacing';
	Field 'refreshLayout' :action('refreshLayout');
}
function LayoutGroup:__init()
	self.spacing = 5
	self.policyH = 'expand'
	self.policyV = 'expand'
end

function LayoutGroup:getChildrenList()
	local l = {}
	local i = 1 	
	local ent = self._entity
	for c in pairs( ent.children ) do
		local item = c:getComponent( LayoutItem )
		if item then
			l[i] = item
			i = i + 1
		end
	end
	table.sort( l, _sortLayoutItem )
	return l
end

function LayoutGroup:refreshLayout()
	self:updateLayout()
end

--------------------------------------------------------------------
CLASS: LayoutHorizontalGroup ( LayoutGroup )
	:MODEL{
		Field 'alignment' :enum( EnumLayoutAlignment );
}

function LayoutHorizontalGroup:updateLayout()
	local children = self:getChildrenList()
	local spacing = self.spacing
	local x = 0
	local y = 0 --TODO
	for i, ch in ipairs( children ) do
		x = x + spacing
		ch:setLayoutLoc( x,y )
		local w, h = ch:getLayoutSize()
		x = x + w
		x = x + spacing
	end
end

--------------------------------------------------------------------
CLASS: LayoutVerticalGroup ( LayoutGroup )
	:MODEL{
		Field 'alignment' :enum( EnumLayoutAlignment );
}

function LayoutVerticalGroup:updateLayout()
	local children = self:getChildrenList()
	local spacing = self.spacing
	local x = 0 --TODO
	local y = 0 
	for i, ch in ipairs( children ) do
		local itemCom = ch:getComponent( LayoutItem )
		if itemCom then
			y = y + spacing
			local w, h = itemCom:getLayoutSize()
			itemCom:setLayoutLoc( x,y )
			y = y + h
			y = y + spacing
		end
	end
end

--------------------------------------------------------------------
-- CLASS: LayoutGridGroup ( LayoutGroup )
-- 	:MODEL{}
-- --TODO


registerComponent( 'LayoutItem', LayoutItem )
registerComponent( 'LayoutScreenPin', LayoutScreenPin )
registerComponent( 'LayoutHorizontalGroup', LayoutHorizontalGroup )
registerComponent( 'LayoutVerticalGroup', LayoutVerticalGroup )
-- registerComponent( 'LayoutGridGroup', LayoutGridGroup )
