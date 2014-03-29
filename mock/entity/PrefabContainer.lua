module 'mock'

CLASS: PrefabContainer ( mock.Entity )
	:MODEL{
		'----';
		Field 'prefab' :asset( 'prefab' ) :set( 'setPrefab' );
		'----';
		Field 'resetLoc' :boolean();
		Field 'resetScl' :boolean();
		Field 'resetRot' :boolean();
		-- Field 'resetLayer' :boolean();
	}

registerEntity( 'PrefabContainer', PrefabContainer )

function PrefabContainer:__init()
	self.prefab   = false
	self.instance = false
	self.resetTransform = true
	self.resetLoc = true
	self.resetScl = false
	self.resetRot = false
	-- self.resetLayer = false
end

function PrefabContainer:refreshPrefab()
	if self.instance then
		self.instance:destroyWithChildrenNow()
		self.instance = false
	end
	if self.prefab then
		local instance = loadPrefab( self.prefab )
		self:addInternalChild( instance )
		--todo: layer
		self.instance = instance
		if self.resetLoc then	instance:setLoc( 0,0,0 )	end
		if self.resetRot then	instance:setRot( 0,0,0 )	end
		if self.resetScl then	instance:setScl( 1,1,1 )	end
	end	
end

function PrefabContainer:setPrefab( path )
	self.prefab = path
	self:refreshPrefab()
end
