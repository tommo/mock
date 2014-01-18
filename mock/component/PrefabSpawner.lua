module 'mock'

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
		Field 'spawnAsChild'   :boolean();		
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
			if self.spawnAsChild then
				ent:addChild( e )
				if self.copyLoc then	e:setLoc( 0,0,0 )	end
				if self.copyRot then	e:setRot( 0,0,0 )	end
				if self.copyScl then	e:setScl( 1,1,1 )	end
			else
				ent:addSibling( e )
				if self.copyLoc then	e:setLoc( ent:getLoc() ) end
				if self.copyRot then	e:setRot( ent:getRot() ) end
				if self.copyScl then	e:setScl( ent:getScl() ) end
			end
		end
	end
	if self.destroyOnSpawn then
		ent:destroy()
	end
end
