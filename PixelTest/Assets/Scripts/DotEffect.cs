using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Camera))]
public class DotEffect : MonoBehaviour
{
    [SerializeField] int _frameRate = 30;
    [SerializeField] int _fineness = 100;
    [SerializeField] float _outlineFromLuminance = 1;
    [SerializeField] float _outlineFromDepth = 1;
    [SerializeField] float _sharpness = 0.5f;
    [SerializeField] Color _outlineColor = Color.black;
    [SerializeField] Material _dotMaterial;

    private void Awake()
    {
        Application.targetFrameRate = _frameRate;
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Vector2 rate = new Vector2(Screen.width, Screen.height).normalized;
        _dotMaterial.SetInt("_Fineness", _fineness);
        _dotMaterial.SetFloat("_ThresholdLum", _outlineFromLuminance);
        _dotMaterial.SetFloat("_ThresholdDep", _outlineFromDepth);
        _dotMaterial.SetVector("_Rate", rate);
        _dotMaterial.SetColor("_OutlineColor", _outlineColor);
        _dotMaterial.SetFloat("_Sharpness", _sharpness);
        Graphics.Blit(src, dest, _dotMaterial);
    }
}
