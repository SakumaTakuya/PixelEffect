using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class OutlineEffect : MonoBehaviour
{
    [SerializeField] float _outlineFromDepth = 1;
    [SerializeField] float _outlineFromLuminance = 1;
    [SerializeField] float _sharpness = 1000;
    [SerializeField, Range(0,1f)] float _maxDepth  = 100;
    [SerializeField, Range(0,1f)] float _alpha; 
    [SerializeField] float _variance = 1.3f;
    [SerializeField] Color _outlineColor = Color.black;
    [SerializeField] Material _outlineMaterial;

    private void Awake()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
        print(1/Mathf.Sqrt(2*3.14f)/1.3f);
        for(int x = -1; x < 2; x++)
        for(int y = -1; y < 2; y++)        
        print(x+","+y+ ":" +(Mathf.Exp((x*x+y*y)/2/1.3f/1.3f)));
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        _outlineMaterial.SetFloat("_ThresholdDep", _outlineFromDepth);
        _outlineMaterial.SetFloat("_ThresholdLum", _outlineFromLuminance);
        _outlineMaterial.SetFloat("_MaxDepth",_maxDepth);
        _outlineMaterial.SetFloat("_Alpha", _alpha);
        _outlineMaterial.SetColor("_OutlineColor", _outlineColor);
        _outlineMaterial.SetFloat("_Sharpness", _sharpness);
        _outlineMaterial.SetFloat("_Variance", _variance);
        Graphics.Blit(src, dest, _outlineMaterial);
    }
}
