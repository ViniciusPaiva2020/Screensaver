using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;
public class patrulhando : MonoBehaviour
{
    public GameObject ponto1;
    public GameObject ponto2;
    public GameObject ponto3;
    GameObject pontoAtual;
    // Start is called before the first frame update
    void Start()
    {
        pontoAtual = ponto1;
        patrol();
    }
    public void patrol()
    {
        NavMeshAgent agente = GetComponent<NavMeshAgent>();
        agente.SetDestination(pontoAtual.transform.position);
        Debug.Log("Entrou 0");
    }
    private void OnTriggerEnter(Collider other)
    {
        if (other.gameObject.name.Equals(ponto1.gameObject.name))
        {
            pontoAtual = ponto2;
            Debug.Log("Entrou 1");
        }
        else if (other.gameObject.name.Equals(ponto2.gameObject.name))
        {
            pontoAtual = ponto3;
            Debug.Log("Entrou 2");
        }
        else
        {
            pontoAtual = ponto1;
            Debug.Log("Entrou 3");
        }
        patrol();
    }
}