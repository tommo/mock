module 'mock'

--------------------------------------------------------------------
local function _generateLUT()
	local img = MOAIImageTexture.new()
	img:init( 1024, 32 )
	local set = img.setRGBA
	for z = 1, 32 do
		for x = 1, 32 do
			for y = 1, 32 do 
				local r,g,b = (x-1)/31, (y-1)/31, (z-1)/31
				set( img, x + ( z - 1 ) * 32 - 1, y - 1, r, g, b, 1 )
			end
		end
	end
	return img
end

local BaseLUT = false
local function buildBaseLUT()
	if BaseLUT then return BaseLUT end
	BaseLUT = _generateLUT()
	return BaseLUT
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