import nme.display.Sprite;
import nme.geom.Rectangle;
import nme.display.OpenGLView;
import nme.gl.GL;
import nme.Assets;
import nme.Lib;
import nme.utils.Float32Array;
import nme.geom.Matrix3D;
import nme.gl.GLProgram;

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
"
#version 330 core

// Interpolated values from the vertex shaders
in vec3 fragmentColor;

// Ouput data
out vec3 color;

void main(){

  // Output color = color specified in the vertex shader, 
  // interpolated between all 3 surrounding vertices
  color = fragmentColor;

}
";

var vertShader =
"
#version 330 core

// Input vertex data, different for all executions of this shader.
layout(location = 0) in vec3 vertexPosition_modelspace;
layout(location = 1) in vec3 vertexColor;

// Output data ; will be interpolated for each fragment.
out vec3 fragmentColor;
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
  GL.enable(GL_DEPTH_TEST);
  // Accept fragment if it closer to the camera than the former one
  GL.depthFunc(GL_LESS); 

        // Create and compile our GLSL program from the shaders
        var prog = createProgram(vertShader,fragShader);


//        var frameBuffer = GL.createFramebuffer();
//        GL.bindFramebuffer(GL.FRAMEBUFFER,frameBuffer);




        // Get a handle for our "MVP" uniform
        var matrixID = GL.getUniformLocation(prog, "MVP");

        var projection = Matrix3D.createOrtho(-10.0,10.0,-10.0,10.0,0.0,100.0);
        var model = new Matrix3D();
        var view = new Matrix3D();

        var mvp = projection;
        mvp.append(model);
        mvp.append(view);

  

  // Our vertices. Tree consecutive floats give a 3D vertex; Three consecutive vertices give a triangle.
  // A cube has 6 faces with 2 triangles each, so this makes 6*2=12 triangles, and 12*3 vertices
  var g_vertex_buffer_data = [ 
    -1.0f,-1.0f,-1.0f,
    -1.0f,-1.0f, 1.0f,
    -1.0f, 1.0f, 1.0f,
     1.0f, 1.0f,-1.0f,
    -1.0f,-1.0f,-1.0f,
    -1.0f, 1.0f,-1.0f,
     1.0f,-1.0f, 1.0f,
    -1.0f,-1.0f,-1.0f,
     1.0f,-1.0f,-1.0f,
     1.0f, 1.0f,-1.0f,
     1.0f,-1.0f,-1.0f,
    -1.0f,-1.0f,-1.0f,
    -1.0f,-1.0f,-1.0f,
    -1.0f, 1.0f, 1.0f,
    -1.0f, 1.0f,-1.0f,
     1.0f,-1.0f, 1.0f,
    -1.0f,-1.0f, 1.0f,
    -1.0f,-1.0f,-1.0f,
    -1.0f, 1.0f, 1.0f,
    -1.0f,-1.0f, 1.0f,
     1.0f,-1.0f, 1.0f,
     1.0f, 1.0f, 1.0f,
     1.0f,-1.0f,-1.0f,
     1.0f, 1.0f,-1.0f,
     1.0f,-1.0f,-1.0f,
     1.0f, 1.0f, 1.0f,
     1.0f,-1.0f, 1.0f,
     1.0f, 1.0f, 1.0f,
     1.0f, 1.0f,-1.0f,
    -1.0f, 1.0f,-1.0f,
     1.0f, 1.0f, 1.0f,
    -1.0f, 1.0f,-1.0f,
    -1.0f, 1.0f, 1.0f,
     1.0f, 1.0f, 1.0f,
    -1.0f, 1.0f, 1.0f,
     1.0f,-1.0f, 1.0f
  ];

  // One color for each vertex. They were generated randomly.
  var g_color_buffer_data = [ 
    0.583f,  0.771f,  0.014f,
    0.609f,  0.115f,  0.436f,
    0.327f,  0.483f,  0.844f,
    0.822f,  0.569f,  0.201f,
    0.435f,  0.602f,  0.223f,
    0.310f,  0.747f,  0.185f,
    0.597f,  0.770f,  0.761f,
    0.559f,  0.436f,  0.730f,
    0.359f,  0.583f,  0.152f,
    0.483f,  0.596f,  0.789f,
    0.559f,  0.861f,  0.639f,
    0.195f,  0.548f,  0.859f,
    0.014f,  0.184f,  0.576f,
    0.771f,  0.328f,  0.970f,
    0.406f,  0.615f,  0.116f,
    0.676f,  0.977f,  0.133f,
    0.971f,  0.572f,  0.833f,
    0.140f,  0.616f,  0.489f,
    0.997f,  0.513f,  0.064f,
    0.945f,  0.719f,  0.592f,
    0.543f,  0.021f,  0.978f,
    0.279f,  0.317f,  0.505f,
    0.167f,  0.620f,  0.077f,
    0.347f,  0.857f,  0.137f,
    0.055f,  0.953f,  0.042f,
    0.714f,  0.505f,  0.345f,
    0.783f,  0.290f,  0.734f,
    0.722f,  0.645f,  0.174f,
    0.302f,  0.455f,  0.848f,
    0.225f,  0.587f,  0.040f,
    0.517f,  0.713f,  0.338f,
    0.053f,  0.959f,  0.120f,
    0.393f,  0.621f,  0.362f,
    0.673f,  0.211f,  0.457f,
    0.820f,  0.883f,  0.371f,
    0.982f,  0.099f,  0.879f
  ;



        var vertexbuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexbuffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(g_vertex_buffer_data), GL.STATIC_DRAW);


        ogl.render = function(rect:Rectangle)
        {
 			// Dark blue background
            GL.clearColor(0.0, 0.0, 0.4, 0.0);

            // Clear the screen.
            GL.clear(GL.COLOR_BUFFER_BIT);

            // Use our shader
            GL.useProgram(prog);

            // Send our transformation to the currently bound shader, 
            // in the "MVP" uniform
            GL.uniformMatrix4fv(matrixID, false, Float32Array.fromMatrix(mvp));

            // 1rst attribute buffer : vertices
            GL.enableVertexAttribArray(0);
            GL.bindBuffer(GL.ARRAY_BUFFER, vertexbuffer);
            GL.vertexAttribPointer(
                0, // attribute 0. No particular reason for 0, but must match the layout in the shader 
                4, // size
                GL.FLOAT, // type
                false, // normalized?
                0, // stride
                0 // array buffer offset
                );

            // Draw the triangle !
            GL.drawArrays(GL.TRIANGLES, 0, 3);
            GL.disableVertexAttribArray(0);
        }
    }
    
    
}