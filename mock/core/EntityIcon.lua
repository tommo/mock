module 'mock'

local entityIconFolders = {}
local entityIconSet = false

function addEntityIconFolder( path )
	table.insert( entityIconFolders, path )
end

function clearEntityIconSet()
	entityIconSet = false
end

function getEntityIconSet()
	if entityIconSet then return entityIconSet end
	--scan everytime?
	local iconSet = {}
	for i, folder in ipairs( entityIconFolders ) do
		local files = MOAIFileSystem.listFiles( folder )
		if files then
			for i, filename in ipairs( files ) do
				if filename:endwith( '.png' ) then
					local name = basename( filename )
					if not iconSet[ name ] then iconSet[ name ] = filename end
				end
			end
		end
	end
	entityIconSet = iconSet
	return entityIconSet
end

