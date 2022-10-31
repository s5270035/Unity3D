using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FocusCamera : MonoBehaviour
{
    public GameObject target;
    public float speedMod = 1.0f;
    private Vector3 point;
    private Vector3 lastMouse = new Vector3(255, 255, 255); //kind of in the middle of the screen, rather than at the top (play)
    private float minFov = 15f;
    private float maxFov = 90f;
    // Start is called before the first frame update
    void Start()
    {
        point = target.transform.position;
        transform.LookAt(point);
    }

    // Update is called once per frame
    void Update()
    {
        // lastMouse = Input.mousePosition - lastMouse ;
        // transform.RotateAround (point,new Vector3(0.0f,1.0f,0.0f),lastMouse.x * speedMod);
        if (Input.GetMouseButtonDown(0))
        {
          lastMouse = Input.mousePosition;
        }
        if (Input.GetMouseButton(0))
        {
            Vector3 delta = Input.mousePosition - lastMouse;
            transform.Translate(delta.x * -0.01f, delta.y * -0.01f, 0);
            lastMouse = Input.mousePosition;
        }

        if (Input.GetMouseButton(1))
        {
            lastMouse = Input.mousePosition - lastMouse;
            transform.RotateAround (point,new Vector3(0.0f,1.0f,0.0f),lastMouse.x * speedMod);
            
        }
        float fov = Camera.main.fieldOfView;
        fov += Input.GetAxis("Mouse ScrollWheel") * -10f;
        fov = Mathf.Clamp(fov, minFov, maxFov);
        Camera.main.fieldOfView = fov;
        lastMouse = Input.mousePosition;
        //transform.RotateAround (point,new Vector3(1.0f,0.0f,0.0f),lastMouse.y * speedMod);
        // lastMouse =  Input.mousePosition;
    }
}
