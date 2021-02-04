using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class MeshGridDeformer : MonoBehaviour {
    public Material material;
    public Vector3[] gridPosition = new Vector3[8];

    void Update () {
        var grid = new float[32];
        for (int i = 0; i < 8; i++) {
            grid[i * 4] = gridPosition[i].x;
            grid[i * 4 + 1] = gridPosition[i].y;
            grid[i * 4 + 2] = gridPosition[i].z;
            grid[i * 4 + 3] = 0;
        }
        material.SetFloatArray ("_Grid", grid);
    }
}
