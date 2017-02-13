module 'mock'

local insert = table.insert
local max = math.max

EnumBoxLayoutDirection = _ENUM_V{
	'vertical',
	'horizontal',
}

--------------------------------------------------------------------
CLASS: UIBoxLayout ( UILayout )
	:MODEL{
		Field 'direction' :enum( EnumBoxLayoutDirection ) :getset( 'Direction' );
		Field 'spacing' :getset( 'Spacing' );
	}

function UIBoxLayout:__init()
	self.direction = 'vertical'
	self.spacing = 5
end

function UIBoxLayout:setDirection( dir )
	self.direction = dir
end

function UIBoxLayout:getDirection()
	return self.direction
end

function UIBoxLayout:setSpacing( s )
	self.spacing = s
	self:invalidate()
end

function UIBoxLayout:getSpacing()
	return self.spacing
end

function UIBoxLayout:onUpdate()
	local dir = self.direction
	if dir == 'vertical' then
		return self:updateVertical()
	elseif dir == 'horizontal' then
		return self:updateHorizontal()
	else
		error( 'unknown layout direction: ' .. tostring( dir ) )
	end
end

function UIBoxLayout:updateHorizontal()
	local owner = self:getOwner()
	local info = owner:getLayoutableChildInfo()
	self:calcLayoutHorizontal( info )
	self:applyLayoutHorizontal( info )
end

function UIBoxLayout:updateVertical()
	local owner = self:getOwner()
	local info = owner:getLayoutableChildInfo()
	self:calcLayoutVertical( info )
	self:applyLayoutVertical( info )
end

function UIBoxLayout:applyLayoutVertical( info )
	local spacing = self.spacing
	local marginL, marginT, marginR, marginB = self:getMargin()
	--pos pass
	local y = marginT
	local x = marginL
	for i, entry in ipairs( info ) do
		local widget = entry.widget
		widget:setLoc( x + ( entry.offsetX or 0 ), y + ( entry.offsetY or 0 ) )
		widget:setSize( 
			entry.targetWidth, entry.targetHeight, 
			false, true
		)
		y = y + entry.targetHeight + spacing
	end
end

