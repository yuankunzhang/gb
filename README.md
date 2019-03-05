# GB

## Project Structure

```bash
$ tree -L 1
.
├── docker-compose/
├── k8s/
└── vagrant/
```

- `docker-compose/`: contains files to setup a Drupal site in the docker-compose stack.
- `k8s/`: contains manifests to deploy and setup a Drupal site in a Kubernetes cluster.
- `vagrant/`: contains files to setup a Drupal site in the Vagrant environment.

Refer to the README file in each sub-directory for further details.

## Notes

Make sure port 8080 is not occupied by other process on your machine.

The solutions for docker-compose stack and Vagrant environment can be easily tested. However the solution for Kubernetes requires a running Kubernetes cluster in advance.