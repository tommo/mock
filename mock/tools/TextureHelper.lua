module 'mock'

--------------------------------------------------------------------
local function _generateLUT( size )
	size = size or 32
	local img = MOAIImageTexture.new()
	img:init( size*size, size )
	local set = img.setRGBA
	for z = 0, size - 1 do
		for x = 0, size - 1 do
			for y = 0, size - 1 do 
				local r,g,b = x/(size-1), y/(size-1), z/(size-1)
				set( img, x + z * size, y, r, g, b, 1 )
			end
		end
	end
	return img
end

local BaseLUTs = {}
local function buildBaseLUT( size )
	size = size or 32
	local lut = BaseLUTs[ size ]
	if lut then
		return lut
	end
	lut = _generateLUT( size )
	BaseLUTs[ size ] = lut
	return lut
end

--------------------------------------------------------------------
local function buildCurveValueImageTexture( curve, size )
	local img = MOAIImageTexture.new()
	local set = img.setRGBA
	img:init( size, 1 )
	local l = curve:getLength()
	for x = 0, size-1 do
		local k = x/(size-1)
		local t = k * l
		local v = curve:getValueAtTime( t )
		set( img, x, 0, v, v, v, 1 )
	end
	return img
end

local function build3CurveValueImageTexture3( curveA, curveB, curveC, size )
	local img = MOAIImageTexture.new()
	local set = img.setRGBA
	img:init( size, 1 )
	local l = curveA:getLength()
	for x = 1, size-1 do
		local k = x/(size-1)
		local t = k * l
		local a = curveA:getValueAtTime( t )
		local b = curveB:getValueAtTime( t )
		local c = curveC:getValueAtTime( t )
		set( img, x, 1, a, b, c, 1 )
	end
	return img
end


--------------------------------------------------------------------
TextureHelper = {
	buildBaseLUT                 = buildBaseLUT;
	buildCurveValueImageTexture  = buildCurveValueImageTexture;
	buildCurveValueImageTexture3 = build3CurveValueImageTexture3;
}