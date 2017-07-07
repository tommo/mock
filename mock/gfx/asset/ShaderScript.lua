module 'mock'


--------------------------------------------------------------------
local _ShaderScriptLoaderEnv = {
	sampler = function ( default )
		return { tag = 'uniform', type = 'sampler', value = default }
	end;
	
	float = function ( default )
		return { tag = 'uniform', type = 'float', value = default }
	end;

	int = function ( default )
		return { tag = 'uniform', type = 'int', value = default }
	end;

	color = function ( default )
		return { tag = 'uniform', type = 'color', value = default }
	end;
	
	mat4 = function ( default )
		return { tag = 'uniform', type = 'mat4', value = default }
	end;

	GLOBAL_PEN_COLOR            = { tag = 'global', type = 'GLOBAL_PEN_COLOR'             };
	GLOBAL_VIEW_PROJ            = { tag = 'global', type = 'GLOBAL_VIEW_PROJ'             };
	GLOBAL_VIEW_WIDTH           = { tag = 'global', type = 'GLOBAL_VIEW_WIDTH'            };
	GLOBAL_VIEW_HEIGHT          = { tag = 'global', type = 'GLOBAL_VIEW_HEIGHT'           };
	GLOBAL_WORLD                = { tag = 'global', type = 'GLOBAL_WORLD'                 };
	GLOBAL_WORLD_VIEW           = { tag = 'global', type = 'GLOBAL_WORLD_VIEW'            };
	GLOBAL_WORLD_VIEW_PROJ_NORM = { tag = 'global', type = 'GLOBAL_WORLD_VIEW_PROJ_NORM'  };
	GLOBAL_WORLD_VIEW_PROJ      = { tag = 'global', type = 'GLOBAL_WORLD_VIEW_PROJ'       };
	GLOBAL_WORLD_INV            = { tag = 'global', type = 'GLOBAL_WORLD_INV'             };
	GLOBAL_WORLD_VIEW_INV       = { tag = 'global', type = 'GLOBAL_WORLD_VIEW_INV'        };
	GLOBAL_WORLD_VIEW_PROJ_INV  = { tag = 'global', type = 'GLOBAL_WORLD_VIEW_PROJ_INV'   };
}


local sharedSourceEnv = {
	math = math,
	print = print
}

