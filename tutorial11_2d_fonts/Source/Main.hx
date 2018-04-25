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
import nme.utils.Int16Array;
import nme.text.TextField;
import nme.text.TextFormat;
import nme.text.TextFieldAutoSize;

import nme.gl.GLProgram;
import nme.gl.Utils;

import nme.geom.Matrix3D;    
import nme.geom.Vector3D;

import nme.display.BitmapData;

import GLM;
import Controls;
import ObjLoader;

import haxe.ds.HashMap;

class Main extends Sprite {
    

    var m_controls:Controls;

    public function new ()
    {        
        super ();

        var ogl = new OpenGLView();
        addChild(ogl);

        addDebugText();

        var fragShader:String = 
(GL3Utils.isDesktopGL()? "#version 330 core\n" : "#version 300 es\nprecision mediump float;\n") +
"// Interpolated values from the vertex shaders
in vec2 UV;
in vec3 Position_worldspace;
in vec3 Normal_cameraspace;
in vec3 EyeDirection_cameraspace;
in vec3 LightDirection_cameraspace;

// Ouput data
out vec4 color;

// Values that stay constant for the whole mesh.
uniform sampler2D myTextureSampler;
uniform mat4 MV;
uniform vec3 LightPosition_worldspace;

void main(){
    // Light emission properties
    // You probably want to put them as uniforms
    vec3 LightColor = vec3(1,1,1);
    float LightPower = 50.0;
    
    // Material properties
    vec3 MaterialDiffuseColor = texture( myTextureSampler, UV ).rgb;
    vec3 MaterialAmbientColor = vec3(0.1,0.1,0.1) * MaterialDiffuseColor;
    vec3 MaterialSpecularColor = vec3(0.3,0.3,0.3);

    // Distance to the light
    float distance = length( LightPosition_worldspace - Position_worldspace );

    // Normal of the computed fragment, in camera space
    vec3 n = normalize( Normal_cameraspace );
    // Direction of the light (from the fragment to the light)
    vec3 l = normalize( LightDirection_cameraspace );
    // Cosine of the angle between the normal and the light direction, 
    // clamped above 0
    //  - light is at the vertical of the triangle -> 1
    //  - light is perpendicular to the triangle -> 0
    //  - light is behind the triangle -> 0
    float cosTheta = clamp( dot( n,l ), 0.0 , 1.0);
    
    // Eye vector (towards the camera)
    vec3 E = normalize(EyeDirection_cameraspace);
    // Direction in which the triangle reflects the light
    vec3 R = reflect(-l,n);
    // Cosine of the angle between the Eye vector and the Reflect vector,
    // clamped to 0
    //  - Looking into the reflection -> 1
    //  - Looking elsewhere -> < 1
    float cosAlpha = clamp( dot( E,R ), 0.0, 1.0);
    
    vec3 col =
        // Ambient : simulates indirect lighting
        MaterialAmbientColor +
        // Diffuse : color of the object
        MaterialDiffuseColor * LightColor * LightPower * cosTheta / (distance*distance) +
        // Specular : reflective highlight, like a mirror
        MaterialSpecularColor * LightColor * LightPower * pow(cosAlpha,5.0) / (distance*distance);
        
    float alpha = 1.0; 
    color = vec4(col,alpha); 
}
";


      var vertShader:String =
(GL3Utils.isDesktopGL()? "#version 330 core\n" : "#version 300 es\nprecision mediump float;\n") +
"// Input vertex data, different for all executions of this shader.
layout(location = 0) in vec3 vertexPosition_modelspace;
layout(location = 1) in vec2 vertexUV;
layout(location = 2) in  vec3 vertexNormal_modelspace;

// Output data ; will be interpolated for each fragment.
out vec2 UV;
out vec3 Position_worldspace;
out vec3 Normal_cameraspace;
out vec3 EyeDirection_cameraspace;
out vec3 LightDirection_cameraspace;

// Values that stay constant for the whole mesh.
uniform mat4 MVP;
uniform mat4 V;
uniform mat4 M;
uniform vec3 LightPosition_worldspace;

void main(){
  // Output position of the vertex, in clip space : MVP * position
  gl_Position =  MVP * vec4(vertexPosition_modelspace,1.0);

    // Position of the vertex, in worldspace : M * position
    Position_worldspace = (M * vec4(vertexPosition_modelspace,1)).xyz;
    
    // Vector that goes from the vertex to the camera, in camera space.
    // In camera space, the camera is at the origin (0,0,0).
    vec3 vertexPosition_cameraspace = ( V * M * vec4(vertexPosition_modelspace,1)).xyz;
    EyeDirection_cameraspace = vec3(0,0,0) - vertexPosition_cameraspace;

    // Vector that goes from the vertex to the light, in camera space. M is ommited because it's identity.
    vec3 LightPosition_cameraspace = ( V * vec4(LightPosition_worldspace,1)).xyz;
    LightDirection_cameraspace = LightPosition_cameraspace + EyeDirection_cameraspace;
    
    // Normal of the the vertex, in camera space
    Normal_cameraspace = ( V * M * vec4(vertexNormal_modelspace,0)).xyz; // Only correct if ModelMatrix does not scale the model ! Use its inverse transpose if not.
    

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
        var viewMatrixID  = GL.getUniformLocation(prog, "V");
        var modelMatrixID  = GL.getUniformLocation(prog, "M");

        m_controls = new Controls();

        var texture:BitmapData = Assets.getBitmapData("assets/uvmap.png");

        var g_vertex_buffer_data:Array<Float> = [];
        var g_uv_buffer_data:Array<Float> = [];
        var g_normals_buffer_data:Array<Float> = [];
       
        ObjLoader.loadObj("assets/suzanne.obj", g_vertex_buffer_data, g_uv_buffer_data, g_normals_buffer_data);
//        ObjLoader.loadObj("assets/cube.obj", g_vertex_buffer_data, g_uv_buffer_data, g_normals_buffer_data);
        var nTriangles:Int = Std.int(g_vertex_buffer_data.length/3);

        var indices:Array<Int> = [];
        var indexed_vertices:Array<Float> = [];//vec3
        var indexed_uvs:Array<Float> = [];//vec2
        var indexed_normals:Array<Float> = [];//vec3
        indexVBO(g_vertex_buffer_data, g_uv_buffer_data, g_normals_buffer_data, indices, indexed_vertices, indexed_uvs, indexed_normals);
        var nIndices:Int = indices.length;

        //trace("indices "+indices.length);
        //trace("v "+indexed_vertices.length/3);
        //trace("uvs "+indexed_uvs.length/2);
        //trace("n "+indexed_normals.length/3);

        var vertexbuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexbuffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(indexed_vertices), GL.STATIC_DRAW);

        var uvbuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, uvbuffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(indexed_uvs), GL.STATIC_DRAW);

