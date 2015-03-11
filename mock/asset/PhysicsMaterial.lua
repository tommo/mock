module 'mock'

---------------------------------------------------------------------
--Material
--------------------------------------------------------------------
CLASS: PhysicsMaterial ()
	:MODEL{
		Field 'density';
		Field 'restitution';
		Field 'friction';
		'----';
		Field 'group'        :int();
		Field 'categoryBits' :int();
		Field 'maskBits'     :int();
		'----';
		Field 'isSensor'     :boolean();
		'----';
	}

function PhysicsMaterial:__init()
	self.density = 1
	self.restitution = 0.5
	self.friction = 0.5
	self.isSensor = false
end

--------------------------------------------------------------------
local function loadPhysicsMaterial( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('config') )
	local config = mock.deserialize( nil, data )	
	return config
end

registerAssetLoader( 'physics_material', loadPhysicsMaterial )
