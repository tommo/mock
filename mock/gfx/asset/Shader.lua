module 'mock'


local _DEFAULT_VSH = [[
	vec4 position;
	vec2 uv;
	vec4 color;

	varying MEDP vec2 uvVarying;
	void main () {
		gl_Position = position;
		uvVarying = uv;
	}
]]


local _DEFAULT_FSH = [[
	varying MEDP vec2 uvVarying;
	uniform sampler2D sampler;

	void main () {
		gl_FragColor = texture2D ( sampler, uvVarying );
	}
]]


--------------------------------------------------------------------
function buildShaderProgramFromString( vsh, fsh, variables )
	local prog = ShaderProgram()
	if variables then
		prog.uniforms = variables.uniforms or {}
		prog.globals  = variables.globals or {}
	end
	prog:buildFromSource( vsh, fsh )
	return prog
end

local loadedShaderPrograms = table.weak_k{}

function releaseShaderProgram( vshPath, fshPath )
	local term = (vshPath or '') .. '|' .. (fshPath or '')
	local torelease = {}
	for key, prog in pairs( loadedShaderPrograms ) do
		if key:find( term ) then 
			torelease[ key ] = true
		end
	end

	for key in pairs( torelease ) do
		local prog = loadedShaderPrograms[ key ]
		loadedShaderPrograms[ key ] = nil
		--TODO: release shaders?
	end
end

function getShaderPrograms()
	return loadedShaderPrograms
end

function getLoadedShaderProgram( path )
	return loadedShaderPrograms[ path ]
end


--------------------------------------------------------------------
CLASS: ShaderProgram ()
	:MODEL{
		Field 'vsh' :asset( 'vsh' );
		Field 'fsh' :asset( 'fsh' );
	}

--------------------------------------------------------------------
CLASS: Shader ()
	:MODEL{}

--------------------------------------------------------------------
--class shader program
--------------------------------------------------------------------
function ShaderProgram:__init()
	self.prog =  MOAIShaderProgram.new()
	self.uniformTable = {}
	self.built = false

	self.vsh = false
	self.fsh = false
	
	self.vshSrc = false
	self.fshSrc = false

	self.uniforms   = {}
	self.attributes = false
	self.shaders    = table.weak_k()
end

function ShaderProgram:getMoaiShaderProgram()
	return self.prog
end

function ShaderProgram:build( force )
	if self.built and not force then return end
	local vshSource
	local fshSource

	if self.vsh == '__default_vsh__' then
		vshSource = _DEFAULT_VSH
	else
		vshSource = mock.loadAsset( self.vsh )
	end

	if self.fsh == '__default_fsh__' then
		fshSource = _DEFAULT_FSH
	else
		fshSource = mock.loadAsset( self.fsh )
	end
	
	return self:buildFromSource( vshSource, fshSource )
end

function ShaderProgram:buildFromSource( vshSource, fshSource )
	local prog  = self.prog

	self.vshSource = vshSource
	self.fshSource = fshSource

	prog:purge()
	prog:load( vshSource, fshSource )
	prog._source = self

	--setup variables
	local attrs = self.attributes or {'position', 'uv', 'color'}
	if attrs then
		for i, a in ipairs(attrs) do
			assert( type(a)=='string' )
			prog:setVertexAttribute( i, a )
		end
	end
	local uniformTable = {}

	local globals  = self.globals
	local uniforms = self.uniforms
	local gcount = ( globals and #globals or 0 ) 
	local ucount = ( uniforms and #uniforms or 0 )

	if ( gcount + ucount ) > 0 then
		prog:reserveUniforms( gcount + ucount )
		if gcount > 0 then
			prog:reserveGlobals( gcount )
			for i, g in ipairs( globals ) do
				local idx = i
				local name = g.name
				local tt = g.type
				if tt == 'GLOBAL_PEN_COLOR' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_VECTOR_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_PEN_COLOR )
				elseif tt == 'GLOBAL_VIEW_PROJ' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_VIEW_PROJ )
				elseif tt == 'GLOBAL_VIEW_WIDTH' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_FLOAT )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_VIEW_WIDTH )
				elseif tt == 'GLOBAL_VIEW_HEIGHT' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_FLOAT )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_VIEW_HEIGHT )
				elseif tt == 'GLOBAL_WORLD' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_WORLD )
				elseif tt == 'GLOBAL_WORLD_VIEW' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_WORLD_VIEW )
				elseif tt == 'GLOBAL_WORLD_VIEW_PROJ_NORM' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F3 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_WORLD_VIEW_PROJ_NORM )
				elseif tt == 'GLOBAL_WORLD_VIEW_PROJ' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_WORLD_VIEW_PROJ )
				elseif tt == 'GLOBAL_WORLD_INV' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_WORLD_INV )				
				elseif tt == 'GLOBAL_WORLD_VIEW_INV' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_WORLD_VIEW_INV )				
				elseif tt == 'GLOBAL_WORLD_VIEW_PROJ_INV' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_WORLD_VIEW_PROJ_INV )				
				else
					error( 'unkown shader global uniform type:' .. tostring( tt ) )
				end
				-- uniformTable[ name ] = idx
			end
		end

		if ucount > 0 then
			for i, u in ipairs(uniforms) do
				local idx = i + gcount
				local utype  = u.type
				local uvalue = u.value
				local name   = u.name
				if     utype == 'float' then
					prog:declareUniformFloat( idx, name, uvalue or 0 )

				elseif utype == 'int' then
					prog:declareUniformInt( idx, name, uvalue or 0 )	

				elseif utype == 'vec' then
					_warn( 'TODO' )

				elseif utype == 'color' then
					prog:declareUniform( idx, name, MOAIShader.UNIFORM_COLOR )

				elseif utype == 'sampler' then
					prog:declareUniformSampler( idx, name, uvalue or 1 )

				elseif utype == 'transform' then
					prog:declareUniform( idx,name, MOAIShader.UNIFORM_TRANSFORM )

				elseif utype == 'pen_color' then
					prog:declareUniform( idx,name,MOAIShader.UNIFORM_PEN_COLOR )

				elseif utype == 'view_proj' then
					prog:declareUniform( idx,name,MOAIShader.UNIFORM_VIEW_PROJ )

				elseif utype == 'world_view_proj' then
					prog:declareUniform( idx,name,MOAIShader.UNIFORM_WORLD_VIEW_PROJ )

				end
				uniformTable[ name ] = idx
			end
		end
	
	end
	self.uniformTable = uniformTable
	self.built = true
	for key, shader in pairs( self.shaders ) do
		shader:setProgram( self )
	end
