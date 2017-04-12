module 'mock'

local enumSpawnMethod = _ENUM_V {
	'root',
	'sibling',
	'child',
	'parent_sibling'
}

CLASS: ProtoSpawner ( Component )
	:MODEL{
		Field 'proto'          :asset('proto');
		Field 'spawnName'      :string();
		Field 'showIcon'       :boolean();
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
	self.showIcon				= true
	self.destroyOnSpawn = true
	self.spawnAsChild   = false
	self.copyLoc        = true
	self.copyScl        = false
	self.copyRot        = false
	self.spawnMethod    = 'sibling'
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
				if ent.parent then
					ent:forceUpdate()
					ent.parent:forceUpdate()
					if self.copyLoc then
						local x, y, z 
						if ent.parent.parent then
							x, y, z = ent.parent.parent:worldToModel( ent:getWorldLoc() )
						else
							x, y, z = ent:getWorldLoc()
						end
						instance:setLoc( x, y, z )
						instance:forceUpdate()
					end
					if self.copyRot then	instance:setRot( ent:getRot() ) end
					if self.copyScl then	instance:setScl( ent:getScl() ) end

					if ox then
						instance:addLoc( ox, oy, oz )
					end

					ent.parent:addSibling( instance )

				else --as root
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
		
		--FIXME:remove this non-generic code
		if ent:isInstance( 'EWMapObject' ) then
			instance:setFloor( ent:getFloor() )
		end
	end
	return instance
end

function ProtoSpawner:spawn()
	local result = { self:onSpawn() }
	self:postSpawn()
	return unpack( result )
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
	if not self.showIcon then return end
	local giz = mock_edit.IconGizmo( 'spawn.png' )
	return giz
end
