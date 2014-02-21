module 'mock'

local enumSpawnMethod = _ENUM_V {
	'root',
	'sibling',
	'child',
}

CLASS: PrefabSpawner ()
	:MODEL{
		Field 'prefab' :asset('prefab');
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

registerComponent( 'PrefabSpawner', PrefabSpawner )
registerEntityWithComponent( 'PrefabSpawner', PrefabSpawner )

function PrefabSpawner:__init()
	self.prefab         = false
	self.autoSpawn      = true
	self.destroyOnSpawn = true
	self.spawnAsChild   = false
	self.copyLoc        = true
	self.copyScl        = false
	self.copyRot        = false
	self.spawnMethod    = 'child'
end

function PrefabSpawner:onStart( ent )
	if self.autoSpawn then
		self:spawn()
	end
end

function PrefabSpawner:spawn()
	local ent = self._entity
	if self.prefab then
		local e = loadPrefab( self.prefab )
		if e then
			local spawnMethod = self.spawnMethod
			if spawnMethod == 'child' then
				ent:addChild( e )
				if self.copyLoc then	e:setLoc( 0,0,0 )	end
				if self.copyRot then	e:setRot( 0,0,0 )	end
				if self.copyScl then	e:setScl( 1,1,1 )	end
			elseif spawnMethod == 'sibling' then
				ent:addSibling( e )
				if self.copyLoc then	e:setLoc( ent:getLoc() ) end
				if self.copyRot then	e:setRot( ent:getRot() ) end
				if self.copyScl then	e:setScl( ent:getScl() ) end
			elseif spawnMethod == 'root' then
				ent:getScene():addEntity( e )				
				if self.copyLoc then	e:setLoc( ent:getWorldLoc() ) end
				if self.copyRot then	e:setRot( ent:getRot() ) end
				if self.copyScl then	e:setScl( ent:getScl() ) end
			end
		end
	end
	if self.destroyOnSpawn then
		ent:destroy()
	end
end
