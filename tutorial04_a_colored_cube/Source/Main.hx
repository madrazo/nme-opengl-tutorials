import nme.display.Sprite;
import nme.geom.Rectangle;
import nme.display.OpenGLView;
import nme.gl.GL;
import nme.Assets;
import nme.Lib;
import nme.utils.Float32Array;
import nme.geom.Matrix3D;
import nme.geom.Vector3D;
import nme.gl.GLProgram;

import GLM;

class Main extends Sprite {
    
   public function createShader(source:String, type:Int)
   {
      var shader = GL.createShader(type);
      GL.shaderSource(shader, source);
      GL.compileShader(shader);
      if (GL.getShaderParameter(shader, GL.COMPILE_STATUS)==0)
      {
         trace("--- ERR ---\n" + source);
         var err = GL.getShaderInfoLog(shader);
         if (err!="")
            throw err;
      }
      return shader;
   }

   public function createProgram(inVertexSource:String, inFragmentSource:String)
   {
      var program = GL.createProgram();
      var vshader = createShader(inVertexSource, GL.VERTEX_SHADER);
      var fshader = createShader(inFragmentSource, GL.FRAGMENT_SHADER);
      GL.attachShader(program, vshader);
      GL.attachShader(program, fshader);
      GL.linkProgram(program);
      if (GL.getProgramParameter(program, GL.LINK_STATUS)==0)
      {
         var result = GL.getProgramInfoLog(program);
         if (result!="")
            throw result;
      }

      return program;
   }


    
    public function new ()
    {        
        super ();

        var ogl = new OpenGLView();
        addChild(ogl);

        var fragShader = 
"//#version 330 core

// Interpolated values from the vertex shaders
//in vec3 fragmentColor;
varying vec3 fragmentColor;

// Ouput data
//out vec3 color;

void main(){

  // Output color = color specified in the vertex shader, 
  // interpolated between all 3 surrounding vertices
  //color = fragmentColor;
  gl_FragColor = vec4(fragmentColor, 1);

}
";


      var vertShader =
"//#version 330 core

precision highp float; //GLES

// Input vertex data, different for all executions of this shader.
//layout(location = 0) in vec3 vertexPosition_modelspace;
//layout(location = 1) in vec3 vertexColor;
attribute vec3 vertexPosition_modelspace;
attribute vec3 vertexColor;

// Output data ; will be interpolated for each fragment.
//out vec3 fragmentColor;
varying vec3 fragmentColor;
// Values that stay constant for the whole mesh.
uniform mat4 MVP;

void main(){  

  // Output position of the vertex, in clip space : MVP * position
  gl_Position =  MVP * vec4(vertexPosition_modelspace,1);

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

        // Create and compile our GLSL program from the shaders
        var prog = createProgram(vertShader,fragShader);

        // Get a handle for our "MVP" uniform
        var matrixID = GL.getUniformLocation(prog, "MVP");
    
        var aspect = 4 / 3;
        var zNear = 0.1;
        var zFar = 1000;
        var fov = 45 * Math.PI / 180;
        var projection = GLM.perspective(fov, aspect, zNear, zFar);

        var view:Matrix3D = GLM.lookAt(
          new Vector3D(4,3,-3), // Camera is at (4,3,-3), in World Space
          new Vector3D(0,0,0), // and looks at the origin
          new Vector3D(0,1,0) // Head is up (set to 0,-1,0 to look upside-down)
          );


        var cameraWorldTransform = new Matrix3D ();
        cameraWorldTransform.appendTranslation (0, 0, -10);
        cameraWorldTransform.appendRotation (45, Vector3D.Y_AXIS, new Vector3D(0,0,0));
        cameraWorldTransform.appendRotation (45, Vector3D.Z_AXIS, new Vector3D(0,0,0));
        var viewTransform = new Matrix3D ();
        viewTransform = cameraWorldTransform.clone ();
        viewTransform.invert ();

        var model = new Matrix3D();

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

        // Dark blue background
        nme.Lib.stage.opaqueBackground = 0x000066;

        ogl.render = function(rect:Rectangle)
        {

            //NME already calls GL.clear, set clear color with "opaqueBackground"
 			      // Dark blue background
            //GL.clearColor(0.0, 0.0, 0.4, 0.0);
            // Clear the screen.
            //GL.clear(GL.COLOR_BUFFER_BIT);

            // NME: Enable depth test per frame
            GL.enable(GL.DEPTH_TEST);

            GL.clear(GL.DEPTH_BUFFER_BIT);

            // Use our shader
            GL.useProgram(prog);

            // Send our transformation to the currently bound shader, 
            // in the "MVP" uniform
            GL.uniformMatrix4fv(matrixID, false, Float32Array.fromMatrix(mvp));

            var posAttrib = 0;//GL.getAttribLocation(prog, "vertexPosition_modelspace");
            var colorAttrib = 1;//GL.getAttribLocation(prog, "vertexColor");

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
        }
    }

    


}
