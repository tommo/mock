------------SYSTEM META
function checkOS(...)
	local os=MOAIEnvironment.osBrand
	for i=1, select('#',...) do
		local n=select(i,...)
		if os==n then return true end
	end
	return false
end

function checkLanguage(...)
	local lang=MOAIEnvironment.languageCode or 'en'

	lang=string.lower(lang)
	for i=1, select('#',...) do
		local n=select(i,...)
		if lang==n then return true end
	end
	return false
end

------------RESOLUTION related
function getDeviceScreenSpec()
	local os=string.lower(MOAIEnvironment.osBrand)
	if os=='osx' or os=='windows' or os=='linux' then return os end

	local sw,sh=
						MOAIEnvironment.horizontalResolution
						,MOAIEnvironment.verticalResolution
	
	local deviceName=""

	if os=='ios' then
		if checkDimension(sw,sh, 320,480) then deviceName='iphone' 
		elseif checkDimension(sw,sh, 640,960) then deviceName='iphone4' 
		elseif checkDimension(sw,sh, 640,1136) then deviceName='iphone5'
		elseif checkDimension(sw,sh, 1024,768) then deviceName='ipad'
		elseif checkDimension(sw,sh, 1024*2,768*2) then deviceName='ipad3'
		end

	elseif os=='android' then
		deviceName=""
	else --???
		error("what ?")
	end
	return os, deviceName, sw,sh
end

local deviceResolutions={
	iphone  = {320,480},
	iphone4 = {640,960},
	iphone5 = {640,1136},
	ipad    = {768,1024},
	ipad2   = {768,1024},
	ipad3   = {768*2,1024*2},
	ipad4   = {768*2,1024*2},
	android = {480,800},
}

function getResolutionByDevice(simDeviceName,simDeviceOrientation)
	if simDeviceName then
		local w,h=unpack(deviceResolutions[simDeviceName])
		if simDeviceOrientation=='portrait' then 
			return w,h
		else
			return h,w
		end
	end
	return 0,0
end

function getDeviceResolution(simDeviceName,simDeviceOrientation)
	local sw,sh=
						MOAIEnvironment.horizontalResolution
						,MOAIEnvironment.verticalResolution

	if sw and sw and sw*sh~=0 then
		return sw,sh		
	elseif simDeviceName then
		return getResolutionByDevice(simDeviceName,simDeviceOrientation)
	end

	return 0,0
end

--------MOAI class tweak
function extractMoaiInstanceMethods(clas,...)
	local methods={...}
	local funcs={}
	local obj=clas.new()
	for i, m in ipairs(methods) do
		local f=obj[m]
		assert(f,'method not found:'..m)
		funcs[i]=f
	end
	return unpack(funcs)
end


function injectMoaiClass( clas, methods )
	local interfaceTable = clas.getInterfaceTable()
	for k, v in pairs(methods) do
		interfaceTable[ k ] = v
	end
end


----------URL
function openURLInBrowser(url)
	if checkOS('iOS') then
		-- print('open url in safari',url)
		MOAIWebViewIOS.openUrlInSafari(url)

	elseif checkOS('Android') then
		-- print('open url in browser',url)
		MOAIAppAndroid.openURL(url)
	else
		os.execute(string.format('open %q',url))
	end
end

function openRateURL(appID)
	if checkOS('iOS') then
		local url=
			'itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id='
			..appID
		openURLInBrowser(url)
	elseif checkOS('Android') then
		--todo
	end
end


if checkOS('Android') then
	print = MOAILogMgr.log
end

LOG = MOAILogMgr.log


function grabNextFrame( filepath, frameBuffer )
	local image = MOAIImage.new()
	frameBuffer = frameBuffer or MOAIGfxDevice.getFrameBuffer()
	frameBuffer:grabNextFrame(
		image,
		function()
			local w,h = image:getSize()
			local setRGBA = image.setRGBA
			local getRGBA = image.getRGBA
			io.write('postprocessing...')
			for y=1,h do
				for x=1,w do
					local r,g,b,a=getRGBA(image,x,y)
					if a<1 then	setRGBA(image,x,y,r,g,b,1) end
				end
			end
			image:writePNG(filepath)
			io.write('saved:   ',filepath,'\n')
		end)
