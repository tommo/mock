module 'mock'

CLASS: IntervalUpdateListener ( Component )
	:MODEL{
		Field 'active' :boolean() :isset('Active');
		Field 'interval' :int() :set( 'setInterval' );
}

local function _callback( timer, ... )
	local src = timer._source
	return src:onUpdate( ... )
end

function IntervalUpdateListener:__init()
	self.interval = 100
	local timer = MOAITimer.new()
	timer:setListener( MOAITimer.EVENT_TIMER_END_SPAN, _callback )
	timer:setMode( MOAITimer.LOOP )
	timer._source = self
	self.timer = timer
end

function IntervalUpdateListener:isActive()
	return self.active
end

function IntervalUpdateListener:getTimer()
	return self.timer
end

function IntervalUpdateListener:setActive( a )
	self.active = a ~= false
	if self.timer then
		self.timer:pause( not self.active )
	end
end

function IntervalUpdateListener:setInterval( interval )
	self.interval = interval
	self.timer:setSpan( interval/1000 )
end

function IntervalUpdateListener:reset()
	self.timer:setTime( 0 )
end

function IntervalUpdateListener:onStart( ent )
	self.timer:start()
	if not self.active then
		self.timer:pause()
	end
end

function IntervalUpdateListener:onDetach( ent )
	self.timer:stop()
end

function IntervalUpdateListener:onUpdate()
end

