import nme.display.Sprite;
import nme.geom.Rectangle;
import nme.display.OpenGLView;
import nme.gl.GL;
import nme.Assets;
import nme.Lib;


class Main extends Sprite {


    public function new ()
    {        
        super ();

        var ogl = new OpenGLView();
        addChild(ogl);

        // Dark blue background: For NME, use "opaqueBackground" instead of "clearColor"
        //GL.clearColor(0.0, 0.0, 0.4, 0.0);
        nme.Lib.stage.opaqueBackground = 0x000066;
	
        ogl.render = function(rect:Rectangle)
        {
            // Clear the screen. It's not mentioned before Tutorial 02, but it can cause flickering, so it's there nonetheless.
            //NME already calls GL.clear with "opaqueBackground" color
            //GL.clear(GL.COLOR_BUFFER_BIT);

        }
    }
    
    
}