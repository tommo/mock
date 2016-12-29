module 'mock'

CLASS: UILayout ()
	:MODEL{}

mock.registerComponent( 'UILayout', UILayout )

function UILayout:__init()
end

function UILayout:getOwnerWidget()
	local ent = self:getEntity()
	if ent and ent.FLAG_UI_WIDGET then
		return ent
	end
end

function UILayout:updateLayout()
end
