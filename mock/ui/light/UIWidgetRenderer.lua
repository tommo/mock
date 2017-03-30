module 'mock'


--------------------------------------------------------------------
CLASS: UIWidgetRenderer ()
	:MODEL{}

function UIWidgetRenderer:__init()
	self.widget = false
	self.options = {}
	self.elements = {}
end

function UIWidgetRenderer:addElement( element )
	assert( element )
	table.insert( self.elements, element )
	element.owner = self
	return element
end

function UIWidgetRenderer:setOptions( options )
	local options0 = self.options
	for k, v in pairs( options ) do
		options0[ k ] = v
	end
end

function UIWidgetRenderer:setOption( k, v )
	self.options[ k ] = v
end

function UIWidgetRenderer:getOption( k, default )
	local v = self.options[ k ]
	if v == nil then return default end
	return v
end

function UIWidgetRenderer:getWidget()
	return self.widget
end

function UIWidgetRenderer:init( widget )
	assert( not self.widget )
	self.widget = widget
	self:onInit( widget, self.options )
	for i, element in ipairs( self.elements ) do
		element:onInit( widget )
	end
end

function UIWidgetRenderer:onInit( widget )
end

function UIWidgetRenderer:update( widget, style, updateStyle, updateContent )
	local elements = self.elements
	if updateContent then
		self:onUpdateContent( widget, style )
		for i, element in ipairs( elements ) do
			element:onUpdateContent( widget, style )
		end
	end
	if updateStyle then
		self:updateCommonStyle( widget, style )
		self:onUpdateStyle( widget, style )
		for i, element in ipairs( elements ) do
			element:onUpdateStyle( widget, style )
		end
	end
	self:onUpdateSize( widget, style )
	for i, element in ipairs( elements ) do
		element:onUpdateSize( widget, style )
	end
end

function UIWidgetRenderer:destroy( widget )
	self:onDestroy( widget )
	for i, element in ipairs( self.elements ) do
		element:onDestroy( widget )
	end
	self.elements = {}
end

function UIWidgetRenderer:updateCommonStyle( widget, style )
	local color = { style:getColor( 'color', { 1,1,1,1 } ) }
	local alpha = style:getNumber( 'alpha', nil )
	if alpha then
		color[ 4 ] = alpha
	end
	widget:setColor( unpack( color ) )
end

function UIWidgetRenderer:onUpdateContent( widget, style )
end

function UIWidgetRenderer:onUpdateSize( widget, style )
end

function UIWidgetRenderer:onUpdateStyle( widget, style )
end

function UIWidgetRenderer:onDestroy( widget )
end
