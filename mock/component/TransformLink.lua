module 'mock'

CLASS: TransformLink ()
	:MODEL{
		Field 'target' :type( mock.Entity ) :getset('Target');
	}
mock.registerComponent( 'TransformLink', TransformLink ) 


function TransformLink:onStart()
	self:applyLink()
end

function TransformLink:setTarget( t )
	self.target = t
	local ent = self._entity
	if ent and ent.started then
		self:applyLink()
	end
end

function TransformLink:getTarget()
	return self.target
end

function TransformLink:applyLink()
	if self.target then
		inheritTransform( self._entity:getProp(), self.target:getProp() )
	end		
end

--------------------------------------------------------------------
CLASS: PartialTransformLink ()
	:MODEL{
		Field 'target' :type( mock.Entity ) :getset('Target');
		'----';
		Field 'locX' :boolean();
		Field 'locY' :boolean();
		Field 'locZ' :boolean();
		'----';
		Field 'rotX' :boolean();
		Field 'rotY' :boolean();
		Field 'rotZ' :boolean();
		'----';
		Field 'sclX' :boolean();
		Field 'sclY' :boolean();
		Field 'sclZ' :boolean();
	}
mock.registerComponent( 'PartialTransformLink', PartialTransformLink ) 


function PartialTransformLink:__init()
	self.locX = true
	self.locY = true
	self.locZ = true
	self.rotX = false
	self.rotY = false
	self.rotZ = false
	self.sclX = false
	self.sclY = false
	self.sclZ = false
end

function PartialTransformLink:onStart()
	self:applyLink()
end

function PartialTransformLink:setTarget( t )
	self.target = t
	local ent = self._entity
	if ent and ent.started then
		self:applyLink()
	end
end

function PartialTransformLink:getTarget()
	return self.target
end

function PartialTransformLink:applyLink()
	if self.target then
		local ps = self.target:getProp()
		local pt = self._entity:getProp()
		if self.locX then
			pt:setAttrLink( MOAIProp.ATTR_X_LOC, ps, MOAIProp.ATTR_X_LOC )
		end
		if self.locY then
			pt:setAttrLink( MOAIProp.ATTR_Y_LOC, ps, MOAIProp.ATTR_Y_LOC )
		end
		if self.locZ then
			pt:setAttrLink( MOAIProp.ATTR_Z_LOC, ps, MOAIProp.ATTR_Z_LOC )
		end

		if self.rotX then
			pt:setAttrLink( MOAIProp.ATTR_X_ROT, ps, MOAIProp.ATTR_X_ROT )
		end
		if self.rotY then
			pt:setAttrLink( MOAIProp.ATTR_Y_ROT, ps, MOAIProp.ATTR_Y_ROT )
		end
		if self.rotZ then
			pt:setAttrLink( MOAIProp.ATTR_Z_ROT, ps, MOAIProp.ATTR_Z_ROT )
		end

		if self.sclX then
			pt:setAttrLink( MOAIProp.ATTR_X_SCL, ps, MOAIProp.ATTR_X_SCL )
		end
		if self.sclY then
			pt:setAttrLink( MOAIProp.ATTR_Y_SCL, ps, MOAIProp.ATTR_Y_SCL )
		end
		if self.sclZ then
			pt:setAttrLink( MOAIProp.ATTR_Z_SCL, ps, MOAIProp.ATTR_Z_SCL )
		end
	end		
end