--------------------------------------------------------------------
function _loadShaderScript( src, filename )
	local shaderItems = {}
	local sourceItems = {}
	local passes
	
	----
	local function passFunc( t )
		passes = t
	end

	----
	local function sourceFunc( name )
		if type( name ) ~= 'string' then
			error( 'source name expected' )
		end

		local function sourceUpdater( src )
			if type( src ) ~= 'string' then
				error( 'source string expected:' .. name )
			end
			if sourceItems[ name ] then
				error( 'redefining source:' .. name )
			end
			local info = debug.getinfo( 2, 'l' )
			local currentline = info[ 'currentline' ]
			local lineCount = src:count( '\n' ) + 1
			local prefix = string.rep( '\n', currentline - lineCount - 2 )
			local output = prefix..src
			sourceItems[ name ] = {
				tag = 'source',
				name = name,
				data = output
			}
		end
		return sourceUpdater
	end

	----
	local function shaderFunc( name )
		if type( name ) ~= 'string' then
			error( 'shader name expected' )
		end
		local function shaderUpdater( data )
			if type( data ) ~= 'table' then
				error( 'table expected for shader:' .. name )
			end
			if shaderItems[ name ] then
				error( 'redefining shader:' .. name )
			end
			shaderItems[ name ] = {
				tag  = 'shader',
				name = name,
				data = data
			}
		end
		return shaderUpdater
	end

	local env = {
		pass       = passFunc;
		shader     = shaderFunc;
		source     = sourceFunc;
	}

	setmetatable( env, { __index = _ShaderScriptLoaderEnv } )
	local func, err = loadstring( src, filename )
	if not func then
		_warn( 'failed loading shader script' )
		print( err )
		return false
	end

	setfenv( func, env )
	local ok, err = pcall( func )
	if not ok then
		_warn( 'failed evaluating shader script' )
		print( err )
		return false
	end

	local sourceEnv = setmetatable( {}, { __index = sharedSourceEnv } )

	local sources = {}
	local shaders = {}
	--process sourceItems
	for _, sourceItem in pairs( sourceItems ) do
		local raw = sourceItem.data
		local preprocessed, err = preprocess( raw, sourceEnv, sourceItem.name )
		if not preprocessed then
			_warn( 'failed loading source entry', sourceItem.name, err )
			return false
		end
		sourceItem.preprocessed = preprocessed
	end

	--process shaderItems
	local function processSource( configData, sourceType, input )
		if type( input ) ~= 'string' then
			_warn( 'invalid shader source entry', sourceType )
			return false
		end
		local ref = input:match( '@(.*)' )
		if ref then
			if getAssetType( ref ) ~= 'glsl' and  getAssetType( ref ) ~= sourceType then
				_warn( 'invalid shader source entry', sourceType, ref )
				return false
			end
			local src = loadAsset( ref )
			if type( src ) ~= 'string' then
				_warn( 'referenced shader source not loaded', sourceType, ref )
				return false
			end
			configData[ sourceType ] = {
				type = 'source',
				data = src
			}
			return true
		else
			local item = sourceItems[ input ]
			if not item then
				_warn( 'inline source not found', input )
				return false
			end
			configData[ sourceType ] = {
				type = 'source',
				data = item.preprocessed
			}
		end
	end

	----
	local shaderConfigs = {}

	for shaderName, shaderItem in pairs( shaderItems ) do
		--verify
		local shaderConfigData = {
		}
		shaderConfigs[ shaderName ] = shaderConfigData

		for k, v in pairs( shaderItem.data ) do
			if k == 'attribute' then
				local attributes = {}
				for i, attrName in ipairs( v ) do
					if not type( attrName ) == 'string' then
						_warn( 'invalid attribute entry', shaderItem.name, attrName )
					else
						table.insert( attributes, attrName )
					end
				end
				shaderConfigs.attributes = attributes

			elseif k == 'uniform' then
				local uniforms = {}
				local globals = {}
				for varName, varItem in pairs( v ) do
					local tag = varItem.tag
					if not (
							type( varItem ) == 'table'
							and ( tag == 'uniform' or tag == 'global' ) 
						)
					then
						_warn( 'invalid uniform entry', shaderItem.name, varName )
					else
						if tag == 'uniform' then
							local entry = {
								name = varName,
								type = varItem.type,
								value = varItem.value
							}
							table.insert( uniforms, entry )

						elseif tag == 'global' then
							local entry = {
								name = varName,
								type = varItem.type,
							}
							table.insert( globals, entry )

						end
					end
				end
				shaderConfigData.uniforms = uniforms 
				shaderConfigData.globals = globals

			elseif k == 'program_tessellation' then
				processSource( shaderConfigData, 'tsh', v )

			elseif k == 'program_geometry' then
				processSource( shaderConfigData, 'gsh', v )

			elseif k == 'program_vertex'   then
				processSource( shaderConfigData, 'vsh', v )

			elseif k == 'program_fragment' then
				processSource( shaderConfigData, 'fsh', v )

			else
				_warn( 'unknown shader field', tostring(k) )
			end
		end

	end

	local entry = shaderConfigs[ 'main' ]
	if not entry then
		_warn( 'no entry shader' )
		return false
	end
	return entry
end


---------------------------------------------------------------------
CLASS: ShaderScriptConfig ( ShaderConfig )

function ShaderScriptConfig:loadFromAssetNode( node )
	local src = loadTextData( node:getObjectFile('src') )
	if not src then return false end
	return self:loadFromSource( src, node:getPath() )
end

function ShaderScriptConfig:loadFromSource( src, name )
	local configData = _loadShaderScript( src, name )
	if not configData then return false end
	return self:loadConfig( configData )
end

--------------------------------------------------------------------
local function ShaderScriptLoader( node )
	local config = node.cached.config
	if not config then
		config = ShaderScriptConfig()
		node.cached.config = config
	end
	if config:loadFromAssetNode( node ) then
		return config:affirmShader( 'default' )
	else
		return false
	end
end

local function ShaderScriptUnloader( node, asset, cached )
	cached.config = node.cached.config --keep the config
end


registerAssetLoader ( 'shader_script', ShaderScriptLoader, ShaderScriptUnloader )

