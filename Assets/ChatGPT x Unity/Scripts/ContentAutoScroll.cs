using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class ContentAutoScroll : MonoBehaviour
{
    private RectTransform rectTransform;

    private void Start()
    {
        rectTransform = GetComponent<RectTransform>();
        DiscussionManager.onMessageRecieved += ScrollDown;
    }
    private void OnDestroy() {
        DiscussionManager.onMessageRecieved -= ScrollDown;

    }
    private void DelayScrollDown() {
        Invoke("ScrollDown", .3f);
    }
    private void ScrollDown()
    {
        Vector2 anchoredPosition = rectTransform.anchoredPosition;
        anchoredPosition.y = Mathf.Max(0, rectTransform.sizeDelta.y);

        rectTransform.anchoredPosition = anchoredPosition;
    }
}
