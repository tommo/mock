module 'mock'

local enumSpawnMethod = _ENUM_V {
	'root',
	'sibling',
	'child',
	'parent_sibling'
}

CLASS: ProtoSpawner ( Component )
	:MODEL{
		Field 'proto'         :asset('proto');
		Field 'spawnName'      :string();
		'----';		
		Field 'copyLoc'        :boolean();
		Field 'copyRot'        :boolean();
		Field 'copyScl'        :boolean();
		'----';		
		Field 'autoSpawn'      :boolean();
		Field 'destroyOnSpawn' :boolean();
		Field 'spawnMethod'    :enum( enumSpawnMethod )
		-- Field 'spawnAsChild'   :boolean();
	}
	:META{
		category = 'spawner'
	}

registerComponent( 'ProtoSpawner', ProtoSpawner )
registerEntityWithComponent( 'ProtoSpawner', ProtoSpawner )

function ProtoSpawner:__init()
	self.proto          = false
	self.autoSpawn      = true
	self.destroyOnSpawn = true
	self.spawnAsChild   = false
	self.copyLoc        = true
	self.copyScl        = false
	self.copyRot        = false
	self.spawnMethod    = 'child'
	self.spawnName      = ''
end

function ProtoSpawner:onStart( ent )
	if self.autoSpawn then
		self:spawn()
	end
end

function ProtoSpawner:spawnOne( ox, oy, oz )
	local ent = self._entity
	local instance
	if self.proto then
		instance = createProtoInstance( self.proto )
		if instance then
			instance:setName( self.spawnName )
			local spawnMethod = self.spawnMethod
			if spawnMethod == 'child' then
				if self.copyLoc then	instance:setLoc( 0,0,0 )	end
				if self.copyRot then	instance:setRot( 0,0,0 )	end
				if self.copyScl then	instance:setScl( 1,1,1 )	end
				if ox then
					instance:addLoc( ox, oy, oz )
				end
				ent:addChild( instance )
				
			elseif spawnMethod == 'sibling' then
				if self.copyLoc then	instance:setLoc( ent:getLoc() ) end
				if self.copyRot then	instance:setRot( ent:getRot() ) end
				if self.copyScl then	instance:setScl( ent:getScl() ) end
				if ox then
					instance:addLoc( ox, oy, oz )
				end
				ent:addSibling( instance )

			elseif spawnMethod == 'parent_sibling' then
				ent:forceUpdate()
				if self.copyLoc then	instance:setWorldLoc( ent:getWorldLoc() ) end
				if self.copyRot then	instance:setRot( ent:getRot() ) end
				if self.copyScl then	instance:setScl( ent:getScl() ) end
				if ox then
					instance:addLoc( ox, oy, oz )
				end
				if ent.parent then
					ent.parent:addSibling( instance )
				else
					ent:getScene():addEntity( instance )				
				end

			elseif spawnMethod == 'root' then
				ent:forceUpdate()
				if self.copyLoc then	instance:setLoc( ent:getWorldLoc() ) end
				if self.copyRot then	instance:setRot( ent:getRot() ) end
				if self.copyScl then	instance:setScl( ent:getScl() ) end
				if ox then
					instance:addLoc( ox, oy, oz )
				end
				instance:forceUpdate()
				ent:getScene():addEntity( instance )

			end
		end
	end
	return instance
end

function ProtoSpawner:spawn()
	self:onSpawn()
	self:postSpawn()
end

function ProtoSpawner:onSpawn()
	return self:spawnOne()
end

function ProtoSpawner:postSpawn()
	if self.destroyOnSpawn then
		self._entity:destroy()
	end
end



--------------------------------------------------------------------
--EDITOR Support
function ProtoSpawner:onBuildGizmo()
	local giz = mock_edit.IconGizmo( 'spawn.png' )
	return giz
end
