using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class DepthWrite : MonoBehaviour {

 private Material DepthWriteMaterial = null;
 // Use this for initialization
 void Start () {
  DepthWriteMaterial = new Material(Shader.Find("Hidden/DepthWrite"));
 }
 

 void OnPreRender()
 {

  DrawQuad();
 }

 void DrawQuad()
 {
  GL.PushMatrix(); 
  GL.LoadOrtho();
  
  DepthWriteMaterial.SetPass(0);     
  
  //Render the full screen quad manually.  
  GL.Begin(GL.QUADS); 
  GL.TexCoord2(0.0f, 0.0f); GL.Vertex3(0.0f, 0.0f, 0.1f);  
  GL.TexCoord2(1.0f, 0.0f); GL.Vertex3(1.0f, 0.0f, 0.1f);  
  GL.TexCoord2(1.0f, 1.0f); GL.Vertex3(1.0f, 1.0f, 0.1f);  
  GL.TexCoord2(0.0f, 1.0f); GL.Vertex3(0.0f, 1.0f, 0.1f);  
  GL.End();
  
  GL.PopMatrix();
 }
}
