using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class InkPaintEffect : MonoBehaviour
{
    [SerializeField, Range(0,1f)] float _outlineFromDepth = 0.005f;
    [SerializeField, Range(0,5f)] float _outlineFromLuminance = 0.4f;
    [SerializeField, Range(0, 10f)] float _outlineSharpness = 0.9f;
    [SerializeField, Range(0,1f)] float _maxDepth  = 0;
    [SerializeField, Range(0,1f)] float _noise = 0.3f; 
    [SerializeField] Color _outlineColor = Color.black;

    [SerializeField] float _variance = 1.3f;
    [SerializeField, Range(0,5)] int _gausRadius = 1;
    [SerializeField, Range(0, 1000f)] float _gausResolution = 3.5f;
    
    [SerializeField, Range(0,1f)] float _intensity = 0.25f;

    [SerializeField, Range(0,5)] int _edgePreserveRadius = 2;
    [SerializeField, Range(0,1f)] float _edgePreserveResolution = 1; 

    [SerializeField] Material _material;


    private void Awake()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        _material.SetFloat("_ThresholdDep", _outlineFromDepth);
        _material.SetFloat("_ThresholdLum", _outlineFromLuminance);
        _material.SetFloat("_MaxDepth",_maxDepth);
        _material.SetFloat("_Alpha", _noise);
        _material.SetColor("_OutlineColor", _outlineColor);
        _material.SetFloat("_OutlineSharpness", _outlineSharpness);
        _material.SetFloat("_Variance", _variance);
        _material.SetInt("_GausRadius", _gausRadius);
        _material.SetFloat("_GausResolution", _gausResolution);
        _material.SetFloat("_Intensity",1 - _intensity);
        _material.SetFloat("_EdgePreserveResolution", _edgePreserveResolution);
        _material.SetInt("_EdgePreserveRadius", _edgePreserveRadius);
        
        Graphics.Blit(src, dest, _material);

    }
}
