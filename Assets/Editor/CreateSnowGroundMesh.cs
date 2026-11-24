using UnityEngine;
using UnityEditor;

public class CreateSnowGroundMesh
{
    [MenuItem("Tools/Snow/生成 50x50 高密测试地面")]
    static void CreateMesh()
    {
        int res = 240;          // 240x240 格 (5.8万顶点，刚好卡在16位索引高效区，约20cm一格)
        float size = 50f;       // 50米 x 50米
        float hillHeight = 1.8f;// 一点柔和的坡度起伏

        Mesh mesh = new Mesh { name = "SnowGround_50m" };
        int vCount = (res + 1) * (res + 1);
        Vector3[] verts = new Vector3[vCount];
        Vector2[] uvs = new Vector2[vCount];
        int[] tris = new int[res * res * 6];

        for (int z = 0; z <= res; z++)
        {
            for (int x = 0; x <= res; x++)
            {
                int i = z * (res + 1) + x;
                float u = (float)x / res;
                float v = (float)z / res;
                float wx = (u - 0.5f) * size;
                float wz = (v - 0.5f) * size;
                // 用双层柏林噪声造缓坡
                float wy = Mathf.PerlinNoise(wx * 0.06f + 10f, wz * 0.06f + 10f) * hillHeight;

                verts[i] = new Vector3(wx, wy, wz);
                uvs[i] = new Vector2(u, v);
            }
        }

        int t = 0;
        for (int z = 0; z < res; z++)
        {
            for (int x = 0; x < res; x++)
            {
                int i0 = z * (res + 1) + x;
                int i1 = (z + 1) * (res + 1) + x;
                int i2 = z * (res + 1) + (x + 1);
                int i3 = (z + 1) * (res + 1) + (x + 1);

                tris[t++] = i0; tris[t++] = i1; tris[t++] = i2;
                tris[t++] = i2; tris[t++] = i1; tris[t++] = i3;
            }
        }

        mesh.vertices = verts;
        mesh.uv = uvs;
        mesh.triangles = tris;
        mesh.RecalculateNormals();
        mesh.RecalculateBounds();

        AssetDatabase.CreateAsset(mesh, "Assets/SnowGround_50m.asset");
        AssetDatabase.SaveAssets();
        Debug.Log("生成完成：Assets/SnowGround_50m.asset");
    }
}