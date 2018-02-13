import nme.display.Sprite;
import nme.geom.Rectangle;
import nme.display.OpenGLView;
import nme.gl.GL;
#if gles3
import nme.gl.GL3;
#end
import nme.Assets;
import nme.Lib;
import nme.utils.Float32Array;
import nme.text.TextField;
import nme.text.TextFieldAutoSize;

import nme.gl.GLProgram;
import nme.gl.Utils;

class Main extends Sprite {


    public function new ()
    {        
        super ();

        var ogl = new OpenGLView();
        addChild(ogl);

        addDebugText();

        var fragShader:String = 
"// Ouput data
" + 
vs_out_color("color") +
"
void main(){
    // Output color = red 
    color = vec4(1.0,0.0,0.0,1.0);
}
";


        var vertShader:String = 
"// Input vertex data, different for all executions of this shader.
" +
vs_in(0) + " vec3 vertexPosition_modelspace;

void main(){
    gl_Position.xyz = vertexPosition_modelspace;
    gl_Position.w = 1.0;
}
";

        // Dark blue background: For NME, use "opaqueBackground" instead of "clearColor"
        //GL.clearColor(0.0, 0.0, 0.4, 0.0);
        nme.Lib.stage.opaqueBackground = 0x000066;
#if gles3
        //GLES3
        if (Utils.isGLES3compat())
        {
            var vertexarray = GL3.createVertexArray();
            GL3.bindVertexArray(vertexarray);
        }
#end
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
#if gles3
        if (!Utils.isGLES3compat())
#end
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
    
    public inline function addDebugText ()
    {
        var tex = new TextField();
        addChild(tex);
        tex.autoSize = TextFieldAutoSize.LEFT;
        tex.background = true;
        tex.defaultTextFormat.size = 200;
#if gles3
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
#else
            tex.text = "Using GLES2";
#end
    }

    function fs_in():String
    {
        #if gles3
        return Utils.IN();
        #else
        return "\nvarying ";
        #end
    }

    function vs_out():String
    {
        #if gles3
        return Utils.OUT();
        #else
        return "\nvarying ";
        #end
    }

    function vs_in(slot:Int):String
    {
        #if gles3
        return Utils.IN(slot);
        #else
        return "\nattribute ";
        #end
    }

    function vs_out_color(slot:String):String
    {
        #if gles3
        return Utils.OUT_COLOR(slot);
        #else
        return "\n#define "+slot+" gl_FragColor\n";
        #end
    }    
}
