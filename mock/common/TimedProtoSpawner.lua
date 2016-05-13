module 'mock'

CLASS: TimedProtoSpawner ( ProtoSpawner )
	:MODEL{
		Field 'frequency' :range( 0 );
		Field 'frequencyVar' :range( 0 );
		Field 'perSpawnCount' :int();
		Field 'spawnCountVar' :int();
		Field 'totalSpawnCount' :int();
		Field 'delay';
	}

registerComponent( 'TimedProtoSpawner', TimedProtoSpawner )
registerEntityWithComponent( 'TimedProtoSpawner', TimedProtoSpawner )

function TimedProtoSpawner:__init()
	self.frequency = 1
	self.frequencyVar = 0
	self.perSpawnCount = 1
	self.spawnCountVar = 0
	self.totalSpawnCount = 10
	self.delay = 0
end

function TimedProtoSpawner:spawn()
	if self.mainThread then
		self.mainThread:stop()
	end
	self.mainThread = self:addCoroutine( 'actionSpawnControl' )
end

function TimedProtoSpawner:actionSpawnControl()
	local count = 0
	self:wait( self.delay )
	while true do
		local var = self.spawnCountVar
		local f = self.frequency + noise( self.frequencyVar )
		if f <= 0 then 
			coroutine.yield()
		else
			local interval = 1 / f
			self:wait( interval )
			local actualCount = math.floor( self.perSpawnCount + noise( self.spawnCountVar ) )
			for i = 1, actualCount do
				self:spawnOne()
				count = count + 1
				if self.totalSpawnCount > 0 and count >= self.totalSpawnCount then
					return self:postSpawn()
				end
			end
		end
	end
end