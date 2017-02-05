module 'mock'

CLASS: UISpacer ( UIWidget )
	:MODEL{}

registerEntity( 'UISpacer', UISpacer )

function UISpacer:__init()
	self:setFocusPolicy( 'none' )
end

