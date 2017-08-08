module 'mock'

local function buildEffectNoiseShader()
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
		
		#define BlendColorDodgef(base, blend) 	((blend == 1.0) ? blend : min(base / (1.0 - blend), 1.0))
		#define BlendColorBurnf(base, blend) 	((blend == 0.0) ? blend : max((1.0 - ((1.0 - base) / blend)), 0.0))
		#define BlendVividLightf(base, blend) 	((blend < 0.5) ? BlendColorBurnf(base, (2.0 * blend)) : BlendColorDodgef(base, (2.0 * (blend - 0.5))))
		#define BlendHardMixf(base, blend) 	((BlendVividLightf(base, blend) < 0.5) ? 0.0 : 1.0)

		uniform sampler2D sampler;
		uniform float time;
		uniform float intensity;
		float rand(vec2 co){
			return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
		}

		void main () {
			LOWP vec4 color = texture2D ( sampler, uvVarying );
			float blend = rand( uvVarying * time );
			LOWP vec4 color1;
			color1.r = BlendHardMixf( color.r, blend );
			color1.g = BlendHardMixf( color.g, blend );
			color1.b = BlendHardMixf( color.b, blend );
			//color1.g=color.g;
			//color1.b=color.b;
			color1.a = 1.0;
			float k1 = 1.0 - ( color.r + color.g ) * 0.5;
			gl_FragColor = mix( color, color1, intensity * 0.01 * k1 );
		}
	]]

	local prog = mock.buildShaderProgramFromString( vsh, fsh, {
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
			}
		} )
	return prog:buildShader()
end

--------------------------------------------------------------------
CLASS: CameraImageEffectNoise ( mock.CameraImageEffect )
	:MODEL{
		Field 'intensity' :meta{ step = 0.1 };
}

function CameraImageEffectNoise:__init()
	self.intensity = 1
end

function CameraImageEffectNoise:onStart()
	self._entity.scene:addUpdateListener( self )
end

function CameraImageEffectNoise:onDetach( entity )
	entity.scene:removeUpdateListener( self )
end

function CameraImageEffectNoise:onBuild( prop, texture, layer, passId )
	self.shader = buildEffectNoiseShader()
	prop:setShader( self.shader:getMoaiShader() )
end

function CameraImageEffectNoise:setIntensity( intensity )
	self.intensity = intensity
end

local t = 0
function CameraImageEffectNoise:onUpdate( dt )
	t = t + dt
	local fps = 10
	self.shader:setAttr( 'time',  math.floor( t*fps ) /fps )
	self.shader:setAttr( 'intensity', self.intensity )
end


registerComponent( 'CameraImageEffectNoise', CameraImageEffectNoise )
