using System.Collections;
using UnityEngine;
using TMPro;

public class AskButtonManager : MonoBehaviour
{
    [Header("Elements")]
    [SerializeField] private DiscussionManager discussionManager;
    [SerializeField] private STTBridge sttBridge;
    [SerializeField] private ToggleObject toggleObject;

    public NetworkManager networkManager;

}


   