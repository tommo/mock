module 'mock'

local insert = table.insert

CLASS: DebugMemoryView ( mock.DebugUIModule )
--------------------------------------------------------------------
function DebugMemoryView:__init()
	self.trackedValues = {}
end

function DebugMemoryView:onDebugGUI( gui, scn )
	gui.Begin( 'Memory' )
		if gui.Button( 'Force GC' ) then
			MOAISim.forceGC()
		end
		if gui.CollapsingHeader( 'Overview', MOAIImGui.TreeNodeFlags_DefaultOpen ) then
			self:subOverview( gui, scn )
		end
		if gui.CollapsingHeader( 'Trace', MOAIImGui.TreeNodeFlags_DefaultOpen ) then
			self:subTrace( gui, scn )
		end
		if gui.CollapsingHeader( 'Textures' ) then
			self:subTextures( gui, scn )
		end
	gui.End( 'Memory' )
end

function DebugMemoryView:trackValue( gui, key, textPattern, newValue,  count, interval, w, h )
	count = count or 10
	interval = interval or 0.25
	local entry = self.trackedValues[ key ]
	if not entry then
		local values = {}
		for i = 1, count do
			values[ i ] = 0
		end
		entry = {
			max = 0,
			min = 0,
			prevTime = 0,
			accumulated = 0,
			values = values,
			text = '',
			offset = 0
		}
		self.trackedValues[ key ] = entry
	end
	local values = entry.values
	local t = os.clock()
	local elapsed = t - entry.prevTime
	if elapsed > interval then
		if type( newValue ) == 'function' then newValue = newValue() end
		local offset = entry.offset
		values[ offset + 1 ] = newValue
		entry.offset = ( offset + 1 ) % count
		entry.prevTime = t
		entry.min = math.min( entry.min, newValue )
		entry.max = math.max( entry.max, newValue )
		local overlayText = string.format( textPattern or '%d', newValue )
		entry.text = overlayText
	end
	gui.PlotLines( key, 
		values, count, entry.offset, 
		entry.text, 
		entry.min, entry.max, 
		w or 0, h or 20
	)
end

-- function DebugMemoryView:subOverview( gui, scn )
-- 	--common
-- 	self:trackValue( gui, 'Scene Objects', 'Scene Objects: %d',  scn.entityCount, 50, 0.55 )
-- 	self:trackValue( gui, 'MOAI Objects',  'MOAI Objects: %d',   MOAISim.getLuaObjectCount(), 50, 0.55 )

-- 	local memUsage = MOAISim.getMemoryUsage()
-- 	self:trackValue( gui, 'Total Memory', 'Total Memory:%dk',    memUsage.total/1000, 100, 0.5, 0, 50 )
-- 	self:trackValue( gui, 'Texture Memory', 'Texture Memory:%dk',  memUsage.texture/1000, 30, 2, 0, 20 )
-- end

function DebugMemoryView:subOverview( gui, scn )
	--common
	gui.Text( string.format( 'Scene Objects: %d',  scn.entityCount ) )
	gui.Text( string.format(  'MOAI Objects: %d',   MOAISim.getLuaObjectCount() ) )

	local memUsage = MOAISim.getMemoryUsage( 'k' )
	gui.Text( string.format( 'Total Memory:%dk',    memUsage.total ) )
	gui.Text( string.format( 'Lua Memory:%dk',  memUsage.lua ) )
	gui.Text( string.format( 'Texture Memory:%dk',  memUsage.texture ) )
	gui.Text( string.format( 'lua_gc:%dk',    memUsage._luagc_count ) )
	gui.Text( string.format( '_sys_vs:%dk',    memUsage._sys_vs ) )
	gui.Text( string.format( '_sys_rss:%dk',    memUsage._sys_rss ) )
end

