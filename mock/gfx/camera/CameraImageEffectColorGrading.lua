module 'mock'

local function buildLUTShader()
	local vsh = [[
		attribute vec4 position;
		attribute vec2 uv;
		attribute vec4 color;

		varying LOWP vec4 colorVarying;
		varying MEDP vec2 uvVarying;

		void main () {
			gl_Position = position;
			uvVarying = uv;
			colorVarying = color;
		}
	]]

	local fsh = [[	
		varying LOWP vec4 colorVarying;
		varying MEDP vec2 uvVarying;

		uniform sampler2D sampler;
		uniform sampler2D samplerLUT1;
		uniform sampler2D samplerLUT2;
		uniform float size1;
		uniform float size2;
		uniform float LUTMix;
		uniform float intensity;

		vec4 sampleAs3DTexture( sampler2D texture, vec3 uv, float width ) {
			float sliceSize = 1.0 / width;              // space of 1 slice
			float slicePixelSize = sliceSize / width;           // space of 1 pixel
			float sliceInnerSize = slicePixelSize * (width - 1.0);  // space of width pixels
			float zSlice0 = min(floor(uv.z * width), width - 1.0);
			float zSlice1 = min(zSlice0 + 1.0, width - 1.0);
			float xOffset = slicePixelSize * 0.5 + uv.x * sliceInnerSize;
			float s0 = xOffset + (zSlice0 * sliceSize);
			float s1 = xOffset + (zSlice1 * sliceSize);
			vec4 slice0Color = texture2D(texture, vec2(s0, uv.y));
			vec4 slice1Color = texture2D(texture, vec2(s1, uv.y));
			float zOffset = mod(uv.z * width, 1.0);
			vec4 result = mix(slice0Color, slice1Color, zOffset);
			return result;
		}

		void main () {
			LOWP vec4 pixel = texture2D ( sampler, uvVarying );
			vec4 gradedPixel = mix(
					sampleAs3DTexture( samplerLUT1, pixel.rgb, size1 ), 
					sampleAs3DTexture( samplerLUT2, pixel.rgb, size2 ),
					LUTMix
				);
			gradedPixel.a = pixel.a;
		  gl_FragColor = mix(pixel, gradedPixel, intensity );
		}

	]]

	local vars = {
		uniforms = {
			{
				name  = "sampler",
				type  = "sampler",
				value = 1
			},
			{
				name  = "samplerLUT1",
				type  = "sampler",
				value = 2
			},
			{
				name  = "samplerLUT2",
				type  = "sampler",
				value = 3
			},
			{
				name = "size1",
				type = "float",
				value = 32.0
			},
			{
				name = "size2",
				type = "float",
				value = 32.0
			},
			{
				name = "LUTMix",
				type = "float",
				value = 0.0
			},
			{
				name = "intensity",
				type = "float",
				value = 1.0
			}
		}
	}
	local prog = buildShaderProgramFromString( vsh, fsh, vars )
	return prog:buildShader()
end

--------------------------------------------------------------------
CLASS: CameraImageEffectColorGrading ( CameraImageEffect )
	:MODEL{
		Field 'LUT'  :asset( 'texture;color_grading' ) :getset( 'LUT' );
		Field 'LUT2' :asset( 'texture;color_grading' ) :getset( 'LUT2' );
		Field 'mix'  :onset( 'updateMix' ) :range(0,1) :meta{ step = 0.1 } :widget('slider');
		Field 'intensity' :onset( 'updateIntensity' ) :meta{ step = 0.1 };
}

function CameraImageEffectColorGrading:__init()
	self.intensity = 1
	self.lutPath = false
	self.lutPath2 = false
	self.lutTex1  = false
	self.lutTex2  = false
	self.size1 = 32
	self.size2 = 32
	self.mix   = 0
	self.tex = MOAIMultiTexture.new()
	self.tex:reserve( 3 )
end

function CameraImageEffectColorGrading:onBuild( prop, texture, layer, passId )
	self.shader = buildLUTShader()
	self.tex:setTexture( 1, texture )
	prop:setTexture( self.tex )
	prop:setShader( self.shader:getMoaiShader() )
	self:updateIntensity()
	self:updateMix()
end

function CameraImageEffectColorGrading:setLUT( path )
	self.lutPath = path
	local atype = getAssetType( path )
	if atype == 'color_grading' then
		self.lutTex1 = mock.loadAsset( path ):getTexture()
	elseif atype == 'texture' then
		local t = mock.loadAsset( path )
		self.lutTex1 = t and t:getMoaiTexture()
	end
	return self:updateTex()
end

function CameraImageEffectColorGrading:getLUT()
	return self.lutPath
end

function CameraImageEffectColorGrading:setLUT2( path )
	self.lutPath2 = path
	local atype = getAssetType( path )
	if atype == 'color_grading' then
		self.lutTex2 = mock.loadAsset( path ):getTexture()
	elseif atype == 'texture' then
		local t = mock.loadAsset( path )
		self.lutTex2 = t and t:getMoaiTexture()
	end
	return self:updateTex()
end

function CameraImageEffectColorGrading:getLUT2()
	return self.lutPath2
end

local function getTextureSize( tex )
	local w, h = tex:getSize()
	if w == 0 and tex._ownerObject then
		return tex._ownerObject:getSize()
	end
	return w, h 
end

function CameraImageEffectColorGrading:updateTex()
	local t1 ,t2 = self.lutTex1, self.lutTex2
	self.tex:setTexture( 2, t1 )
	self.tex:setTexture( 3, t2 )
	local h1 = 32
	local h2 = 32
	if t1 then
		local w, h = getTextureSize( t1 )
		h1 = h
	end
	if t2 then
		local w, h = getTextureSize( t2 )
		h2 = h
	end
	self.size1 = h1
	self.size2 = h2
	self:updateMix()
	self:updateIntensity()
end

function CameraImageEffectColorGrading:setMix( mix )
	self.mix = mix
	return self:updateMix()
end

function CameraImageEffectColorGrading:updateMix()
	if not self.shader then return end
	local a, b = self.lutTex1, self.lutTex2
	self.shader:setAttr( 'size1', self.size1 )
	self.shader:setAttr( 'size2', self.size2 )
	if a and b then
		return self.shader:setAttr( 'LUTMix', self.mix )
	else
		if b then
			return self.shader:setAttr( 'LUTMix', 1 )
		else
			return self.shader:setAttr( 'LUTMix', 0 )
		end
	end
end

function CameraImageEffectColorGrading:updateIntensity()
	if not self.shader then return end
	if not self.lutPath then
		return self.shader:setAttr( 'intensity', 0 )
	else
		return self.shader:setAttr( 'intensity', self.intensity )
	end
end

mock.registerComponent( 'CameraImageEffectColorGrading', CameraImageEffectColorGrading )