end

function ShaderProgram:buildShader( key )	
	if not self.built then self:build() end
	local shader = Shader()
	shader:setProgram( self )
	shader._id = key
	key = key or shader
	self.shaders[ key ] = shader
	return shader
end

function ShaderProgram:findShader( key )	
	return self.shaders[ key ]
end

function ShaderProgram:releaseShader( id )
	local shader = self.shaders[ id ]
	if not shader then
		-- _warn( 'no shader found', id )
		return false
	end
	self.shaders[ id ] = nil
end

function ShaderProgram:affirmShader( key )	
	local shader = self:findShader( key )
	if not shader then
		return self:buildShader( key )
	end
	return shader
end


--------------------------------------------------------------------
--class shader
--------------------------------------------------------------------
local shaders = table.weak()
function reportShader()
	print( 'remaining shaders:')
	for shader in pairs( shaders ) do
		local id = shader._id
		if type( id ) == 'table' then
			print( '>>', id.__name, shader.released )
		else
			-- print( shader._id )
		end
	end
end

function Shader:__init()
	self.shader = MOAIShader.new()
	self.shader.parent = self
	shaders[ self ] = true
end

function Shader:release()
	if self.prog then
		self.prog:releaseShader( self._id )
	end
	if self.config then
		self.config:releaseShader( self._id )
	end
	self.shader.parent = nil
	self.released = true
end

function Shader:setProgram( prog )
	self.prog = prog
	self.shader:setProgram( prog:getMoaiShaderProgram() )
end

function Shader:getProgram()
	return self.prog
end

function Shader:getMoaiShader()
	return self.shader
end

function Shader:getAttrId( name )	
	return self.prog.uniformTable[ name ]
end

function Shader:hasAttr( name )
	return self:getAttrId( name ) and true or false
end

function Shader:setAttr( name, v )
	local id = self.prog.uniformTable[ name ]
	if not id then error('undefined uniform:'..name, 2) end
	return self.shader:setAttr( id, v )
end

function Shader:setAttrById( id, v )
	return self.shader:setAttr( id, v )
end

function Shader:setAttrByIdUnsafe( id, v )
	return self.shader:setAttrUnsafe( id, v )
end

function Shader:setAttrLink( name, node, id1 )
	local id = self.prog.uniformTable[ name ]
	if not id then error('undefined uniform:'..name, 2) end
	self.shader:setAttrLink( id, node, id1 )
end

function Shader:seekAttr( name, v, duration, ease )
	--Future...
	-- local id = self.prog.uniformTable[ name ]
	-- if not id then error('undefined uniform:'..name, 2) end
	-- return self.shader:seekAttr( id, v, duration, ease )
end

function Shader:moveAttr( name, v, duration, ease )
	--Future...
	-- local id = self.prog.uniformTable[ name ]
	-- if not id then error('undefined uniform:'..name, 2) end
	-- return self.shader:moveAttr( id, v, duration, ease )
end


--------------------------------------------------------------------
CLASS: MultiShader ( Shader )
	:MODEL{}

