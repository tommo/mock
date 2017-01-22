module 'mock'
-- --------------------------------------------------------------------
local _stopwatchState = {}
local function _affirmStopwatchEntry( id )
	id = id or 'default'
	local entry = _stopwatchState[ id ]
	if not entry then
		entry = {
			id          = id;
			active      = 0;
			from        = false;
			total       = 0;
			previous    = 0;
		}
		_stopwatchState[ id ] = entry
	end
	return entry
end

local function _stopwatchClock()
	return os.clock()
end

local function stopwatchResetAll()
	for id, entry in pairs( _stopwatchState ) do
		entry.total = 0
	end
end

local function stopwatchReset( id, a, ... )
	local entry = _affirmStopwatchEntry( id )
	entry.total = 0
	if a then
		return stopwatchReset( a, ... )
	end
end

local function stopwatchStart( id, a, ... )
	local entry = _affirmStopwatchEntry( id )
	if entry.active <= 0 then
		entry.from = _stopwatchClock()
	end
	entry.active = entry.active + 1
	if a then
		return stopwatchStart( a, ... )
	end
end

local function stopwatchStop( id, a, ... )
	local entry = _affirmStopwatchEntry( id )
	local active = entry.active - 1
	if active < 0 then
		_error( 'stopwatch mistached start/stop' )
		return
	elseif active == 0 then
		local elapsed = _stopwatchClock() - entry.from
		entry.previous = elapsed
		entry.from = false
		entry.total = entry.total + elapsed
		entry.active = 0
	else
		entry.active = active
	end
	if a then
		return stopwatchStop( a, ... )
	end
end

local function stopwatchGet( id )
	local entry = _affirmStopwatchEntry( id )
	local prev
	local total = entry.total
	if entry.active > 0 then
		if entry.from then
			prev = _stopwatchClock() - entry.from
			total = total + prev
		else
			prev = 0
		end
	else
		prev = entry.previous or 0
	end
	return prev, total
end

local function stopwatchGetTotal( id )
	local prev, total = stopwatchGet( id )
	return total
end

local function stopwatchGetNow( id )
	local entry = _affirmStopwatchEntry( id )
	if entry.active > 0 then
		if entry.from then
			return _stopwatchClock() - entry.from
		end
	end
	return 0
end

local function stopwatchGetPrev( id )
	entry = _affirmStopwatchEntry( id )
	return entry.previous or 0
end

local function stopwatchReport( ... )
	local result = {}
	local ids
	if not ... then
		ids = { 'default' }
	else
		ids = { ... }
	end
	local output = ''
	for i, id in ipairs( ids ) do
		if i > 1 then
			output = output .. '\n'
		end
		local prev, total = stopwatchGet( id )
		output = output .. string.format( '%#8.3f /%#8.3f -> Time elapsed <%s>', prev or 0, total or 0, id )
	end
	return output
end

local function stopwatchAdd( id, t )
	local entry = _affirmStopwatchEntry( id )
	entry.total = entry.total + ( t or 0 )
end

--Export
_Stopwatch = {
	prev     = stopwatchGetPrev,
	now      = stopwatchGetNow,
	total    = stopwatchGetTotal,
	get      = stopwatchGet,
	start    = stopwatchStart,
	stop     = stopwatchStop,
	reset    = stopwatchReset,
	resetAll = stopwatchResetAll,
	report   = stopwatchReport,
	add      = stopwatchAdd
}

--------------------------------------------------------------------
local ProFi
function startProfiler()
	if not ProFi then
		ProFi = require 'mock.3rdparty.ProFi'
	end
	ProFi:reset()
	ProFi:start()	
end

function stopProfiler( outputFile )
	if ProFi then
		ProFi:stop()
		if outputFile then
			ProFi:writeReport( outputFile )
		end
	end
end

function runProfiler( duration, outputPath )
	duration = duration or 10
	printf('start profiling for %d secs', duration)
	startProfiler()
	laterCall(
		duration,
		function()
			print('stop profiling')
			mock.stopProfiler( outputPath or 'profiler.log' )
		end
	)
end