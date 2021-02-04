using System.Collections;
using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;

[CustomEditor (typeof (MeshGridDeformer))]
public class MeshGridDeformerEditor : Editor {

    int currentId = -1;

    void OnSceneGUI () {
        var target = this.target as MeshGridDeformer;
        if (target == null) {
            return;
        }

        var transform = target.transform;
        var handleSize = HandleUtility.GetHandleSize (transform.position) * 0.05f;
        var snap = Vector3.one * 0.5f;
        Handles.matrix = transform.localToWorldMatrix;
        Handles.color = new Color (1, 1, 1, 0.5f);

        DrawGridLines (target);

        for (int id = 0; id < 8; id++) {
            EditorGUI.BeginChangeCheck ();
            var pos = Handles.FreeMoveHandle (target.gridPosition[id], Quaternion.identity, handleSize, snap,
                (controlID, position, rotation, size, eventType) => {
                    if (controlID == GUIUtility.hotControl) {
                        currentId = id;
                    };
                    Handles.DotHandleCap (controlID, position, rotation, size, eventType);
                }
            );
            if (EditorGUI.EndChangeCheck ()) {
                Undo.RecordObject (target, "Changed");
                target.gridPosition[currentId] = pos;
            }
        }

        if (currentId != -1) {
            EditorGUI.BeginChangeCheck ();
            var pos = Handles.PositionHandle (target.gridPosition[currentId], Quaternion.identity);
            if (EditorGUI.EndChangeCheck ()) {
                Undo.RecordObject (target, "Changed");
                target.gridPosition[currentId] = pos;
            }
        }
    }

    void DrawGridLines (MeshGridDeformer target) {
        for (int x = 0; x < 2; x++) {
            for (int y = 0; y < 2; y++) {
                for (int z = 0; z < 2; z++) {
                    if (x < 1) {
                        Handles.DrawLine (target.gridPosition[IndexToId (x, y, z)], target.gridPosition[IndexToId (x + 1, y, z)]);
                    }
                    if (y < 1) {
                        Handles.DrawLine (target.gridPosition[IndexToId (x, y, z)], target.gridPosition[IndexToId (x, y + 1, z)]);
                    }
                    if (z < 1) {
                        Handles.DrawLine (target.gridPosition[IndexToId (x, y, z)], target.gridPosition[IndexToId (x, y, z + 1)]);
                    }
                }
            }
        }
    }

    public override void OnInspectorGUI () {
        base.OnInspectorGUI ();

        if (GUILayout.Button ("Reset Grid")) {
            ResetGrid ();
        }
    }

    void ResetGrid () {
        var target = this.target as MeshGridDeformer;
        if (target == null) {
            return;
        }

        target.gridPosition = new Vector3[8];
        for (int id = 0; id < 8; id++) {
            var index = IdToIndex (id);
            target.gridPosition[id] = new Vector3 (-0.5f, -0.5f, -0.5f) + new Vector3 (1f * index.x, 1f * index.y, 1f * index.z);
        }
    }

    Vector3Int IdToIndex (int id) {
        var result = new Vector3Int ();
        result.z = id % 2;
        id /= 2;
        result.y = id % 2;
        id /= 2;
        result.x = id;
        return result;
    }

    int IndexToId (int x, int y, int z) {
        return x * 4 + y * 2 + z;
    }
}
#endif