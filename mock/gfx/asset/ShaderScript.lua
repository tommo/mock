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
			local template, err = loadpreprocess( output, filename )
			if not template then
				print( err )
				error( 'failed loading source:' .. filename )
			end 
			sourceItems[ name ] = {
				tag = 'source',
				name = name,
				data = output,
				template = template
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

	--process shaderItems
	local function processSource( configData, sourceType, input )
		if type( input ) ~= 'string' then
			_warn( 'invalid shader source entry', sourceType )
			return false
		end
		local ref = input:match( '^%s*@(.*)' )
		if ref then
			if getAssetType( ref ) ~= 'glsl' and  getAssetType( ref ) ~= sourceType then
				_warn( 'invalid shader source entry', sourceType, ref )
				return false
			end
			-- local src = loadAsset( ref )
			-- if type( src ) ~= 'string' then
			-- 	_warn( 'referenced shader source not loaded', sourceType, ref )
			-- 	return false
			-- end
			configData[ sourceType ] = {
				type = 'file',
				path = ref
			}
			return true
		else
			local item = sourceItems[ input ]
			if not item then
				_warn( 'inline source not found', input )
				return false
			end
			configData[ sourceType ] = {
				type     = 'source',
				data     = item.data,
				template = item.template
			}
		end
	end

	----
	local shaderDatas = {}

	for shaderName, shaderItem in pairs( shaderItems ) do
		--verify
		local shaderConfigData = {
		}
		shaderDatas[ shaderName ] = shaderConfigData

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
				shaderDatas.attributes = attributes

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

	---
	local passDatas = {}
	local passCount = 0
	local maxPass   = 0
	
	if not passes then --single pass shader
		local defaultShader = shaderDatas[ 'main' ]
		if not defaultShader then
			_warn( 'no main shader or passes defined', path )
			return false
		end
		passes = { ['default'] = 'main' }
	end

	for passId, data in pairs( passes ) do
		if type( passId ) == 'number' then
			passCount = passCount + 1
			maxPass = math.max( maxPass, passId )
		end
		local path = data:match( '^%s*@(.*)')
		if path then
			passDatas[ passId ] = {
				type = 'file',
				path = path
			}
		else
			passDatas[ passId ] = {
				type = 'ref',
				name = data
			}
		end
	end

	return {
		shaders = shaderDatas,
		passes  = passDatas,
		maxPass = maxPass,
	}
end

---------------------------------------------------------------------
CLASS: ShaderScriptConfig ( ShaderConfig )

function ShaderScriptConfig:loadFromAssetNode( node )
	local src = loadTextData( node:getObjectFile('src') )
	if not src then return false end
	return self:loadFromSource( src, '@'..node:getPath() )
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
		config.path = node:getPath()
		node.cached.config = config
	end
	if config:loadFromAssetNode( node ) then
		return config
	else
		return false
	end
end

local function ShaderScriptUnloader( node, asset, cached )
	cached.config = node.cached.config --keep the config
end

registerAssetLoader ( 'shader_script', ShaderScriptLoader, ShaderScriptUnloader )

--------------------------------------------------------------------
local function shaderSourceLoader( node )
	local source = loadTextData( node:getObjectFile('src') )
	if source then
		local template, err = loadpreprocess( source, node:getPath() )
		if template then return template end
		_log( err )
		_error( 'failed processing shader source:' .. filename )
	else
		_error( 'failed loading shader source:' .. filename )
	end
	return false
end

registerAssetLoader ( 'fsh', shaderSourceLoader )
registerAssetLoader ( 'vsh', shaderSourceLoader )
registerAssetLoader ( 'glsl', shaderSourceLoader )


--------------------------------------------------------------------
local function legacyShaderConfigLoader( node )
	local data = loadAssetDataTable( node:getObjectFile('def') or node:getFilePath() )
	if not data then return false end

	if data[ 'multiple' ] then
		local configData = {}
		local passData = {}
		local maxPass = 0
		for i, entry in ipairs( data['shaders'] or {} ) do
			local passId = entry[ 'pass' ]
			if type( passId ) == 'number' then
				maxPass = math.max( maxPass, passId )
			end
			passData[ passId ] = { 
				type = 'file', 
				path = entry['path']
			}
		end
		configData[ 'passes' ]  = passData
		configData[ 'maxPass' ] = maxPass
		configData[ 'shaders' ] = {}

		local config = ShaderConfig()
		config:loadConfig( configData )
		config.path = node:getPath()
		return config
			
	else
		local configData = {}
		local mainShaderData = {
			name = 'main';
			vsh = {
				type = 'file';
				path = data[ 'vsh' ]
				};
			fsh = {
				type = 'file';
				path = data[ 'fsh' ]
				};
			uniforms = data[ 'uniforms' ];
			globals  = data[ 'globals' ];
			attributes  = data[ 'attributes' ];
		}
		configData[ 'passes' ]  = { ['default'] = { type = 'ref', name = 'main' } }
		configData[ 'maxPass' ] = 0
		configData[ 'shaders' ] = { [ 'main' ] = mainShaderData }
		local config = ShaderConfig()
		config:loadConfig( configData )
		config.path = node:getPath()
		return config

	end

end

registerAssetLoader ( 'shader', legacyShaderConfigLoader )

--------------------------------------------------------------------
function buildMasterShader( shaderPath, id, context )
	local shaderConfig = loadAsset( shaderPath )
	if shaderConfig then
		return shaderConfig:affirmShader( id or 'default', context )
	else
		_warn( 'cannot load shaderConfig', shaderPath )
		return false
	end
end

--------------------------------------------------------------------
function buildShader( shaderPath, id, context )
	local master = buildMasterShader( shaderPath, id, context )
	if master then
		return master:getDefaultShader()
	end
	return false
end

