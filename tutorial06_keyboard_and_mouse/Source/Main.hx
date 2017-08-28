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

import nme.display.BitmapData;
import nme.Assets;

import nme.events.Event;
import nme.events.KeyboardEvent;
import nme.events.MouseEvent;
import nme.ui.Keyboard;

import GLM;
import Controls;

class Main extends Sprite {
    

    var m_controls:Controls;

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
//in vec2 UV;
varying vec2 UV;

// Ouput data
//out vec3 color;

// Values that stay constant for the whole mesh.
uniform sampler2D myTextureSampler;

void main(){


  // Output color = color of the texture at the specified UV
  //color = texture( myTextureSampler, UV ).rgb;
  gl_FragColor = texture2D( myTextureSampler, UV );

}
";


      var vertShader =
"//#version 330 core

precision highp float; //GLES

// Input vertex data, different for all executions of this shader.
//layout(location = 0) in vec3 vertexPosition_modelspace;
//layout(location = 1) in vec3 vertexUV;
attribute vec3 vertexPosition_modelspace;
attribute vec2 vertexUV;

// Output data ; will be interpolated for each fragment.
//out vec2 UV;
varying vec2 UV;
// Values that stay constant for the whole mesh.
uniform mat4 MVP;

void main(){  

  // Output position of the vertex, in clip space : MVP * position
  gl_Position =  MVP * vec4(vertexPosition_modelspace,1);

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

        // Create and compile our GLSL program from the shaders
        var prog = createProgram(vertShader,fragShader);

        // Get a handle for our "MVP" uniform
        var matrixID = GL.getUniformLocation(prog, "MVP");

        m_controls = new Controls();
        /*
        Lib.current.stage.addEventListener (KeyboardEvent.KEY_DOWN, stage_onKeyDown);
        Lib.current.stage.addEventListener (KeyboardEvent.KEY_UP, stage_onKeyUp);
        Lib.current.stage.addEventListener (MouseEvent.MOUSE_MOVE, stage_onMouseMove);*/
        //Lib.current.stage.addEventListener (Event.ENTER_FRAME, this_onEnterFrame);


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


            // Compute the MVP matrix from keyboard and mouse input 
            m_controls.computeMatricesFromInputs();
            var projection = m_controls.getProjectionMatrix();
            var view = m_controls.getViewMatrix();
            var model = new Matrix3D();

            var mvp = model;
            mvp.append(view);
            mvp.append(projection);



            // Send our transformation to the currently bound shader, 
            // in the "MVP" uniform
            GL.uniformMatrix4fv(matrixID, false, Float32Array.fromMatrix(mvp));

            var posAttrib = 0;//GL.getAttribLocation(prog, "vertexPosition_modelspace");
            var uvAttrib = 1;//GL.getAttribLocation(prog, "vertexColor");


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
        }
    }

/*
  private function stage_onMouseMove(event:MouseEvent)
  { 
    m_controls.onMouseMove(event);
  }

  private function stage_onKeyDown (event:KeyboardEvent):Void {
    m_controls.onKeyDown(event);
  }
  
  private function stage_onKeyUp (event:KeyboardEvent):Void {
    m_controls.onKeyUp(event);
  }
  */
  
  //private function this_onEnterFrame (event:Event):Void {
  //}

}
