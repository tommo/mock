module 'mock'

--DEPRECATED
--for legacy support

local newProp = MOAIProp.new
function Prop( option )
	local prop = newProp()
	if option then
		prop:setupProp( option )		
	end
	return prop
end

function Entity:addProp( option )
	return self:attach( Prop( option ) )
end

updateAllSubClasses( Entity )