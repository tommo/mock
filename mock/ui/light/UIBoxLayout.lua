module 'mock'

--------------------------------------------------------------------
CLASS: UIBoxLayout ( UILayout )
	:MODEL{}

function UIBoxLayout:__init()
	self.direction = 'vertical'
	self.margin = { 0,0,0,0 }
	self.spacing = 1
end

function UIBoxLayout:setDirection( dir )
	self.direction = dir
end

function UIBoxLayout:getDirection()
	return self.direction
end

function UIBoxLayout:setSpacing( s )
	self.spacing = s
end

function UIBoxLayout:getMargin()
	return unpack( self.margin )
end

function UIBoxLayout:setMargin( left, top, right, bottom )
	self.margin = { left or 0, top or 0, right or 0, bottom or 0 }
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

end

function UIBoxLayout:updateVertical()
	local owner = self:getOwner()
	local spacing = self.spacing
	local marginL, marginT, marginR, marginB = self:getMargin()
	--size pass
	-- local minHeight = owner:getMinHeight()
	local availableWidth, availableHeight = owner:getSize()
	availableWidth  = availableWidth  - marginL - marginR
	availableHeight = availableHeight - marginT - marginB

	local minHeight = 0
	local targetHeight = 0
	local info = owner:getLayoutingChildInfo()
	local result = {}
	for i, entry in ipairs( info ) do
		minHeight    = minHeight + entry.minH + spacing
		targetHeight = targetHeight + entry.hintH + spacing
	end

	if minHeight > availableHeight then --use min height
		for i, widget in ipairs( info ) do
		end
	else
		if targetHeight < availableHeight then --grow
			local remain = availableHeight - targetHeight
			for i, widget in ipairs( owner:getChildWidgets() ) do
				widget:setHeight()
			end
		elseif targetHeight > availableHeight then
		end
	end

	--pos pass
	local y = marginT
	-- for i, entry in ipairs( info ) do
	-- end
end


--------------------------------------------------------------------

CLASS: UIHBoxLayout ( UIBoxLayout )
	:MODEL{}

function UIHBoxLayout:__init()
	self:setDirection( 'horizontal' )
end

function UIHBoxLayout:setDirection( dir )
	return UIHBoxLayout.__super.setDirection( 'horizontal' )
end


--------------------------------------------------------------------

CLASS: UIVBoxLayout ( UIBoxLayout )
	:MODEL{}

function UIVBoxLayout:__init()
	self:setDirection( 'vertical' )
end

function UIVBoxLayout:setDirection( dir )
	return UIVBoxLayout.__super.setDirection( 'vertical' )
end
