import nme.display.Sprite;
import nme.geom.Rectangle;
import nme.display.OpenGLView;
import nme.gl.GL;
import nme.gl.GL3;
import nme.Assets;
import nme.Lib;
import nme.utils.Float32Array;
import nme.text.TextField;
import nme.text.TextFieldAutoSize;

import nme.gl.GLProgram;
import nme.gl.Utils;

import nme.geom.Matrix3D;	
import nme.geom.Vector3D;

import nme.display.BitmapData;

import GLM;
import Controls;
import ObjLoader;

class Main extends Sprite {
    

    var m_controls:Controls;

    public function new ()
    {        
        super ();

        var ogl = new OpenGLView();
        addChild(ogl);

        addDebugText();

        var fragShader:String = 
"// Interpolated values from the vertex shaders
" + Utils.IN() + " vec2 UV;
" + Utils.IN() + " vec3 Position_worldspace;
" + Utils.IN() + " vec3 Normal_cameraspace;
" + Utils.IN() + " vec3 EyeDirection_cameraspace;
" + Utils.IN() + " vec3 LightDirection_cameraspace;

// Ouput data
" + 
Utils.OUT_COLOR("color") +
"

// Values that stay constant for the whole mesh.
uniform sampler2D myTextureSampler;
uniform mat4 MV;
uniform vec3 LightPosition_worldspace;

void main(){
	// Light emission properties
	// You probably want to put them as uniforms
	vec3 LightColor = vec3(1,1,1);
	float LightPower = 50.0f;
	
	// Material properties
	vec3 MaterialDiffuseColor = texture( myTextureSampler, UV ).rgb;
	vec3 MaterialAmbientColor = vec3(0.1,0.1,0.1) * MaterialDiffuseColor;
	vec3 MaterialSpecularColor = vec3(0.3,0.3,0.3);

	// Distance to the light
	float distance = length( LightPosition_worldspace - Position_worldspace );

	// Normal of the computed fragment, in camera space
	vec3 n = normalize( Normal_cameraspace );
	// Direction of the light (from the fragment to the light)
	vec3 l = normalize( LightDirection_cameraspace );
	// Cosine of the angle between the normal and the light direction, 
	// clamped above 0
	//  - light is at the vertical of the triangle -> 1
	//  - light is perpendicular to the triangle -> 0
	//  - light is behind the triangle -> 0
	float cosTheta = clamp( dot( n,l ), 0.0 , 1.0);
	
	// Eye vector (towards the camera)
	vec3 E = normalize(EyeDirection_cameraspace);
	// Direction in which the triangle reflects the light
	vec3 R = reflect(-l,n);
	// Cosine of the angle between the Eye vector and the Reflect vector,
	// clamped to 0
	//  - Looking into the reflection -> 1
	//  - Looking elsewhere -> < 1
	float cosAlpha = clamp( dot( E,R ), 0.0, 1.0);
	
	vec3 col =
		// Ambient : simulates indirect lighting
		MaterialAmbientColor +
		// Diffuse : color of the object
		MaterialDiffuseColor * LightColor * LightPower * cosTheta / (distance*distance) +
		// Specular : reflective highlight, like a mirror
		MaterialSpecularColor * LightColor * LightPower * pow(cosAlpha,5.0) / (distance*distance);
		
	color = vec4(col,1.0); 
}
";


      var vertShader:String =
"// Input vertex data, different for all executions of this shader.
" +
Utils.IN(0) + " vec3 vertexPosition_modelspace;
" +
Utils.IN(1) + " vec2 vertexUV;
" +
Utils.IN(2) + " vec3 vertexNormal_modelspace;

// Output data ; will be interpolated for each fragment.
" + Utils.OUT() + " vec2 UV;
" + Utils.OUT() + " vec3 Position_worldspace;
" + Utils.OUT() + " vec3 Normal_cameraspace;
" + Utils.OUT() + " vec3 EyeDirection_cameraspace;
" + Utils.OUT() + " vec3 LightDirection_cameraspace;

// Values that stay constant for the whole mesh.
uniform mat4 MVP;
uniform mat4 V;
uniform mat4 M;
uniform vec3 LightPosition_worldspace;

void main(){
  // Output position of the vertex, in clip space : MVP * position
  gl_Position =  MVP * vec4(vertexPosition_modelspace,1.0);

	// Position of the vertex, in worldspace : M * position
	Position_worldspace = (M * vec4(vertexPosition_modelspace,1)).xyz;
	
	// Vector that goes from the vertex to the camera, in camera space.
	// In camera space, the camera is at the origin (0,0,0).
	vec3 vertexPosition_cameraspace = ( V * M * vec4(vertexPosition_modelspace,1)).xyz;
	EyeDirection_cameraspace = vec3(0,0,0) - vertexPosition_cameraspace;

	// Vector that goes from the vertex to the light, in camera space. M is ommited because it's identity.
	vec3 LightPosition_cameraspace = ( V * vec4(LightPosition_worldspace,1)).xyz;
	LightDirection_cameraspace = LightPosition_cameraspace + EyeDirection_cameraspace;
	
	// Normal of the the vertex, in camera space
	Normal_cameraspace = ( V * M * vec4(vertexNormal_modelspace,0)).xyz; // Only correct if ModelMatrix does not scale the model ! Use its inverse transpose if not.
	

  // The color of each vertex will be interpolated
  // to produce the color of each fragment
  UV = vertexUV;
}
";


        // Enable depth test
        GL.enable(GL.DEPTH_TEST);
        // Accept fragment if it closer to the camera than the former one
        GL.depthFunc(GL.LESS); 

        // NME disable depth test for now
        GL.disable(GL.DEPTH_TEST);


        // Dark blue background: For NME, use "opaqueBackground" instead of "clearColor"
        //GL.clearColor(0.0, 0.0, 0.4, 0.0);
        nme.Lib.stage.opaqueBackground = 0x000066;

        //GLES3
        if (Utils.isGLES3compat())
        {
            var vertexarray = GL3.createVertexArray();
            GL3.bindVertexArray(vertexarray);
        }

        // Create and compile our GLSL program from the shaders
        var prog = Utils.createProgram(vertShader,fragShader);

        // Get a handle for our "MVP" uniform
        var matrixID = GL.getUniformLocation(prog, "MVP");
        var viewMatrixID  = GL.getUniformLocation(prog, "V");
        var modelMatrixID  = GL.getUniformLocation(prog, "M");

        m_controls = new Controls();

        var texture:BitmapData = Assets.getBitmapData("assets/uvmap.png");

        var g_vertex_buffer_data:Array<Float> = [];
        var g_uv_buffer_data:Array<Float> = [];
        var g_normals_buffer_data:Array<Float> = [];
       
        ObjLoader.loadObj("assets/cube.obj", g_vertex_buffer_data, g_uv_buffer_data, g_normals_buffer_data);

        var vertexbuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexbuffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(g_vertex_buffer_data), GL.STATIC_DRAW);

