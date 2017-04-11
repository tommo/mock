module 'mock'

local function buildHueShader()
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
        uniform float hueOffset;

        vec3 rgb2hsv(vec3 c)
        {
            vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
            vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
            vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

            float d = q.x - min(q.w, q.y);
            float e = 1.0e-10;
            return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
        }

        vec3 hsv2rgb(vec3 c)
        {
            vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

        void main ()
        {
            // Sample the input pixel
            vec4 color = texture2D(sampler, uvVarying);
            vec3 hue = rgb2hsv( color.rgb );
            hue.r += hueOffset;
            vec3 rgb = hsv2rgb( hue );
            color.r = rgb.r;
            color.g = rgb.g;
            color.b = rgb.b;
            gl_FragColor    = color;
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
                name = "hueOffset",
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
CLASS: CameraImageEffectHue ( CameraImageEffect )
    :MODEL{
        Field 'hueOffset' :float() :onset( 'updateHueOffset' ) :meta{ step = 0.1 };
    }

function CameraImageEffectHue:__init()
    self.hueOffset = 0
end

function CameraImageEffectHue:onBuild( prop, layer )
    self.shader = buildHueShader()
    prop:setShader( self.shader:getMoaiShader() )
    self:updateHueOffset()
end

function CameraImageEffectHue:updateHueOffset()
    if not self.shader then return end
    self.shader:setAttr( 'hueOffset', self.hueOffset )
end

function CameraImageEffectHue:setHueOffset( h )
    self.hueOffset = h
    self:updateHueOffset()
end

mock.registerComponent( 'CameraImageEffectHue', CameraImageEffectHue )