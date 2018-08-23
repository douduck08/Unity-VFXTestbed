using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent (typeof (Camera))]
public class SetDepthTextureMode : MonoBehaviour {

    [SerializeField] DepthTextureMode depthTextureMode;

    void Start () {
        GetComponent<Camera> ().depthTextureMode = depthTextureMode;
    }

    void Onvalidate () {
        Start ();
    }
}