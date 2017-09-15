import nme.display.Sprite;
import nme.geom.Rectangle;
import nme.display.OpenGLView;
import nme.gl.GL;
import nme.Assets;
import nme.Lib;
import nme.utils.Float32Array;
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

        var fragShader:String = 
"// Interpolated values from the vertex shaders
" + Utils.IN() + " vec2 UV;

// Ouput data
" + 
Utils.OUT_COLOR("color") +
"

// Values that stay constant for the whole mesh.
uniform sampler2D myTextureSampler;

void main(){
  // Output color = color of the texture at the specified UV
  color = " + Utils.TEXTURE() +"( myTextureSampler, UV );
}
";


      var vertShader:String =
"// Input vertex data, different for all executions of this shader.
" +
Utils.IN(0) + " vec3 vertexPosition_modelspace;
" +
Utils.IN(1) + " vec2 vertexUV;

// Output data ; will be interpolated for each fragment.
" + Utils.OUT() + " vec2 UV;
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

        //GLES3
        if (Utils.isGLES3compat())
        {
            var vertexarray = GL.createVertexArray();
            GL.bindVertexArray(vertexarray);
        }

        // Create and compile our GLSL program from the shaders
        var prog = Utils.createProgram(vertShader,fragShader);

        // Get a handle for our "MVP" uniform
        var matrixID = GL.getUniformLocation(prog, "MVP");

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


        var posAttrib = 0;
	      var uvAttrib = 1;
        if (!Utils.isGLES3compat())
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
    
    
}