function MultiShader:__init()
	self.shader = MOAIMultiShader.new()
	self.shader.parent = self
	self.subShaders = {}
end

function MultiShader:init( maxPass )
	self.shader:reserve( maxPass + 1 )
end

function MultiShader:release()
	for k, sub in pairs( self.subShaders ) do
		sub:release()
	end
	if self.config then
		self.config:releaseShader( self._id )
	end
	self.shader.parent = nil
end

function MultiShader:setSubShader( pass, shader )
	self.subShaders[ pass ] = shader
	self.shader:setSubShader( pass + 1, shader:getMoaiShader() )
	if pass == 0 then
		self:setDefaultShader( shader )
	end
end

function MultiShader:getSubShader( pass )
	return self.subShaders[ pass ]
end

function MultiShader:setDefaultShader( shader )
	self.defautlSubShader = shader
	self.shader:setDefaultShader( shader:getMoaiShader() )
end


--------------------------------------------------------------------
--SINGLE SHADER
--------------------------------------------------------------------
--------------------------------------------------------------------
CLASS: ShaderConfig ()

function ShaderConfig:__init()
	self.shaderType = 'single'
	self.subShaders = {}
	self.program = false
	self.shaders = table.weak_k()
	self.shared  = true
end

function ShaderConfig:loadMultiShader( data )
	self.shaderType = 'multi'
	local passCount = 0
	local maxPass = 0
	for i, subData in ipairs( data['shaders' ] ) do
		local pass = subData['pass'] or 0
		local shared = subData['shared'] ~= false
		if pass > maxPass then maxPass = pass end
		if self.subShaders[ pass ] then
			_warn( 'duplicated shader pass' )
		else
		end
		local path = subData[ 'path' ]
		local childShaderConfig = loadShaderConfig( path )
		self.subShaders[ pass ] = assert( childShaderConfig )
	end
	self.maxPass = maxPass
end

function ShaderConfig:loadSingleShader( data )
	self.shaderType = 'single'
	local prog = ShaderProgram()
	prog.vsh = data['vsh'] or '__default_vsh__'
	prog.fsh = data['fsh'] or '__default_fsh__'
	prog.uniforms   = data['uniforms'] or {}
	prog.globals    = data['globals'] or {}
	prog.attributes = data['attributes'] or false
	prog:build()
	prog.config = self
	loadedShaderPrograms[ self ] = prog
	self.program = prog
end

function ShaderConfig:loadConfig( data )
	if data['shaders'] then
		self:loadMultiShader( data )		
		return true
	else --single shader config
		self:loadSingleShader( data )
		return true
	end
end

function ShaderConfig:build( force )
	if self.built then return end
	if self.program then
		self.program:build( force )
	end
	for pass, subConfig in pairs( self.subShaders ) do
		subConfig:build( force )
	end
	self.built = true
end

function ShaderConfig:buildMultiShader( id )
	local shader = MultiShader()
	shader:init( self.maxPass )
	for pass, subConfig in pairs( self.subShaders ) do
		local subShader = subConfig:affirmShader( id )
		shader:setSubShader( pass, subShader )
	end
	return shader
end

function ShaderConfig:buildShader( id )
	self:build()
	local shader
	if self.shaderType == 'multi' then --build multiple shader
		shader = self:buildMultiShader( id )
	else
		shader = self.program:buildShader( id )
	end
	shader._id = id
	shader.config = self
	self.shaders[ id ] = shader
	return shader
end

function ShaderConfig:getShader( id )
	return self.shaders[ id ]
end

function ShaderConfig:affirmShader( id )
	local shader = self:getShader( id )
	if not shader then shader = self:buildShader( id ) end
	return shader
end

function ShaderConfig:releaseShader( id )
	local shader = self.shaders[ id ]
	if not shader then
		-- _warn( 'no shader found', id )
		return false
	end
	for pass, subConfig in pairs( self.subShaders ) do
		subConfig:releaseShader( id )
	end
	self.shaders[ id ] = nil
end


--------------------------------------------------------------------
--------------------------------------------------------------------

local function shaderLoader( node )
	local data = loadAssetDataTable( node:getObjectFile('def') )
	if not data then return false end
	local config = ShaderConfig()
	config:loadConfig( data )
	node.cached.config = config
	return config:affirmShader( 'default' )	
end

local function shaderSourceLoader( node )
	local data = loadTextData( node:getObjectFile('src') )
	return data
end

function buildShader( shaderPath, id )
	local shader = loadAsset( shaderPath )
	if id then
		if shader then
			return shader.config:affirmShader( id )
		end
	end
	return shader
end

function loadShaderConfig( path )
	local shader = loadAsset( path )
	return shader.config
end

registerAssetLoader ( 'shader', shaderLoader   )
registerAssetLoader ( 'vsh', shaderSourceLoader )
registerAssetLoader ( 'fsh', shaderSourceLoader )

