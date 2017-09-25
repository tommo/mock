module 'mock'

--------------------------------------------------------------------
CLASS: EditorEntity ( mock.Entity )
function EditorEntity:__init()
	self.layer = '_GII_EDITOR_LAYER'
	self.FLAG_EDITOR_OBJECT = true
end

--------------------------------------------------------------------
CLASS: ComponentPreviewer ()
	:MODEL{}

function ComponentPreviewer:onStart()
end

function ComponentPreviewer:onUpdate( dt )
end

function ComponentPreviewer:onDestroy()
end

function ComponentPreviewer:onReset() --??
end


--------------------------------------------------------------------
function resetFieldDefaultValue( obj, fid )
	local model = Model.fromObject( obj )
	if not model then return false end
	local field = model:getField( fid )
	if not field then return false end
	field:resetDefaultValue( obj )
	return true
end