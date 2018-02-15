import nme.display.Sprite;
import nme.geom.Rectangle;
import nme.display.OpenGLView;
import nme.gl.GL;
#if gles3
import nme.gl.GL3;
#end
import GL3Utils;
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

class Main extends Sprite {


    public function new ()
    {        
        super ();

        var ogl = new OpenGLView();
        addChild(ogl);

        addDebugText();

        var fragShader:String = 
"// Interpolated values from the vertex shaders
in vec2 UV;

// Ouput data
out vec4 color;

// Values that stay constant for the whole mesh.
uniform sampler2D myTextureSampler;

void main(){
  // Output color = color of the texture at the specified UV
  color = texture(myTextureSampler, UV);
}
";


      var vertShader:String =
"// Input vertex data, different for all executions of this shader.
layout(location = 0) in vec3 vertexPosition_modelspace;
layout(location = 1) in vec2 vertexUV;

// Output data ; will be interpolated for each fragment.
out vec2 UV;
// Values that stay constant for the whole mesh.
uniform mat4 MVP;

void main(){
  // Output position of the vertex, in clip space : MVP * position
  gl_Position =  MVP * vec4(vertexPosition_modelspace,1.0);

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
        #if gles3
        if (GL3Utils.isGLES3compat())
        {
            var vertexarray = GL3.createVertexArray();
            GL3.bindVertexArray(vertexarray);
        }
        #end

        // Create and compile our GLSL program from the shaders
        if (!GL3Utils.isGLES3compat())
        {
            vertShader = GL3Utils.vsToGLES2(vertShader);
            fragShader = GL3Utils.fsToGLES2(fragShader);
        }
        var prog = Utils.createProgram(vertShader,fragShader);

        // Get a handle for our "MVP" uniform
        var matrixID = GL.getUniformLocation(prog, "MVP");
        var model = new Matrix3D();
#if false
        //Ortho camera
        var view:Matrix3D = new Matrix3D();
        var projection = Matrix3D.createOrtho(-10.0,10.0,-10.0,10.0,0.0,100.0);
#else
       //Persp camera
        var view:Matrix3D = GLM.lookAt(
          new Vector3D(4,3,-3), // Camera is at (4,3,-3), in World Space
          new Vector3D(0,0,0), // and looks at the origin
          new Vector3D(0,1,0) // Head is up (set to 0,-1,0 to look upside-down)
          );
    
        var fov = 45 * Math.PI / 180;
        var aspect = 4 / 3;
        var zNear = 0.1;
        var zFar = 1000;
        var projection = GLM.perspective(fov, aspect, zNear, zFar);
#end

        var mvp = model;
        mvp.append(view);
        mvp.append(projection);

        var texture:BitmapData = Assets.getBitmapData("assets/uvtemplate.png");


        // Our vertices. Tree consecutive floats give a 3D vertex; Three consecutive vertices give a triangle.
        // A cube has 6 faces with 2 triangles each, so this makes 6*2=12 triangles, and 12*3 vertices
        var g_vertex_buffer_data = [ 
          -1.0,-1.0,-1.0,
          -1.0,-1.0, 1.0,
          -1.0, 1.0, 1.0,
           1.0, 1.0,-1.0,
          -1.0,-1.0,-1.0,
          -1.0, 1.0,-1.0,
           1.0,-1.0, 1.0,
          -1.0,-1.0,-1.0,
           1.0,-1.0,-1.0,
           1.0, 1.0,-1.0,
           1.0,-1.0,-1.0,
          -1.0,-1.0,-1.0,
          -1.0,-1.0,-1.0,
          -1.0, 1.0, 1.0,
          -1.0, 1.0,-1.0,
           1.0,-1.0, 1.0,
          -1.0,-1.0, 1.0,
          -1.0,-1.0,-1.0,
          -1.0, 1.0, 1.0,
          -1.0,-1.0, 1.0,
           1.0,-1.0, 1.0,
           1.0, 1.0, 1.0,
           1.0,-1.0,-1.0,
           1.0, 1.0,-1.0,
           1.0,-1.0,-1.0,
           1.0, 1.0, 1.0,
           1.0,-1.0, 1.0,
           1.0, 1.0, 1.0,
           1.0, 1.0,-1.0,
          -1.0, 1.0,-1.0,
           1.0, 1.0, 1.0,
          -1.0, 1.0,-1.0,
          -1.0, 1.0, 1.0,
           1.0, 1.0, 1.0,
          -1.0, 1.0, 1.0,
           1.0,-1.0, 1.0
        ];



        // Two UV coordinatesfor each vertex. They were created with Blender.
        var g_uv_buffer_data = [ 
          0.000059, /*1.0-*/0.000004, 
          0.000103, /*1.0-*/0.336048, 
          0.335973, /*1.0-*/0.335903, 
          1.000023, /*1.0-*/0.000013, 
          0.667979, /*1.0-*/0.335851, 
          0.999958, /*1.0-*/0.336064, 
          0.667979, /*1.0-*/0.335851, 
          0.336024, /*1.0-*/0.671877, 
          0.667969, /*1.0-*/0.671889, 
          1.000023, /*1.0-*/0.000013, 
          0.668104, /*1.0-*/0.000013, 
          0.667979, /*1.0-*/0.335851, 
          0.000059, /*1.0-*/0.000004, 
          0.335973, /*1.0-*/0.335903, 
          0.336098, /*1.0-*/0.000071, 
          0.667979, /*1.0-*/0.335851, 
          0.335973, /*1.0-*/0.335903, 
          0.336024, /*1.0-*/0.671877, 
          1.000004, /*1.0-*/0.671847, 
          0.999958, /*1.0-*/0.336064, 
          0.667979, /*1.0-*/0.335851, 
          0.668104, /*1.0-*/0.000013, 
          0.335973, /*1.0-*/0.335903, 
          0.667979, /*1.0-*/0.335851, 
          0.335973, /*1.0-*/0.335903, 
          0.668104, /*1.0-*/0.000013, 
          0.336098, /*1.0-*/0.000071, 
          0.000103, /*1.0-*/0.336048, 
          0.000004, /*1.0-*/0.671870, 
          0.336024, /*1.0-*/0.671877, 
          0.000103, /*1.0-*/0.336048, 
          0.336024, /*1.0-*/0.671877, 
          0.335973, /*1.0-*/0.335903, 
          0.667969, /*1.0-*/0.671889, 
          1.000004, /*1.0-*/0.671847, 
          0.667979, /*1.0-*/0.335851
        ];

        var vertexbuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexbuffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(g_vertex_buffer_data), GL.STATIC_DRAW);

        var uvbuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, uvbuffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(g_uv_buffer_data), GL.STATIC_DRAW);


        var posAttrib = 0;
	var uvAttrib = 1;
        if (!GL3Utils.isGLES3compat())
        {
          posAttrib = GL.getAttribLocation(prog, "vertexPosition_modelspace");
          uvAttrib = GL.getAttribLocation(prog, "vertexUV");
        }

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

            // Send our transformation to the currently bound shader, 
            // in the "MVP" uniform
            GL.uniformMatrix4fv(matrixID, false, Float32Array.fromMatrix(mvp));

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


            // Draw the triangle !
            GL.drawArrays(GL.TRIANGLES, 0, 12*3);
            GL.disableVertexAttribArray(0);
            GL.disableVertexAttribArray(1);

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
        if (GL3Utils.isGLES3compat())
        {
            trace("Compatible with GLES3 API");
            tex.text = "Compatible with GLES3 API";
        }
        else
        {
            trace("Not compatible with GLES3 API");
            tex.text = "Not compatible with GLES3 API or forced GLES2";
        }
    }
    
}