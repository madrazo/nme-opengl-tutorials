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
import GLM;

class Main extends Sprite {


    public function new ()
    {        
        super ();

        var ogl = new OpenGLView();
        addChild(ogl);

        addDebugText();

        var fragShader:String = 
(GL3Utils.isDesktopGL()? "#version 330 core\n" : "#version 300 es\nprecision mediump float;\n") +
"// Interpolated values from the vertex shaders
in vec3 fragmentColor;

// Ouput data
out vec4 color;
void main(){
  // Output color = color specified in the vertex shader, 
  // interpolated between all 3 surrounding vertices
  color = vec4(fragmentColor, 1.0);
}
";


      var vertShader:String =
(GL3Utils.isDesktopGL()? "#version 330 core\n" : "#version 300 es\nprecision mediump float;\n") +
"// Input vertex data, different for all executions of this shader.
layout(location = 0) in vec3 vertexPosition_modelspace;
layout(location = 1) in vec3 vertexColor;

// Output data ; will be interpolated for each fragment.
out vec3 fragmentColor;
// Values that stay constant for the whole mesh.
uniform mat4 MVP;

void main(){
  // Output position of the vertex, in clip space : MVP * position
  gl_Position =  MVP * vec4(vertexPosition_modelspace,1.0);

  // The color of each vertex will be interpolated
  // to produce the color of each fragment
  fragmentColor = vertexColor;
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

        // One color for each vertex. They were generated randomly.
        var g_color_buffer_data = [ 
          0.583,  0.771,  0.014,
          0.609,  0.115,  0.436,
          0.327,  0.483,  0.844,
          0.822,  0.569,  0.201,
          0.435,  0.602,  0.223,
          0.310,  0.747,  0.185,
          0.597,  0.770,  0.761,
          0.559,  0.436,  0.730,
          0.359,  0.583,  0.152,
          0.483,  0.596,  0.789,
          0.559,  0.861,  0.639,
          0.195,  0.548,  0.859,
          0.014,  0.184,  0.576,
          0.771,  0.328,  0.970,
          0.406,  0.615,  0.116,
          0.676,  0.977,  0.133,
          0.971,  0.572,  0.833,
          0.140,  0.616,  0.489,
          0.997,  0.513,  0.064,
          0.945,  0.719,  0.592,
          0.543,  0.021,  0.978,
          0.279,  0.317,  0.505,
          0.167,  0.620,  0.077,
          0.347,  0.857,  0.137,
          0.055,  0.953,  0.042,
          0.714,  0.505,  0.345,
          0.783,  0.290,  0.734,
          0.722,  0.645,  0.174,
          0.302,  0.455,  0.848,
          0.225,  0.587,  0.040,
          0.517,  0.713,  0.338,
          0.053,  0.959,  0.120,
          0.393,  0.621,  0.362,
          0.673,  0.211,  0.457,
          0.820,  0.883,  0.371,
          0.982,  0.099,  0.879
        ];

        var vertexbuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexbuffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(g_vertex_buffer_data), GL.STATIC_DRAW);

        var colorbuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, colorbuffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(g_color_buffer_data), GL.STATIC_DRAW);


        var posAttrib = 0;
	var colorAttrib = 1;
        if (!GL3Utils.isGLES3compat())
        {
          posAttrib = GL.getAttribLocation(prog, "vertexPosition_modelspace");
          colorAttrib = GL.getAttribLocation(prog, "vertexColor");
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

            // 2nd attribute buffer : colors
            GL.enableVertexAttribArray(colorAttrib);
            GL.bindBuffer(GL.ARRAY_BUFFER, colorbuffer);
            GL.vertexAttribPointer(
                colorAttrib, // attribute 0. No particular reason for 0, but must match the layout in the shader 
                3, // size
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
