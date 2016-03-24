module 'mock'

local function buildMosaicShader()
	local vsh = [[
		attribute vec4 position;
		attribute vec2 uv;
		attribute vec4 color;

		uniform float viewWidth;
		uniform float viewHeight;
		uniform float size;

		varying LOWP vec4 colorVarying;
		varying MEDP vec2 uvVarying;

		varying LOWP vec2 uvStep;

		void main () {
			gl_Position = position;
			uvStep.x = 1.0/viewWidth  * size;
			uvStep.y = 1.0/viewHeight  * size;
			uvVarying = uv;
			colorVarying = color;
		}
	]]

	local fsh = [[	
		varying LOWP vec4 colorVarying;
		varying MEDP vec2 uvVarying;
		varying LOWP vec2 uvStep;

		uniform sampler2D sampler;

		void main () {
			MEDP vec2 uv;
			uv.x = floor( uvVarying.x / uvStep.x ) * uvStep.x;
			uv.y = floor( uvVarying.y / uvStep.y ) * uvStep.y;
			gl_FragColor = texture2D ( sampler, uv );
		}
	]]

	local prog = buildShaderProgramFromString( vsh, fsh , {
			uniforms = {
				{
					name = "sampler",
					type = "sampler",
					value = 1
				},
				{
					name = "size",
					type = "float",
					value = 4.0
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
CLASS: CameraImageEffectMosaic ( CameraImageEffect )
	:MODEL{
		Field 'size' :onset( 'updateSize' ) :meta{ step = 1 } :range(1);
}

function CameraImageEffectMosaic:__init()
	self.size = 4
	self.shader = false
end

function CameraImageEffectMosaic:onBuild( prop, layer )
	self.shader = buildMosaicShader()
	prop:setShader( self.shader:getMoaiShader() )
	self:updateSize()
end

function CameraImageEffectMosaic:updateSize()
	if not self.shader then return end
	self.shader:setAttr( 'size', self.size )
end

mock.registerComponent( 'CameraImageEffectMosaic', CameraImageEffectMosaic )
