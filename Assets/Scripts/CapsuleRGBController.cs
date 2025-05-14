using UnityEngine;

public class CapsuleRGBController : MonoBehaviour
{
    [SerializeField] private MeshRenderer capsule;
    [SerializeField] private float speed = 0.2f;

    private Material capsuleMaterial;
    private float hue;

    private void Start()
    {
        capsuleMaterial = capsule.material;
        hue = 0f;
    }

    private void Update()
    {
        hue += Time.deltaTime * speed;
        if (hue > 1f)
            hue -= 1f;

        Color rgbColor = Color.HSVToRGB(hue, 1f, 1f);
        capsuleMaterial.color = rgbColor;
    }
}
