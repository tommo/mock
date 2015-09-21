module 'mock'
CLASS: AnimatorTrackField ( AnimatorValueTrack )
	:MODEL{
		Field 'fieldId' :string();
	}

function AnimatorTrackField:__init()
	self.name = 'field'
	self.targetField = false
	self.fieldId = false
end

function AnimatorTrackField:onInit()
end

function AnimatorTrackField:isMatched( obj, fieldId, relativeTo )
	return self.targetPath:get( relativeTo ) == obj and fieldId == self.fieldId
end

function AnimatorTrackField:getType()
	return 'field<unknown>'
end

function AnimatorTrackField:toString()
	local pathText = self.targetPath:toString()
	return pathText..'::'..self.fieldId
end

function AnimatorTrackField:apply( state, target, t )
	local value = self.curve:getValueAtTime( t )
	return self.targetField:setValue( target, value )
end

function AnimatorTrackField:build( context ) --building shared data
	self.curve = self:buildCurve()
	context:updateLength( self:calcLength() )
end

function AnimatorTrackField:isPlayable()
	return true
end

function AnimatorTrackField:onStateLoad( state )
	local rootEntity, scene = state:getTargetRoot()
	local target = self.targetPath:get( rootEntity, scene )
	state:addUpdateListenerTrack( self, target )
end

function AnimatorTrackField:onLoad()
	self:affirmTargetField()	
end

function AnimatorTrackField:setFieldId( fieldId )
	self.fieldId = fieldId
	self:affirmTargetField()
end

function AnimatorTrackField:affirmTargetField()
	assert( self.fieldId )
	local clas = self.targetPath:getTargetClass()
	local model = Model.fromClass( clas )
	self.targetField = assert(model:getField( self.fieldId ) )
end

function AnimatorTrackField:getTragetField()
	return self.targetField
end

function AnimatorTrackField:onCollectObjectRecordingState( animator, retainedState )
	local rootEntity, scene = animator._entity, animator._entity.scene
	local target = self.targetPath:get( rootEntity, scene )
	retainedState:markFieldRecording( target, self.fieldId )
end

function AnimatorTrackField:onRestoreObjectRecordingState( animator, retainedState )
	local rootEntity, scene = animator._entity, animator._entity.scene
	local target = self.targetPath:get( rootEntity, scene )
	retainedState:restoreFieldRecording( target, self.fieldId )
end

function AnimatorTrackField:isLoadable( state )
	local rootEntity, scene = state:getTargetRoot()
	local target = self.targetPath:get( rootEntity, scene )
	return target and true or false
end