        var uvbuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, uvbuffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(g_uv_buffer_data), GL.STATIC_DRAW);

        var normalbuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, normalbuffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(g_normals_buffer_data), GL.STATIC_DRAW);

        var posAttrib = 0;
	var uvAttrib = 1;
	var normalAttrib = 2;
        if (!Utils.isGLES3compat())
        {
          posAttrib = GL.getAttribLocation(prog, "vertexPosition_modelspace");
          uvAttrib = GL.getAttribLocation(prog, "vertexUV");
	  normalAttrib = GL.getAttribLocation(prog, "vertexNormal_modelspace");
        }

       // Get a handle for our "LightPosition" uniform
        //GL.useProgram(prog);
        var lightID  = GL.getUniformLocation(prog, "LightPosition_worldspace");

        ogl.render = function(rect:Rectangle)
        {

            //NME already calls GL.clear with "opaqueBackground" color
            // Clear the screen.
            //GL.clear(GL.COLOR_BUFFER_BIT);

            // NME: Enable depth test per frame?
            GL.enable(GL.DEPTH_TEST);
            GL.clear(GL.DEPTH_BUFFER_BIT);

            // Use our shader
            GL.useProgram(prog);


            // Compute the MVP matrix from keyboard and mouse input 
            m_controls.computeMatricesFromInputs();
            var model = new Matrix3D();
            var view = m_controls.getViewMatrix();
            var projection = m_controls.getProjectionMatrix();

            var mvp = model;
            mvp.append(view);
            mvp.append(projection);


            // Send our transformation to the currently bound shader, 
            // in the "MVP" uniform
            GL.uniformMatrix4fv(matrixID, false, Float32Array.fromMatrix(mvp));
		GL.uniformMatrix4fv(modelMatrixID, false, Float32Array.fromMatrix(model));
		GL.uniformMatrix4fv(viewMatrixID, false, Float32Array.fromMatrix(view));

		var lightPos = new nme.geom.Vector3D(4,4,4);
		GL.uniform3f(lightID, lightPos.x, lightPos.y, lightPos.z);

            // Bind our texture in Texture Unit 0
            GL.bindBitmapDataTexture( texture );

            // 1rst attribute buffer : vertices
            GL.enableVertexAttribArray(posAttrib);
            GL.bindBuffer(GL.ARRAY_BUFFER, vertexbuffer);
            GL.vertexAttribPointer(
                posAttrib, // attribute 0. No particular reason for 0, but must match the layout in the shader 
                3, // size
                GL.FLOAT, // type
                false, // normalized?
                0, // stride
                0 // array buffer offset
                );

            // 2nd attribute buffer : UVs
            GL.enableVertexAttribArray(uvAttrib);
            GL.bindBuffer(GL.ARRAY_BUFFER, uvbuffer);
            GL.vertexAttribPointer(
                uvAttrib, // attribute 0. No particular reason for 0, but must match the layout in the shader 
                2, // size
                GL.FLOAT, // type
                false, // normalized?
                0, // stride
                0 // array buffer offset
                );

            // 3rd attribute buffer : normals
            GL.enableVertexAttribArray(normalAttrib);
            GL.bindBuffer(GL.ARRAY_BUFFER, normalbuffer);
            GL.vertexAttribPointer(
                normalAttrib, // attribute 
                3, // size
                GL.FLOAT, // type
                false, // normalized?
                0, // stride
                0 // array buffer offset
                );


            // Draw the triangles !
            GL.drawArrays(GL.TRIANGLES, 0, 12*3);
            GL.disableVertexAttribArray(0);
            GL.disableVertexAttribArray(1);
            GL.disableVertexAttribArray(2);

            //NME: Disable if enabled per frame
            GL.disable(GL.DEPTH_TEST);

           // Swap buffers: is done automatically
        }
    }
    
    public inline function addDebugText ()
    {
        var tex = new TextField();
        addChild(tex);
        tex.autoSize = TextFieldAutoSize.LEFT;
        tex.background = true;
        tex.defaultTextFormat.size = 200;
        if (Utils.isGLES3compat())
        {
            trace("Compatible with GLES3 API");
            tex.text = "Compatible with GLES3 API";
        }
        else
        {
            trace("Not compatible with GLES3 API");
            tex.text = "Not compatible with GLES3 API";
        }
    }
    
}