        var normalbuffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, normalbuffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(indexed_normals), GL.STATIC_DRAW);

        // Generate a buffer for the indices as well
        var elementbuffer = GL.createBuffer();
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, elementbuffer);
        GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, new Int16Array(indices), GL.STATIC_DRAW);

        var posAttrib = 0;
        var uvAttrib = 1;
        var normalAttrib = 2;
        if (!GL3Utils.isGLES3compat())
        {
            posAttrib = GL.getAttribLocation(prog, "vertexPosition_modelspace");
            uvAttrib = GL.getAttribLocation(prog, "vertexUV");
            normalAttrib = GL.getAttribLocation(prog, "vertexNormal_modelspace");
        }

        // Get a handle for our "LightPosition" uniform
        //GL.useProgram(prog);
        var lightID  = GL.getUniformLocation(prog, "LightPosition_worldspace");


        // Initialize our little text (field) with the Holstein font
        var texFormat = new TextFormat();
        texFormat.font = Assets.getFont("assets/holstein.ttf").fontName;
	    texFormat.size = 100;
        texFormat.color = 0xFFFFFF; //white
        var tex = new TextField();
        tex.x = 100; 
        tex.y = 100; 
        tex.autoSize = TextFieldAutoSize.LEFT;
        tex.defaultTextFormat = texFormat;
        //tex.background = true;
        addChild(tex);
 
        ogl.render = function(rect:Rectangle)
        {
	        //update text here or on enter frame event
            tex.text = floatToStringPrecision2(haxe.Timer.stamp())+" sec";

            //NME already calls GL.clear with "opaqueBackground" color
            // Clear the screen.
            //GL.clear(GL.COLOR_BUFFER_BIT);

            // NME: Enable depth test per frame?
            GL.enable(GL.DEPTH_TEST);
            GL.clear(GL.DEPTH_BUFFER_BIT);

            // Cull triangles which normal is not towards the camera
            GL.enable(GL.CULL_FACE);

            // Enable blending
            //GL.enable(GL.BLEND);
            //GL.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);

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
            GL.uniformMatrix4fv(modelMatrixID, false, Float32Array.fromMatrix(model));
            GL.uniformMatrix4fv(viewMatrixID, false, Float32Array.fromMatrix(view));

            var lightPos = new nme.geom.Vector3D(4,4,4);
            GL.uniform3f(lightID, lightPos.x, lightPos.y, lightPos.z);

            // Bind our texture in Texture Unit 0
            GL.bindBitmapDataTexture( texture );

            // 1rst attribute buffer : vertices
            GL.enableVertexAttribArray(posAttrib);
            GL.bindBuffer(GL.ARRAY_BUFFER, vertexbuffer);
            GL.vertexAttribPointer(
                posAttrib, // attribute
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
                uvAttrib, // attribute
                2, // size
                GL.FLOAT, // type
                false, // normalized?
                0, // stride
                0 // array buffer offset
                );

            // 3rd attribute buffer : normals
            GL.enableVertexAttribArray(normalAttrib);
            GL.bindBuffer(GL.ARRAY_BUFFER, normalbuffer);
            GL.vertexAttribPointer(
                normalAttrib, // attribute 
                3, // size
                GL.FLOAT, // type
                false, // normalized?
                0, // stride
                0 // array buffer offset
                );

            // Index buffer
            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, elementbuffer);

            // Draw the triangles !
            GL.drawElements(GL.TRIANGLES, nIndices, GL.UNSIGNED_SHORT, 0);
            GL.disableVertexAttribArray(0);
            GL.disableVertexAttribArray(1);
            GL.disableVertexAttribArray(2);

            // Cull triangles which normal is not towards the camera
            GL.disable(GL.CULL_FACE); //Needed for text to show

            //NME: Disable if enabled per frame
            GL.disable(GL.DEPTH_TEST);

           // Swap buffers: is done automatically
        }
    }

    
