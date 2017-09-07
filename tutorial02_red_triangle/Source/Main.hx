import nme.display.Sprite;
import nme.geom.Rectangle;
import nme.display.OpenGLView;
import nme.gl.GL;
import nme.Assets;
import nme.Lib;
import nme.utils.Float32Array;

import nme.gl.GLProgram;
import nme.gl.Utils;

class Main extends Sprite {


    public function new ()
    {        
        super ();

        var ogl = new OpenGLView();
        addChild(ogl);

        var fragShader:String = 
"// Ouput data
"+Utils.OUT_COLOR("color")+"

void main()
{
    // Output color = red 
    color = vec4(1.0,0.0,0.0,1.0);
}
";


        var vertShader:String = 
"// Input vertex data, different for all executions of this shader.
"+Utils.IN(0)+" vec3 vertexPosition_modelspace;

void main(){
    gl_Position.xyz = vertexPosition_modelspace;
    gl_Position.w = 1.0;
}
";

        // Dark blue background: For NME, use "opaqueBackground" instead of "clearColor"
        //GL.clearColor(0.0, 0.0, 0.4, 0.0);
        nme.Lib.stage.opaqueBackground = 0x000066;

        //GLES3
        if (Utils.isGLES3compat())
        {
            var vertexarray = GL.createVertexArray();
            GL.bindVertexArray(vertexarray);
        }

        // Create and compile our GLSL program from the shaders
        var prog = Utils.createProgram(vertShader,fragShader);


        var g_vertex_buffer_data = [
         -1.0, -1.0, 0.0, //vertex 0 x,y,z
          1.0, -1.0, 0.0, //vertex 1
          0.0,  1.0, 0.0, //vertex 2
        ]; //3 vertex of size 3

        var vertexbuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexbuffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(g_vertex_buffer_data), GL.STATIC_DRAW);

        var posAttrib = 0;
        if (!Utils.isGLES3compat())
        {
          posAttrib = GL.getAttribLocation(prog, "vertexPosition_modelspace");
        }

        ogl.render = function(rect:Rectangle)
        {
            //NME already calls GL.clear with "opaqueBackground" color
            // Clear the screen.
            //GL.clear(GL.COLOR_BUFFER_BIT);

            // Use our shader
            GL.useProgram(prog);

            // 1rst attribute buffer : vertices
            GL.enableVertexAttribArray(posAttrib);
            GL.bindBuffer(GL.ARRAY_BUFFER, vertexbuffer);
            GL.vertexAttribPointer(
                posAttrib, // attribute 0. No particular reason for 0, but must match the layout in the shader 
                3,  // size
                GL.FLOAT, // type
                false, // normalized?
                0, // stride
                0 // array buffer offset
                );

            // Draw the triangle !
            GL.drawArrays(GL.TRIANGLES, 0, 3);
            GL.disableVertexAttribArray(0);

           // Swap buffers: is done automatically
        }
    }
    
    
}
