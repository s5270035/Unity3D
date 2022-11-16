using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class DepthWrite : MonoBehaviour {
 // Use this for initialization
 public Camera _camera;
 public Material _mat;
 void Start () {
  if (_camera == null)
			_camera = GetComponent<Camera> ();
		if (_camera != null)
			_camera.depthTextureMode = DepthTextureMode.Depth;
 }
 void OnRenderImage(RenderTexture src, RenderTexture dest) {
		Graphics.Blit(src, dest, _mat);
	}

}