function UIBoxLayout:calcLayoutVertical( info )
	local count = #info
	if count == 0 then return end

	local spacing = self.spacing
	local marginL, marginT, marginR, marginB = self:getMargin()

	local owner = self:getOwner()
	local availableWidth, availableHeight = self:getAvailableSize()

	availableHeight = availableHeight - spacing * ( count - 1 )
	local minHeightTotal = 0
	local minWidthTotal = 0

	--width pass
	for i, entry in ipairs( info ) do
		minWidthTotal = max( minWidthTotal, entry.minWidth )
		local policy = entry.policyH
		if policy == 'expand' then
			entry.targetWidth = max( availableWidth, entry.minWidth )
			entry.offsetX = 0
		else
			local targetWidth = entry.minWidth
			local alignH = entry.alignH
			if alignH == 'left' then
				entry.offsetX = 0
			elseif alignH == 'center' then
				entry.offsetX = max( availableWidth - targetWidth, 0 )/2
			elseif alignH == 'right' then
				entry.offsetX = max( availableWidth - targetWidth, 0 )
			end
			entry.targetWidth = targetWidth
		end
	end

	--height pass
	for i, entry in ipairs( info ) do
		minHeightTotal = minHeightTotal + entry.minHeight
	end

	--use min height?
	if availableHeight <= minHeightTotal then 
		for i, entry in ipairs( info ) do
			entry.targetHeight = entry.minHeight
		end
		return
	end

	--grow?
	local propAvailHeight = availableHeight --height available for proportional widgets
	local proportional = {}
	local nonproportional = {}
	local fixed = {}
	local totalProportion = 0
	for i, entry in ipairs( info ) do
		if entry.policyV == 'expand' then
			if entry.proportionV > 0 then
				insert( proportional, entry )
				totalProportion = totalProportion + entry.proportionV
			else
				entry.targetHeight = entry.minHeight
				propAvailHeight = propAvailHeight - entry.minHeight
				insert( nonproportional, entry )
			end
		else
			entry.targetHeight = entry.minHeight
			propAvailHeight = propAvailHeight - entry.minHeight
			insert( fixed, entry )
		end
	end

	--no proportional?
	if totalProportion == 0 then
		if next( nonproportional ) then
			local remain = availableHeight - minHeightTotal
			local expand = remain/( #nonproportional )
			for _, entry in ipairs( nonproportional ) do
				entry.targetHeight = entry.minHeight + expand
			end
		end
		return
	end

	--proportional	
	--find non-fits
	while true do
		local proportional2 = {}
		local heightUnit = propAvailHeight / totalProportion
		totalProportion = 0
		for _, entry in ipairs( proportional ) do
			local targetHeight = entry.proportionV * heightUnit
			if targetHeight < entry.minHeight then
				entry.targetHeight = entry.minHeight
				propAvailHeight = propAvailHeight - entry.minHeight
			else
				entry.targetHeight = targetHeight
				totalProportion = totalProportion + entry.proportionV
				insert( proportional2, entry )
			end
		end
		if #proportional == #proportional2 then break end --no nonfits anymore
		proportional = proportional2
	end
end

function UIBoxLayout:applyLayoutHorizontal( info )
	local spacing = self.spacing
	local marginL, marginT, marginR, marginB = self:getMargin()
	--pos pass
	local y = marginT
	local x = marginL
	for i, entry in ipairs( info ) do
		local widget = entry.widget
		widget:setLoc( x + ( entry.offsetX or 0 ), y + ( entry.offsetY or 0 ) )
		widget:setSize( 
			entry.targetWidth, entry.targetHeight, 
			false, true
		)
		x = x + entry.targetWidth + spacing
	end
end

function UIBoxLayout:calcLayoutHorizontal( info )
	local count = #info
	if count == 0 then return end

	local spacing = self.spacing
	local marginL, marginT, marginR, marginB = self:getMargin()

	local owner = self:getOwner()
	local availableWidth, availableHeight = self:getAvailableSize()

	availableWidth  = availableWidth - spacing * ( count - 1 )

	local minWidthTotal = 0
	local minHeightTotal = 0

	--height pass
	for i, entry in ipairs( info ) do
		minHeightTotal = max( minHeightTotal, entry.minHeight )
		local policy = entry.policyH
		if policy == 'expand' then
			entry.targetHeight = max( availableHeight, entry.minHeight )
			entry.offsetY = 0
		else
			local targetHeight = entry.minHeight
			local alignH = entry.alignH
			if alignH == 'top' then
				entry.offsetY = 0
			elseif alignH == 'center' then
				entry.offsetY = max( availableHeight - targetHeight, 0 )/2
			elseif alignH == 'bottom' then
				entry.offsetY = max( availableHeight - targetHeight, 0 )
			end
			entry.targetHeight = targetHeight
		end
	end

	--width pass
	for i, entry in ipairs( info ) do
		minWidthTotal = minWidthTotal + entry.minWidth
	end

	--use min iwdth?
	if availableWidth <= minWidthTotal then 
		for i, entry in ipairs( info ) do
			entry.targetWidth = entry.minWidth
		end
		return
	end

	--grow?
	local propAvailWidth = availableWidth --Width available for proportional widgets
	local proportional = {}
	local nonproportional = {}
	local fixed = {}
	local totalProportion = 0
	for i, entry in ipairs( info ) do
		if entry.policyV == 'expand' then
			if entry.proportionV > 0 then
				insert( proportional, entry )
				totalProportion = totalProportion + entry.proportionV
			else
				entry.targetWidth = entry.minWidth
				propAvailWidth = propAvailWidth - entry.minWidth
				insert( nonproportional, entry )
			end
		else
			entry.targetWidth = entry.minWidth
			propAvailWidth = propAvailWidth - entry.minWidth
			insert( fixed, entry )
		end
	end

	--no proportional?
	if totalProportion == 0 then
		if next( nonproportional ) then
			local remain = availableWidth - minWidthTotal
			local expand = remain/( #nonproportional )
			for _, entry in ipairs( nonproportional ) do
				entry.targetWidth = entry.minWidth + expand
			end
		end
		return
	end

	--proportional	
	--find non-fits
	while true do
		local proportional2 = {}
		local widthUnit = propAvailWidth / totalProportion
		totalProportion = 0
		for _, entry in ipairs( proportional ) do
			local targetWidth = entry.proportionV * widthUnit
			if targetWidth < entry.minWidth then
				entry.targetWidth = entry.minWidth
				propAvailWidth = propAvailWidth - entry.minWidth
			else
				entry.targetWidth = targetWidth
				totalProportion = totalProportion + entry.proportionV
				insert( proportional2, entry )
			end
		end
		if #proportional == #proportional2 then break end --no nonfits anymore
		proportional = proportional2
	end
end

--------------------------------------------------------------------

CLASS: UIHBoxLayout ( UIBoxLayout )
	:MODEL{
		Field 'direction' :no_edit();
	}

function UIHBoxLayout:__init()
	self:setDirection( 'horizontal' )
end

function UIHBoxLayout:setDirection( dir )
	return UIHBoxLayout.__super.setDirection( self, 'horizontal' )
end

registerComponent( 'UIHBoxLayout', UIHBoxLayout )

--------------------------------------------------------------------

CLASS: UIVBoxLayout ( UIBoxLayout )
	:MODEL{
		Field 'direction' :no_edit();
	}

function UIVBoxLayout:__init()
	self:setDirection( 'vertical' )
end

function UIVBoxLayout:setDirection( dir )
	return UIVBoxLayout.__super.setDirection( self, 'vertical' )
end

registerComponent( 'UIVBoxLayout', UIVBoxLayout )
