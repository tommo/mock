module 'mock'

CLASS: PhysicsBodyDef ()
	:MODEL{
		Field 'tag'            :string();
		'----';
		Field 'bodyType'       :enum( EnumPhysicsBodyType );
		'----';
		Field 'allowSleep'     :boolean();
		Field 'isBullet'       :boolean();
		Field 'fixedRotation'  :boolean();
		'----';
		Field 'gravityScale'   :number();
		Field 'linearDamping'  :number();
		Field 'angularDamping' :number();
		'----';
		Field 'defaultMaterial' :asset( 'physics_material' )
	}

function PhysicsBodyDef:__init()
	self.tag            = ''
	self.bodyType       = 'dynamic'
	self.allowSleep     = true
	self.isBullet       = false
	self.fixedRotation  = false
	self.gravityScale   = 1
	self.linearDamping  = 1
	self.angularDamping = 1
	self.defaultMaterial = false
end


local defaultBodyDef = PhysicsBodyDef()
defaultBodyDef.tag = '_default'
function getDefaultPhysicsBodyDef()
	return table.simplecopy(defaultBodyDef)
end

--------------------------------------------------------------------
local function loadPhysicsBodyDef( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('def') )
	local def    = mock.deserialize( nil, data )	
	return def
end

registerAssetLoader( 'physics_body_def', loadPhysicsBodyDef )
