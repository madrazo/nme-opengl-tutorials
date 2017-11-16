package;

import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;

import nme.Assets;

class Main extends Sprite {

    public function new () {
        
        super ();

        //Displaying a Bitmap
        var logo = new Bitmap ( Assets.getBitmapData ("assets/nme.png") );
        logo.x =  (stage.stageWidth - logo.width) / 2;
        logo.y =  (stage.stageHeight - logo.height) / 2;
        addChild (logo);

        var bitmapData = Assets.getBitmapData ("assets/elephant1_Diffuse.png");
        var bitmapData_n = Assets.getBitmapData ("assets/elephant1_Normal.png");
        var bitmap = new Bitmap ( bitmapData );
        bitmap.x =  (stage.stageWidth - bitmap.width) / 2;
        bitmap.y =  (stage.stageHeight - bitmap.height) / 2;
        addChild (bitmap);

        //Objects that use OGLView
        {
	        var shaderProgram_texturemaping =  nme.gl.Utils.createProgram(vs, fs_texturemap);
	        var colorElephant:ShaderBitmap = new ShaderBitmap(shaderProgram_texturemaping, [bitmapData]);
	        colorElephant.x = ( (stage.stageWidth) / 2 ) -100;
	        colorElephant.y = (stage.stageHeight) / 2;

	        var shaderProgram_bumpmaping =  nme.gl.Utils.createProgram(vs, fs_bumpmap);
	        var bumpElephant:ShaderBitmap = new ShaderBitmap(shaderProgram_bumpmaping, [bitmapData, bitmapData_n]);
	        bumpElephant.x = ( (stage.stageWidth) / 2) + 100;
	        bumpElephant.y = (stage.stageHeight) / 2;

	        addChild(bumpElephant);
	        addChild(colorElephant);
	    }
    }


        public var vs = 
"   attribute vec3 vertexPosition;
    attribute vec2 texPosition;
    uniform mat4 modelViewMatrix;
    uniform mat4 projectionMatrix;
    varying vec2   vTexCoord;
    void main() {            
        vTexCoord = texPosition;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(vertexPosition, 1.0);
    }
";

//Pixel shader with one texture
        public var fs_texturemap = 
"   varying vec2 vTexCoord;

    uniform sampler2D color_texture;   
    //uniform float time;
    //uniform vec2 mouse;
    //uniform vec2 resolution;
  
    void main() {  
        // Set the output color of our current pixel  
        gl_FragColor = texture2D(color_texture, vTexCoord).bgra;  //testing: rgba->bgra
    }  
";

//Pixel shader with two textures
        public var fs_bumpmap = 
 "  varying vec2 vTexCoord;
    uniform sampler2D color_texture;
    uniform sampler2D normal_texture;
    uniform float time;
    uniform vec2 mouse;
    //uniform vec2 resolution;

    void main() {
        // Extract the normal from the normal map
        vec3 normal = normalize(texture2D(normal_texture, vTexCoord).rgb * 2.0 - 1.0);
        // Determine where the light is positioned
        vec3 light_pos = normalize(vec3(mouse.xy, 1.5));
        // Calculate the lighting diffuse value
        float diffuse = max(dot(normal, light_pos), 0.0);
        vec4 color  = texture2D(color_texture, vTexCoord).rgba;
        vec3 color1 = diffuse * color.rgb;
        // Set the output color of our current pixel
        gl_FragColor = vec4(color1,color.a);
    }
"
;
}
