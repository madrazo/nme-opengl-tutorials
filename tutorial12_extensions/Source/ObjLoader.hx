
package;

import nme.Assets;


class ObjLoader {
    
    //A *very* simple obj paser
    //Alternatives: 
    //assimp https://github.com/madrazo/haxe-assimp
    //Away3D https://github.com/openfl/away3d/blob/4e3a686cb6a04f3ff16e602f54e3d53a8ea5c8de/away3d/loaders/parsers/OBJParser.hx
    //tinyObj https://github.com/syoyo/tinyobjloader , GLM https://github.com/devernay/glm

    static public function loadObj(objFile:String, vertexBufferData:Array<Float>, uvBufferData:Array<Float>, normalsBufferData:Array<Float>)
    {
        var objTxt:String = Assets.getText(objFile);
        var lines:Array<String> = objTxt.split("\n");
        var temp_vertices:Array<Float> = [];
        var temp_uvs:Array<Float> = [];
        var temp_normals:Array<Float> = [];
        var vertexIndices:Array<Int> = [];
        var uvIndices    :Array<Int> = [];
        var normalIndices    :Array<Int> = [];

        for(line in lines)
        {
          var words:Array<String> = line.split(" ");
          if( words[0]=="v" )
          {
            temp_vertices.push(Std.parseFloat(words[1]));
            temp_vertices.push(Std.parseFloat(words[2]));
            temp_vertices.push(Std.parseFloat(words[3]));
          }
          else if( words[0]=="vt" )
          {
            temp_uvs.push(Std.parseFloat(words[1]));
            temp_uvs.push(Std.parseFloat(words[2]));
          }
          else if( words[0]=="vn" )
          {
            temp_normals.push(Std.parseFloat(words[1]));
            temp_normals.push(Std.parseFloat(words[2]));
            temp_normals.push(Std.parseFloat(words[3]));
          }
          else if( words[0]=="f" )
          {
            var e0 = words[1].split("/");
            var e1 = words[2].split("/");
            var e2 = words[3].split("/");

            vertexIndices.push(Std.parseInt(e0[0]));
            vertexIndices.push(Std.parseInt(e1[0]));
            vertexIndices.push(Std.parseInt(e2[0]));

            uvIndices.push(Std.parseInt(e0[1]));
            uvIndices.push(Std.parseInt(e1[1]));
            uvIndices.push(Std.parseInt(e2[1]));

            normalIndices.push(Std.parseInt(e0[2]));
            normalIndices.push(Std.parseInt(e1[2]));
            normalIndices.push(Std.parseInt(e2[2]));
          }
        }
 
        for(i in 0...vertexIndices.length)
        {
            // Get the indices of its attributes
            var vertexIndex = vertexIndices[i];
            var uvIndex = uvIndices[i];
            var normalIndex = normalIndices[i];

            var v:Int = (vertexIndex-1)*3;
            var t:Int = (uvIndex-1)*2;
            var n:Int = (normalIndex-1)*3;
            vertexBufferData.push(temp_vertices[ v ]);
            vertexBufferData.push(temp_vertices[ v+1 ]);
            vertexBufferData.push(temp_vertices[ v+2 ]);

            uvBufferData.push(temp_uvs[ t ]);
            uvBufferData.push(1.0-temp_uvs[ t+1 ]); //1.0- OK?

            normalsBufferData.push(temp_normals[ n ]);
            normalsBufferData.push(temp_normals[ n+1 ]);
            normalsBufferData.push(temp_normals[ n+2 ]);
        }
    }  
}