end


-------replace system os.clock
os._clock=os.clock
os.clock=MOAISim.getDeviceTime

MOAIJsonParser.defaultEncodeFlags = 0x02 + 0x80  --indent 2, sort key

function encodeJSON( data ) --included default flags
	return MOAIJsonParser.encode( data, MOAIJsonParser.defaultEncodeFlags )
end

function decodeJSON( data ) --included default flags
	return MOAIJsonParser.decode( data )
end



--------------------------------------------------------------------
----extract all easetype constant to global env?
--------------------------------------------------------------------

EASE_IN        = MOAIEaseType.EASE_IN
EASE_OUT       = MOAIEaseType.EASE_OUT
FLAT           = MOAIEaseType.FLAT
LINEAR         = MOAIEaseType.LINEAR
SHARP_EASE_IN  = MOAIEaseType.SHARP_EASE_IN
SHARP_EASE_OUT = MOAIEaseType.SHARP_EASE_OUT
SHARP_SMOOTH   = MOAIEaseType.SHARP_SMOOTH
SMOOTH         = MOAIEaseType.SMOOTH
SOFT_EASE_IN   = MOAIEaseType.SOFT_EASE_IN
SOFT_EASE_OUT  = MOAIEaseType.SOFT_EASE_OUT
SOFT_SMOOTH    = MOAIEaseType.SOFT_SMOOTH
BACK_IN        = MOAIEaseType.BACK_IN
BACK_OUT       = MOAIEaseType.BACK_OUT
BACK_SMOOTH    = MOAIEaseType.BACK_SMOOTH
ELASTIC_IN     = MOAIEaseType.ELASTIC_IN
ELASTIC_OUT    = MOAIEaseType.ELASTIC_OUT
ELASTIC_SMOOTH = MOAIEaseType.ELASTIC_SMOOTH
BOUNCE_IN      = MOAIEaseType.BOUNCE_IN
BOUNCE_OUT     = MOAIEaseType.BOUNCE_OUT
BOUNCE_SMOOTH  = MOAIEaseType.BOUNCE_SMOOTH

--------------------------------------------------------------------

function saveMOAIGridTiles( grid )
	local stream = MOAIMemStream.new()
	stream:open()

	local writer64 = MOAIStreamAdapter.new()
	local writerDeflate = MOAIStreamAdapter.new ()
	writer64:openBase64Writer ( stream )
	writerDeflate:openDeflateWriter ( writer64 )
	grid:streamTilesOut( writerDeflate )
	writerDeflate:close()
	writer64:close()

	stream:seek( 0 )
	local encoded = stream:read()
	stream:close()

	return encoded
end


function loadMOAIGridTiles( grid, dataString )

	local stream = MOAIMemStream.new()
	stream:write( dataString )
	stream:seek(0)

	local reader64 = MOAIStreamAdapter.new()
	local readerDeflate = MOAIStreamAdapter.new ()
	reader64:openBase64Reader( stream )
	readerDeflate:openDeflateReader( reader64 )

	grid:streamTilesIn( readerDeflate )

	readerDeflate:close()
	reader64:close()
	stream:close()

end


function resizeMOAIGrid( grid, w, h, tw, th ,ox, oy, cw, ch )
	local ow, oh = grid:getSize()
	local nw, nh = math.min( ow, w ), math.min( oh, h )
	local tmpGrid = MOAIGrid.new()
	tmpGrid:setSize( nw, nh )
	for y = 1, nh do
		for x = 1, nw do
			tmpGrid:setTile( x, y, grid:getTile( x, y ) )
		end
	end
	grid:setSize( w,h,tw,th,ox,oy,cw,ch )
	for y = 1, nh do
		for x = 1, nw do
			grid:setTile( x, y, tmpGrid:getTile( x, y ) )
		end
	end
end
