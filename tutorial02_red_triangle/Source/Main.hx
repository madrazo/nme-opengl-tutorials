import nme.display.Sprite;
import nme.geom.Rectangle;
import nme.display.OpenGLView;
import nme.gl.GL;
import nme.Assets;
import nme.Lib;
import nme.utils.Float32Array;

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
// Ouput data
out vec3 color;

void main()
{

    // Output color = red 
    color = vec3(1,0,0);

}
";

var vertShader =
"
// Input vertex data, different for all executions of this shader.
layout(location = 0) in vec3 vertexPosition_modelspace;

void main(){

    gl_Position.xyz = vertexPosition_modelspace;
    gl_Position.w = 1.0;

}
";


        // Create and compile our GLSL program from the shaders
        var prog = createProgram(vertShader,fragShader);


//        var frameBuffer = GL.createFramebuffer();
//        GL.bindFramebuffer(GL.FRAMEBUFFER,frameBuffer);

         var g_vertex_buffer_data = [
         -1.0, -1.0, 0.0, 1.0,
         1.0, -1.0, 0.0, 1.0,
         0.0,  1.0, 0.0, 1.0
        ];


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