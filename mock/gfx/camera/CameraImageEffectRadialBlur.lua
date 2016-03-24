module 'mock'

local function buildRadialBlurShader()
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
		uniform float viewWidth;
		uniform float viewHeight;
		uniform float intensity;

		void main () {
			vec2 diff = vec2( 0.5, 0.5 ) - uvVarying;
			gl_FragColor = texture2D ( sampler, uvVarying );
			gl_FragColor += texture2D ( sampler, uvVarying - diff * 0.01 * intensity );
			gl_FragColor += texture2D ( sampler, uvVarying + diff * 0.01 * intensity );

			gl_FragColor += texture2D ( sampler, uvVarying - diff * 0.02 * intensity ) * 0.5;
			gl_FragColor += texture2D ( sampler, uvVarying + diff * 0.02 * intensity ) * 0.5;

			gl_FragColor /= 4.0;
		}
	]]

	local prog = buildShaderProgramFromString( vsh, fsh, {
		uniforms = {
			{
				name = "sampler",
				type = "sampler",
				value = 1
			},
			{
				name = "time",
				type = "float",
				value = 0
			},
			{
				name = "intensity",
				type = "float",
				value = 2
			}
		},
		globals = {
			{
				name = 'viewWidth',
				type = 'GLOBAL_VIEW_WIDTH',
			},
			{
				name = 'viewHeight',
				type = 'GLOBAL_VIEW_HEIGHT',
			}
		}
	} )
	return prog:buildShader()
end

--------------------------------------------------------------------
CLASS: CameraImageEffectRadialBlur ( CameraImageEffect )
	:MODEL{
		Field 'intensity' :onset( 'updateIntensity' ) :meta{ step=0.1 };
	}

function CameraImageEffectRadialBlur:__init()
	self.intensity = 1
	self.shader = false
end

function CameraImageEffectRadialBlur:getPassCount()
	return 1
end

function CameraImageEffectRadialBlur:onBuild( prop, frameBuffer, layer, passId )
	self.shader = buildRadialBlurShader()
	prop:setShader( self.shader:getMoaiShader() )
	self:updateIntensity()
end

function CameraImageEffectRadialBlur:updateIntensity()
	if not self.shader then return end
	self.shader:setAttr( 'intensity', self.intensity )
end

mock.registerComponent( 'CameraImageEffectRadialBlur', CameraImageEffectRadialBlur )