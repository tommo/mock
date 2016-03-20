module 'mock'

CLASS: Palette ()
	:MODEL{}

function Palette:__init()
	self.name = 'Palette'
	self.colorList  = {}
	self.colorTable = {}
end

function Palette:getColor( name )
	return unpack( self.colorTable[ name ] )
end

function Palette:setColor( name, r,g,b,a )
	local c = self.colorTable[ name ]
	if c then
		c[1] = r
		c[2] = g
		c[3] = b
		c[4] = a
	else
		self:addColor( name, r,g,b,a )
	end
end

function Palette:addColor( name, r,g,b,a )
	local entry = { 
		name = name, 
		color = { r,g,b,a }
	}
	table.insert( self.colorList, entry )
	self.colorTable[ name ] = { r,g,b,a }
end

function Palette:save()
	return {
		name = self.name,
		colors = self.colorList
	}
end

function Palette:load( data )
	local name = data.name
	local colors = data.colors
	self.colorList = {}
	self.colorTable= {}
	for i, entry in ipairs( colors ) do
		self:setColor( entry.name, unpack( entry.color ) )
	end
	self.name = name
end


--------------------------------------------------------------------
CLASS: PaletteLibrary ()
	:MODEL{}
function PaletteLibrary:__init()
	self.palettes = {}
	self.paletteCache = {}
end

function PaletteLibrary:addPalette( pal )
	if not pal then pal = Palette() end
	table.insert( self.palettes, pal )
	return pal
end

function PaletteLibrary:removePalette( pal )
	local idx = table.index( self.palettes, pal )
	if idx then table.remove( self.palettes, idx ) end
end

function PaletteLibrary:clear()
	self.palettes = {}
	self.paletteCache = {}
end

function PaletteLibrary:findPalette( name )
	local pal = self.paletteCache[ name ]
	if pal then return pal end
	for i, p in ipairs( self.palettes ) do
		if p.name == name then pal = p break end
	end
	if pal then
		self.paletteCache[ name ] = pal
	end
	return pal
end

function PaletteLibrary:load( data )
	self:clear()
	if not data then return end
	for i, entry in ipairs( data ) do
		local pal = self:addPalette()
		pal:load( entry )
	end
end

function PaletteLibrary:save()
	local output = {}
	for i, pal in ipairs( self.palettes ) do
		local data = pal:save()
		output[ i ] = data
	end
	return output
end

local _paletteLibrary = PaletteLibrary()
function getPaletteLibrary()
	return _paletteLibrary
end
