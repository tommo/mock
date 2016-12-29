module 'mock'

--------------------------------------------------------------------
CLASS: UIEvent ()
	:MODEL{}

function UIEvent:__init( type )
	self.type = type
	self.accepted = false
end

function UIEvent:accept()
	self.accepted = true
end

function UIEvent:ignore()
	self.accepted = false
end

--------------------------------------------------------------------
