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

class Main extends Sprite {


    public function new ()
    {        
        super ();

        var ogl = new OpenGLView();
        addChild(ogl);

        addDebugText();

        var fragShader:String = 
(GL3Utils.isDesktopGL()? "#version 330 core\n" : "#version 300 es\nprecision mediump float;\n") +
"// Ouput data
out vec4 color;
void main(){
    // Output color = red 
    color = vec4(1.0,0.0,0.0,1.0);
}
";


        var vertShader:String = 
(GL3Utils.isDesktopGL()? "#version 330 core\n" : "#version 300 es\nprecision mediump float;\n") +
"// Input vertex data, different for all executions of this shader. 
layout(location = 0) in vec3 vertexPosition_modelspace;

// Values that stay constant for the whole mesh.
uniform mat4 MVP;

void main(){
  // Output position of the vertex, in clip space : MVP * position
  gl_Position =  MVP * vec4(vertexPosition_modelspace,1.0);
}
";

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
#if true
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

         var g_vertex_buffer_data = [
         -1.0, -1.0, 0.0, 1.0, //vertex 0 x,y,z,w
          1.0, -1.0, 0.0, 1.0, //vertex 1
          0.0,  1.0, 0.0, 1.0  //vertex2
        ]; //3 vertex of size 4


        var vertexbuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexbuffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(g_vertex_buffer_data), GL.STATIC_DRAW);

        var posAttrib = 0;
        if (!GL3Utils.isGLES3compat())
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

            // Send our transformation to the currently bound shader, 
            // in the "MVP" uniform
            GL.uniformMatrix4fv(matrixID, false, Float32Array.fromMatrix(mvp));

            // 1rst attribute buffer : vertices
            GL.enableVertexAttribArray(posAttrib);
            GL.bindBuffer(GL.ARRAY_BUFFER, vertexbuffer);
            GL.vertexAttribPointer(
                posAttrib, // attribute 0. No particular reason for 0, but must match the layout in the shader 
                4,  // size
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
