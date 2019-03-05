# Running Drupal in Kubernetes

## Usage

Make sure you have your kubectl configured properly.

To start the pods:

```bash
$ kubectl apply -f mysql-deployment.yaml
$ kubectl apply -f mysql-svc.yaml
$ kubectl apply -f drupal-deployment.yaml
```

After the pods are up and running, use port forwarding to communicate with the Drupal pod:

```bash
$ kubectl port-forward (kubectl get po -l app=drupal -o jsonpath="{.items[0].metadata.name}") 8080:80
```

And now you are able to visit http://localhost:8080 in your browser.

To tear down the pods:

```bash
$ kubectl delete -f drupal-deployment.yaml
$ kubectl delete -f mysql-svc.yaml
$ kubectl delete -f mysql-deployment.yaml
```

