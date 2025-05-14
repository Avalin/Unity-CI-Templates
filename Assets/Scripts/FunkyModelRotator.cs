using UnityEngine;

public class FunkyModelRotator : MonoBehaviour
{
    private Vector3 rotationVelocity = Vector3.zero;
    private Vector3 lastMousePosition;
    private bool isDragging = false;

    public float dragSensitivity = 0.2f;
    public float momentumDamping = 2f; // Higher = faster stop

    void Update()
    {
        // Mouse down
        if (Input.GetMouseButtonDown(0))
        {
            isDragging = true;
            lastMousePosition = Input.mousePosition;
        }

        // Mouse up
        if (Input.GetMouseButtonUp(0))
        {
            isDragging = false;
        }

        if (isDragging)
        {
            Vector3 delta = Input.mousePosition - lastMousePosition;
            rotationVelocity = new Vector3(-delta.y, delta.x, 0) * dragSensitivity;
            lastMousePosition = Input.mousePosition;
        }
        else
        {
            // Apply damping to rotation velocity
            rotationVelocity = Vector3.Lerp(
                rotationVelocity,
                Vector3.zero,
                Time.deltaTime * momentumDamping
            );
        }

        // Rotate object based on velocity
        transform.Rotate(rotationVelocity, Space.World);
    }
}
