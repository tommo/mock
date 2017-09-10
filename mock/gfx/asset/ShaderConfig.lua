module 'mock'

--------------------------------------------------------------------
local DefaultShaderSource = {}

DefaultShaderSource.__DEFAULT_VSH = [[
	vec4 position;
	vec2 uv;
	vec4 color;

	varying MEDP vec2 uvVarying;
	void main () {
		gl_Position = position;
		uvVarying = uv;
	}
]]

DefaultShaderSource.__DEFAULT_FSH = [[
	varying MEDP vec2 uvVarying;
	uniform sampler2D sampler;

	void main () {
		gl_FragColor = texture2D ( sampler, uvVarying );
	}
]]


--------------------------------------------------------------------
--------------------------------------------------------------------
CLASS: ShaderConfig ()

function ShaderConfig:__init()
	self.name = ''
	self.path = false
	self.shaders = table.weak_k()
	self.dependentConfigs = table.weak_k()
	self.context = {}
end

function ShaderConfig:getPath()
	if not self.path then
		if self.parent then return self.parent:getPath() end
	end
	return false
end

function ShaderConfig:loadConfig( data, path )
	self.path = path
	self.maxPass     = data[ 'maxPass' ]
	self.passes      = data[ 'passes' ]
	self.shaderDatas = data[ 'shaders' ]
	self.baseContext = data[ 'context' ]
	return true
end

function ShaderConfig:buildShader( id, context )
	id = id or 'default'
	local shader0 = self.shaders[ id ]
	context = context or {}
	local builder = ShaderBuilder( self, context )
	local shader = builder:buildMasterShader( self, shader0 )
	shader.context = context
	self.shaders[ id ] = shader
	return shader
end

function ShaderConfig:getShader( id )
	return self.shaders[ id ]
end

function ShaderConfig:affirmShader( id, context )
	local shader = self:getShader( id )
	if not shader then 
		shader = self:buildShader( id, context )
	end
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

function ShaderConfig:rebuildShaders()
	for id, shader0 in pairs( self.shaders ) do
		self:buildShader( id, shader0.context, true )
	end
end

--------------------------------------------------------------------
local sharedSourceEnv = {
	math = math,
	print = print
}

--------------------------------------------------------------------
CLASS: ShaderBuilder ()
	:MODEL{}


local function processContext( context )
	local tt = type( context )
	if tt == 'table' then
		return table.simplecopy( context )

	elseif tt == 'string' then
		return parseSimpleValueList( context )
	end
	return nil
end

function ShaderBuilder:__init( masterConfig, instanceContext )
	self.instanceContext = processContext( instanceContext ) or {}
	self.masterConfig = masterConfig
end

function ShaderBuilder:buildMasterShader( config, shader0, baseContext )
	local entryShader = shader0 or MultiShader()
	assert( entryShader:isInstance( MultiShader ) )

	entryShader:init( config.maxPass )
	entryShader.maseterConfig = self.masterConfig
	
	if self.masterConfig ~= config then
		config.dependentConfigs[ self.masterConfig ] = true
	end

	local envContext = table.merge( baseContext or {}, config.context )
	for id, passEntry in pairs( config.passes ) do
		local subShader = false
		local shaderType = passEntry.type
		if shaderType == 'file' then
			--load referenced shader
			local shaderConfig = loadAsset( passEntry.path )
			if shaderConfig then
				subShader = self:buildMasterShader( shaderConfig, nil, envContext )
			end

		elseif shaderType == 'ref' then
			local shaderData = config.shaderDatas[ passEntry.name ]
			if not shaderData then
				_warn( 'no shader config found', passEntry.name )
			else
				subShader = self:buildSingleShader( shaderData, envContext )
			end

		elseif shaderType == 'config' then
			subShader = self:buildSingleShader( passEntry.data, envContext )

		else
			error( 'unknown sub shader type' .. tostring( shaderType ) )

		end

		if subShader then
			if id == 'default' then
				entryShader:setDefaultShader( subShader )
			else
				entryShader:setSubShader( id, subShader )
			end
		else
			_warn( 'cannot load subshader' )
		end
		
	end
	return entryShader
end

function ShaderBuilder:buildSingleShader( data, envContext )
	local context = table.merge( envContext or {}, data.context or {} )
	context = table.merge( context, self.instanceContext )
	local prog = ShaderProgram()
	prog.vsh, prog.vshPath = self:processSource( data['vsh'] or '__DEFAULT_VSH', context )
	prog.fsh, prog.fshPath = self:processSource( data['fsh'] or '__DEFAULT_FSH', context )
	prog.gsh, prog.gshPath = self:processSource( data['gsh'] or false, context )
	prog.tsh, prog.tshPath = self:processSource( data['tsh'] or false, context )

	--DEBUG:OUTPUT processed source
	-- print( prog.vsh )
	-- print( prog.fsh )
	prog.uniforms   = data['uniforms'] or {}
	prog.globals    = data['globals'] or {}
	prog.attributes = data['attributes'] or false
	prog:build()
	prog.masterConfig = self.masterConfig

	local shader = Shader()
	shader:setProgram( prog )
	shader.maseterConfig = self.masterConfig


	return shader

end

function ShaderBuilder:_doPreprocessor( template, context )
	local sourceEnv = setmetatable( {}, { __index = sharedSourceEnv } )
	sourceEnv.context = context or {}
	local processed, err = template( sourceEnv )
	if not processed then
		_warn( 'failed processing source', self.path )
		return false
	end
	return processed
end

function ShaderBuilder:processSource( src, context )
	if not src then return false end
	local tt = type( src )
	if tt == 'table' then
		local srcType = src.type
		if srcType == 'source' then
			local processed, err = self:_doPreprocessor( src.template, context )
			return processed, false

		elseif srcType == 'file' then
			local template, node = loadAsset( src.path )

			if template then
				local processed, err = self:_doPreprocessor( template, context )
				return processed, src.path
			else
				_warn( 'preprocess template not load?', src.path )
				return false
			end

		else
			return src.data, false

		end

	elseif tt == 'string' then --reference?
		local builtin = DefaultShaderSource[ src ]
		if builtin then return builtin end
		local sourceText = loadAsset( src )
		if sourceText then
			return sourceText, false
		end
		return src, false

	end

	_warn( 'invalid source type', tt )
	return false
end
