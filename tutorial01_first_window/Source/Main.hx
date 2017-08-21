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

        ogl.render = function(rect:Rectangle)
        {
 			// Dark blue background
            GL.clearColor(0.0, 0.0, 0.4, 0.0);

            // Clear the screen. It's not mentioned before Tutorial 02, but it can cause flickering, so it's there nonetheless.
            GL.clear(GL.COLOR_BUFFER_BIT);
        }
    }
    
    
}