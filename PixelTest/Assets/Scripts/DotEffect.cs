using UnityEngine;
using System.Collections;

public class DotEffect : MonoBehaviour
{
    [SerializeField] int _fineness = 100;
    [SerializeField] float _outline = 1;
    [SerializeField] Color _outlineColor = Color.black;
    [SerializeField] Material _dotMaterial;

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Vector2 rate = new Vector2(Screen.width, Screen.height).normalized;
        _dotMaterial.SetInt("_Fineness", _fineness);
        _dotMaterial.SetFloat("_Threshold", _outline);
        _dotMaterial.SetVector("_Rate", rate);
        _dotMaterial.SetColor("_OutlineColor", _outlineColor);
        Graphics.Blit(src, dest, _dotMaterial);
    }
}
