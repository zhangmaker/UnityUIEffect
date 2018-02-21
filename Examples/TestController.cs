using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace DemoSpace
{
    public class TestController : MonoBehaviour
    {
        public GameObject[] PageObject;
        public Button NextPageBtn;
        private int m_CurrentIndex;

        // Use this for initialization
        void Start()
        {
            NextPageBtn.onClick.AddListener(delegate ()
            {
                clickNextPage();
            });
        }

        // Update is called once per frame
        void Update()
        {
            
        }

        private void clickNextPage()
        {
            if (m_CurrentIndex+1 >= PageObject.Length)
            {
                m_CurrentIndex = 0;
            }
            else
            {
                m_CurrentIndex++;
            }

            for (int objIndex = 0; objIndex < PageObject.Length; ++objIndex)
            {
                if(objIndex == m_CurrentIndex)
                {
                    PageObject[objIndex].SetActive(true);
                }
                else
                {
                    PageObject[objIndex].SetActive(false);
                }
            }
        }
    }
}

