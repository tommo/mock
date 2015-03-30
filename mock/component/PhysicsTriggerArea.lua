module 'mock'
--------------------------------------------------------------------
CLASS: TriggerAreaBase ( TriggerObjectBase )
	:MODEL{	
	}

function TriggerObjectBase:createBody()
	local world = self:getScene():getBox2DWorld()
	local body = world:addBody( MOAIBox2DBody.STATIC )
	return body
end

--------------------------------------------------------------------
CLASS: TriggerAreaCircle ( TriggerAreaBase )
	:MODEL{
		'----';
		Field 'radius' :range(0) :set('setRadius')
	}

registerComponent( 'TriggerAreaCircle', TriggerAreaCircle )
registerEntityWithComponent( 'TriggerAreaCircle', TriggerAreaCircle )

function TriggerAreaCircle:__init()
	self.radius = 100
end

function TriggerAreaCircle:updateCollisionShape()
	local body = self.body
	if not body then return end
	if self.shape then self.shape:destroy() end
	self.shape = body:addCircle( 0,0, self.radius )
	self.shape:setSensor( true )
	self:setupCollisionCallback( self.shape )
end

function TriggerAreaCircle:setRadius( r )	
	self.radius = r
	self:updateCollisionShape()
end

--------------------------------------------------------------------
--EDITOR
--------------------------------------------------------------------
function TriggerAreaCircle:onBuildGizmo()
	local giz = mock_edit.SimpleBoundGizmo()
	giz:setTarget( self )
	return giz
end

function TriggerAreaCircle:drawBounds()
	GIIHelper.setVertexTransform( self._entity:getProp() )
	mock_edit.applyColor( 'gizmo_trigger' )
	MOAIDraw.fillCircle( 0, 0, self.radius )
	mock_edit.applyColor( 'gizmo_trigger_border' )
	MOAIDraw.drawCircle( 0, 0, self.radius )
end


--------------------------------------------------------------------
CLASS: TriggerAreaBox ( TriggerAreaBase )
	:MODEL{
		'----';
		Field 'width' :range(0) :set('setWidth');
		Field 'height' :range(0) :set('setHeight');
	}

registerComponent( 'TriggerAreaBox', TriggerAreaBox )
registerEntityWithComponent( 'TriggerAreaBox', TriggerAreaBox )

function TriggerAreaBox:__init()
	self.width  = 100
	self.height = 100
	self.shape  = false
end

function TriggerAreaBox:setWidth( w )	
	self.width = w
	self:updateCollisionShape()
end

function TriggerAreaBox:setHeight( h )	
	self.height = h
	self:updateCollisionShape()
end

function TriggerAreaBox:updateCollisionShape()
	local body = self.body
	if not body then return end
	if self.shape then self.shape:destroy() end
	local w, h = self.width, self.height
	self.shape = body:addRect( rectCenter( 0,0, w,h ) )
	self.shape:setSensor( true )	
	self:setupCollisionCallback( self.shape )
end

--------------------------------------------------------------------
--EDITOR
--------------------------------------------------------------------
function TriggerAreaBox:onBuildGizmo()
	local giz = mock_edit.SimpleBoundGizmo()
	giz:setTarget( self )
	return giz
end

function TriggerAreaBox:drawBounds()
	GIIHelper.setVertexTransform( self._entity:getProp() )
	local w, h = self.width, self.height
	mock_edit.applyColor( 'gizmo_trigger' )
	MOAIDraw.fillRect( -w/2, -h/2, w/2, h/2 )
	mock_edit.applyColor( 'gizmo_trigger_border' )
	MOAIDraw.drawRect( -w/2, -h/2, w/2, h/2 )
end


