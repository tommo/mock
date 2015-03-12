module 'mock'

---------------------------------------------------------------------
--Material
--------------------------------------------------------------------
CLASS: PhysicsMaterial ()
	:MODEL{
		Field 'tag' :string();
		'----';
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
	self.group = 1
	self.categoryBits = 1
	self.maskBits = 0xffff
end

function PhysicsMaterial:clone()
	local m = PhysicsMaterial()
	m.density      = self.density
	m.restitution  = self.restitution
	m.friction     = self.friction
	m.isSensor     = self.isSensor
	m.group        = self.group
	m.categoryBits = self.categoryBits
	m.maskBits     = self.maskBits
	return m
end

--------------------------------------------------------------------
local DefaultMaterial = PhysicsMaterial()

function getDefaultPhysicsMaterial()
	return DefaultMaterial
end

--------------------------------------------------------------------
local function loadPhysicsMaterial( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('config') )
	local config = mock.deserialize( nil, data )	
	return config
end

registerAssetLoader( 'physics_material', loadPhysicsMaterial )
