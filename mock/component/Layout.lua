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
-- EnumLayoutType = _ENUM_V{
-- 	'vertical';
-- 	'horizontal';
-- 	'grid';
-- }

CLASS: LayoutItem ( mock.Component )
CLASS: LayoutGroup ( LayoutItem )

---------------------------------------------------------------------
LayoutItem:MODEL{
	Field 'order' :int();
	'----';
	Field 'size' :type('vec2') :getset( 'Size' );
	Field 'margin' ;
	Field 'expandX' :boolean();
	Field 'expandY' :boolean();
}

function LayoutItem:__init()
	self.w, self.h = 100, 100
	self.margin  = 5
	self.expandX = false
	self.expandY = false
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

--------------------------------------------------------------------
CLASS: LayoutFloatItem ( LayoutItem )
	:MODEL{
		Field 'offset' :type('vec2') :getset( 'Offset' );
		Field 'relative' :enum( EnumLayoutRelativeOrigin );
}

function LayoutFloatItem:__init()
	self.relative = 'top-left'
	self.ox = 0
	self.oy = 0
end

function LayoutFloatItem:getOffset()
	return self.ox, self.oy
end

function LayoutFloatItem:setOffset( ox, oy )
	self.ox, self.oy = ox, oy
end

function LayoutFloatItem:getLayoutSize() --not in layout calculation
	return false
end


--------------------------------------------------------------------
LayoutGroup:MODEL{
	'----';
	Field 'spacing';
}
function LayoutGroup:__init()
	self.spacing = 5
	self.expandX = true
	self.expandY = true
end

function LayoutGroup:updateLayout()
end

--------------------------------------------------------------------
CLASS: LayoutHorizontal ( LayoutGroup )
	:MODEL{
		Field 'alignment' :enum( EnumLayoutAlignment );
}

function LayoutHorizontal:updateLayout()
	
end

--------------------------------------------------------------------
CLASS: LayoutVertical ( LayoutGroup )
	:MODEL{
		Field 'alignment' :enum( EnumLayoutAlignment );
}

