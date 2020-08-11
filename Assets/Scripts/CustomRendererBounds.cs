using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent (typeof (MeshFilter), typeof (Renderer))]
public class CustomRendererBounds : MonoBehaviour {

    [SerializeField] Bounds customBounds;

    void Start () {
        var meshFilter = GetComponent<MeshFilter> ();
        var mesh = meshFilter.sharedMesh;
        mesh.bounds = customBounds;
    }

    void OnDrawGizmosSelected () {
        var renderer = GetComponent<Renderer> ();
        var bounds = renderer.bounds;

        Gizmos.color = Color.yellow;
        Gizmos.DrawWireCube (bounds.center, bounds.size);

        Gizmos.matrix = transform.localToWorldMatrix;
        Gizmos.color = Color.red;
        Gizmos.DrawWireCube (customBounds.center, customBounds.size);
    }
}
