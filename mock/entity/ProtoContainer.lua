module 'mock'

CLASS: ProtoContainer ( mock.Entity )
	:MODEL{
		'----';
		Field 'proto' :asset( 'proto' ) :set( 'setProto' );
		'----';
		Field 'resetLoc' :boolean() :onset( 'refreshProto' );
		Field 'resetScl' :boolean() :onset( 'refreshProto' );
		Field 'resetRot' :boolean() :onset( 'refreshProto' );
		'----';
		Field 'resetLayer' :boolean() :onset( 'refreshProto' );
	}

registerEntity( 'ProtoContainer', ProtoContainer )

function ProtoContainer:__init()
	self.proto   = false
	self.instance = false
	self.resetTransform = true
	self.resetLoc = true
	self.resetScl = false
	self.resetRot = false
	self.resetLayer = false
end

function ProtoContainer:refreshProto()
	if not self.loaded then return end

	if self.instance then
		self.instance:destroyWithChildrenNow()
		self.instance = false
	end
	
	if self.proto then
		local instance = createProtoInstance( self.proto )
		if not instance then return end
		
		--todo: layer
		if self.resetLoc then	instance:setLoc( 0,0,0 )	end
		if self.resetRot then	instance:setRot( 0,0,0 )	end
		if self.resetScl then	instance:setScl( 1,1,1 )	end

		if self.resetLayer then
			self:addInternalChild( instance, self:getLayer() )
		else
			self:addInternalChild( instance )
		end
		print( 'built instance', instance, instance:getParent() )
		print( instance:getParent():getLoc() )
		self.instance = instance
	end	
end

function ProtoContainer:setProto( path )
	self.proto = path
	self:refreshProto()
end

function ProtoContainer:getInstance()
	return self.instance
end

function ProtoContainer:onLoad()
	self.loaded = true
	self:refreshProto()
end