public function indexVBO (
    in_vertices:Array<Float>,
    in_uvs:Array<Float>,
    in_normals:Array<Float>,
    out_indices:Array<Int>,
    out_vertices:Array<Float>,
    out_uvs:Array<Float>,
    out_normals:Array<Float>
){
    var vertexToOutIndex = new HashMap();

    //trace("start v"+in_vertices.length/3);
    //trace("start uvs"+in_uvs.length/2);
    //trace("start n"+in_normals.length/3);

    // For each input vertex
    var n:Int = Std.int(in_vertices.length/3);
    for(i in 0...n)
    {

        var packed:PackedVert = new PackedVert(
            in_vertices[i*3+0],
            in_vertices[i*3+1],
            in_vertices[i*3+2],
            in_uvs[i*2+0],
            in_uvs[i*2+1],
            in_normals[i*3+0],
            in_normals[i*3+1],
            in_normals[i*3+2]
            );
        var found:Bool = vertexToOutIndex.exists( packed );
    
        if(found)
        {
            //trace("FOUND");
            var index = vertexToOutIndex.get( packed );
            out_indices.push( index );
        }
        else
        {
            // If not, it needs to be added in the output data.
            out_vertices.push( in_vertices[i*3+0]);
            out_vertices.push( in_vertices[i*3+1]);
            out_vertices.push( in_vertices[i*3+2]);
            out_uvs     .push( in_uvs[i*2+0]);
            out_uvs     .push( in_uvs[i*2+1]);
            out_normals .push( in_normals[i*3+0]);
            out_normals .push( in_normals[i*3+1]);
            out_normals .push( in_normals[i*3+2]);
            var newindex:Int = Std.int(out_vertices.length/3) - 1;
            out_indices .push( newindex );
                vertexToOutIndex.set( packed,  newindex);            
        }

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

    //https://stackoverflow.com/questions/23689001/how-to-reliably-format-a-floating-point-number-to-a-specified-number-of-decimal
    public static function floatToStringPrecision2(n:Float)
    {
        if(n==0)
            return "0.000";

        var minusSign:Bool = (n<0.0);
        n = Math.abs(n);
        var intPart:Int = Math.floor(n);
        var p:Float = 100.0; //pow(10, 2)
        var fracPart = Math.round( p*(n - intPart) );
        var buf:StringBuf = new StringBuf();

        if(minusSign)
            buf.addChar("-".code);
        buf.add(Std.string(intPart));
        if(fracPart==0)
             buf.add(".00");
        else 
        {
            if(fracPart<10)
                buf.add(".0"); 
            else
                buf.add("."); 
            buf.add(fracPart);
        }
        return buf.toString();
    }
    
}


class PackedVert
{
    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var u:Float;
    public var v:Float;
    public var nx:Float;
    public var ny:Float;
    public var nz:Float;

    public function new(x:Float, y:Float, z:Float, u:Float, v:Float, nx:Float, ny:Float, nz:Float)
    {
        this.x = x;
        this.y = y;
        this.z = z;
        this.u = u;
        this.v = v;
        this.nx = nx;
        this.ny = ny;
        this.nz = nz;
    }
    public function hashCode():Int
    {
        return Std.int((100*x + 10000*y - 100000*z)*(u-v)-100*(nx+ny+nz)); //of course don't use this, but a real hash map
    }
}