function DebugMemoryView:subTrace( gui, scn )
	--sort by count
	--sort by name
	self:subTraceMOCK( gui, scn )
	-- self:subTraceMOAI( gui, scn )
	if gui.Button( 'Report MOAI Histogram' ) then
		MOAILuaRuntime.setTrackingFlags( MOAILuaRuntime.TRACK_OBJECTS + MOAILuaRuntime.TRACK_OBJECTS_STACK_TRACE )
		MOAILuaRuntime.reportHistogram()
	end
end

function DebugMemoryView:updateMOCKTrace()
	local countdown = ( self.countdownMOCKTrace or 0 ) - 1
	if countdown <= 0 then
		local countMap = countTracingObject()
		local countList = {}
		for name, count in pairs( countMap ) do
			insert( countList, { name, count } )
		end
		table.sort( countList, function( i1, i2 ) return i1[2] > i2[2] end )
		self.MOCKTraceCountList = countList
		countdown = 5
	end
	self.countdownMOCKTrace = countdown
end

function DebugMemoryView:subTraceMOCK( gui, scn )
	gui.Separator()
	local ev, checked = gui.Checkbox( 'Tracing MOCK object', isTracingObjectAllocation() )
	if ev then
		setTracingObjectAllocation( checked )
	end
	if isTracingObjectAllocation() then
		if gui.Button( 'Clear Tracing Table' ) then
			clearTracingTable()
		end
		gui.Separator()
		self:updateMOCKTrace()
		local countList = self.MOCKTraceCountList
		gui.Columns( 2 )
		gui.Text'Type';  gui.NextColumn()
		gui.Text'Count'; gui.NextColumn()
		gui.Separator()
		for i, entry in ipairs( countList ) do
			gui.Text( entry[1] )
		end
		gui.NextColumn()
		for i, entry in ipairs( countList ) do
			gui.Text( tostring( entry[2] ) )
		end
		gui.Columns( 1 )
	end
	gui.Separator()
end


function DebugMemoryView:subTraceMOAI( gui, scn )
	gui.Separator()
	local ev, checked = gui.Checkbox( 'Tracing MOAI object', isTracingObjectAllocation() )
	if ev then
		setTracingObjectAllocation( checked )
	end
	if isTracingObjectAllocation() then
		gui.Separator()
		local countMap = countTracingObject()
		local countList = {}
		for name, count in pairs( countMap ) do
			insert( countList, { name, count } )
		end
		table.sort( countList, function( i1, i2 ) return i1[2] > i2[2] end )
	-- table.sort( counts, function( i1, i2 ) return i1[1] < i2[1] end )
		gui.Columns( 2 )
		gui.Text'Type';  gui.NextColumn()
		gui.Text'Count'; gui.NextColumn()
		gui.Separator()
		for i, entry in ipairs( countList ) do
			gui.Text( entry[1] )
		end
		gui.NextColumn()
		for i, entry in ipairs( countList ) do
			gui.Text( tostring( entry[2] ) )
		end
		gui.Columns( 1 )
	end
	gui.Separator()
end

function DebugMemoryView:subTextures( gui, scn )
	local textures = getLoadedMoaiTextures()
	local report = {}
	for tex in pairs( textures ) do
		local w, h = tex:getSize()
		local memSize = w * h * 4 --TODO: use texturesize in future
		local sizeText = string.format( '%d,%d', w, h )
		table.insert( report, { tex.debugName or '<unknown>', sizeText ,w*h*4 } )
	end
	local function _sortFunc( i1, i2 )
		return i1[1] < i2[1]
	end
	table.sort( report, _sortFunc )

	gui.Columns( 2 )
	gui.Text'name';  gui.NextColumn()
	gui.Text'size'; gui.NextColumn()
	gui.Separator()
	for i, entry in ipairs( report ) do
		gui.Text( entry[1] )
	end
	gui.NextColumn()
	for i, entry in ipairs( report ) do
		gui.Text( tostring( entry[2] ) )
	end
	gui.Columns( 1 )
end

DebugMemoryView():register( 'memory' )
