# UB Dspace Helm Template

This Helm Chart can be used to deploy the [DSpace](https://dspace.org) digital repository software
fully functional with all components needed to run it. 

It is designed to work for both local development (e.g. in minikube) and deployment on remote
Kubernetes clusters (development and productive stages).


## Prerequisites

To run DSpace in Kubernetes, it is necessary to have appropriate Docker images for both the Frontend
and the Backend (and possibly the Solr server).

You can use the official DSpace Docker images, but as these are not recommended for use in production,
we recommend building your own images when moving towards a productive environment.

You also need access to need a functioning Kubernetes cluster, either a remote one or,
for testing and development purposes, a local cluster.


## What This Chart Will Install

Except for the namespace and secrets (see below), 
this chart will install everything needed to run DSpace.

It will install a backend, a frontend, a solr server, a database and an Apache httpd proxy.
For each component, it will install a Deployment to manage the pods and a Service to expose 
the container within the cluster network. 
Additionally, there are Persistent Volumes for the backend, the solr Server and each assetstore 
you register in your backend. For each, you can configure the size.
The proxy also comes with an Ingress that will manage incoming traffic.

The database and solr are optional and can be turned off with a toggle.
Instead of dynamically deploying instance of postgres and/or solr with this chart, you can 
use connection strings you might have preconfigured.


## Running DSpace in Minikube

The easiest way to test this chart as well as trying out DSpace in Kubernetes is by running it on 
a local cluster. For this, we use [minikube](https://minikube.sigs.k8s.io), but other clusters
should work in a similar way. However, we provide information only for minikube.


### Setting up Minikube

To set up minikube, we refer to their documentation, as this is highly dependant of your machine. 

To later access the app, we need to install the 
[minikube ingress addon](https://minikube.sigs.k8s.io/docs/handbook/addons/ingress-dns/):
```bash
minikube addons enable ingress
```
Installing `ingress-dns` is not necessary.


### Setting Up the Namespace

A few resources need to be set up manually, as they cannot be managed by helm 
(especially the secrets). For this reason, we manually create a namespace.

Either use the minikube dashboard for the following tasks or use `kubectl`.

First create the namespace `dspace` running

> kubectl create namespace dspace

You can give the namespace another name, but make sure to change your configuration later on if 
you choose to do so.

Next, create the secret that contains the password for the database.
If you install the database with this chart, you can use any password as the 
backend and database instances will be synced automatically (they both consume this secret).
If you want to connect to an existing database, you will of course have to use the correct password.
Run 

> kubectl -n dspace create secret generic dspace-backend-secret --from-literal=db__P__password=dspace

to create a secret with the password `dspace`. Feel free to replace `dspace` with any other 
valid password string.

Finally, you might need to create a docker pull secret for your private docker registry.
If you just want to use the public images from the Docker Hub, this is not necessary, and 
you can safely skip this step.

> kubectl create secret docker-registry regcred --docker-server=DOCKER_REGISTRY_SERVER --docker-username=DOCKER_USER --docker-password=DOCKER_PASSWORD --docker-email=DOCKER_EMAIL

Make sure that the name `regcred` (or any other name you might choose) matches your configuration
during the deployment.


### Configuring the Network

If you have installed the `ingress` addon for minikube, your cluster will also run an
nginx proxy under the ip you receive from `minikube ip`.

You may now choose a URL under which to host your local DSpace installation.
We use `dspace.example`, but if you wish to use another URL, change the `host` entry
in your `values.yaml`.

The following explanation works on Linux operating systems, if you use anything else, 
you may have to make other changes.

To make sure that any request sent to `http://dspace.example` (or your chosen URL) is 
forwarded to the minikube ingress, add a line to your `/etc/host file`: 

> dspace.example <MINIKUPE-IP>

So if `minikube ip` returns `<some-ip>`, then add

> dspace.example <some-ip>

and if you use another URL, change the entry accordingly.

If you now open `http://dspace.example` in your browser, you should get an error message from
an nginx server.


### Deploying the Application

After going through the preparatory steps, simply run 

> helm install dspace-local .

To install the helm chart under the name `dspace-local`.
Wait some time until all pods have started (you can check the logs of each pod) and 
then your application should be available under `http://dspace.example`.

As the persistent volumes are not deleted on uninstallation you can run 

> helm uninstall dspace-local

and then install again. Any data you put into the system will still be there.

Lastly, you will need an admin user to try out your new DSpace installation.

Run 

> kubectl -n dspace exec -it deploy/dspace-local-backend -- bash

to open a shell in the backend pod, or more easily use the minikube dashboard.
Inside the pod, run 

> bin/dspace create-administrator

and follow the instructions.


## IIIF Support

The helm chart also supports the IIIF plugin for DSpace.
To enable it, simply set `iiifEnabled` to `true` in your `values.yaml` and uncomment the 
settings for the Cantaloupe image. You may also change these if you have other requirements.
This will start a Cantaloupe image server along with the DSpace installation and configure 
the backend to enable IIIF support and use the provisioned Cantaloupe instance.
 
## Values Reference

| Key                                    | Comment                                                                                                                                                                                                                                                                       |
|----------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `namespace`                            | Kubernetes namespace in which to deploy                                                                                                                                                                                                                                       |
| `host`                                 | Public URL for the DSpace instance                                                                                                                                                                                                                                            |
| `hostProtocol`                         | `http` or `https`, depending on your endpoint                                                                                                                                                                                                                                 |
| `imagePullSecret`                      | Name of the Docker Pull Secret in your `namespace`, only neccessary if you use a private registry.                                                                                                                                                                            |
| `tolerationKey`                        | Use only if you cluster supports or requires node tolerations.                                                                                                                                                                                                                |
| `dbUrl`                                | Set this to the _jdbc_ connection string if you want to connect your backend to an external database                                                                                                                                                                          |
| `dbUsername`                           | Username your backend uses for the database (automatically used by the database if dynamically provided)                                                                                                                                                                      |
| `dbImageName`                          | Which image to use for the database (ignored if `dbUrl` is set)                                                                                                                                                                                                               |
| `dbImageVersion`                       | Which image tag to use for the database (ignored if `dbUrl` is set)                                                                                                                                                                                                           |
| `dbDatabaseName`                       | Database name in the deployed database container (ignored if `dbUrl` is `set`)                                                                                                                                                                                                |
| `dbExistingPvcName`                    | Only set if you want to deploy a database and mount an existing PVC (the PVC needs to be in the `namespace`)                                                                                                                                                                  |
| `dbPvcStorageClass`                    | Kubernetes Storage Class for a dynamically provided database PVC (ignored if `dbExistingPvcName` is set)                                                                                                                                                                      |
| `dbPvcSize`                            | Size of the dynamically provided database PVC (ignored if `dbExistingPvcName` is set)                                                                                                                                                                                         |
| `solrUrl`                              | If you want to use an external Solr server, set this to to the connection string, if `null` a Solr server is provided                                                                                                                                                         |
| `solrMulticorePrefix`                  | Multicore prefix for the solr connection                                                                                                                                                                                                                                      |
| `solrImageName`                        | Which image to use for Solr (ignored if `solrUrl` is set)                                                                                                                                                                                                                     |
| `solrImageVersion`                     | Which image tag to use for Solr (ignored if `solrUrl` is set)                                                                                                                                                                                                                 |
| `solrDatabaseName`                     | Database name in the deployed Solr container (ignored if `solrUrl` is set)                                                                                                                                                                                                    |
| `solrExistingPvcName`                  | Only set if you want to deploy Solr and mount an existing PVC (the PVC needs to be in the `namespace`)                                                                                                                                                                        |
| `solrPvcStorageClass`                  | Kubernetes Storage Class for a dynamically provided Solr PVC (ignored if `solrExistingPvcName` is set)                                                                                                                                                                        |
| `solrPvcSize`                          | Size of the dynamically provided Solr PVC (ignored if `solrExistingPvcName` is set)                                                                                                                                                                                           |
| `solrInitCommands`                     | Array of shell commands that run in an init Container before Solr start-up                                                                                                                                                                                                    | 
| `backendImageName`                     | Name of the DSpace backend image                                                                                                                                                                                                                                              |
| `backendImageVersion`                  | Tag of the DSpace backend image                                                                                                                                                                                                                                               |
| `backendConfigSecret`                  | Name of the precreated secret containing at least the `db__P__password` key, needs to be in `namespace`                                                                                                                                                                       |
| `backendInstanceName`                  | Name of your DSpace instance as displayed in the application                                                                                                                                                                                                                  |
| `backendPath`                          | Context path of your backend, usually `/server`                                                                                                                                                                                                                               |
| `backendAssetstores`                   | Array with an item for each assetstore configured in your backend's `bitstore.xml`                                                                                                                                                                                            |
| `backendAssetstores[].volumeName`      | Internal name of the volume in the deployment, needs to be unique                                                                                                                                                                                                             |
| `backendAssetstores[].mountPath`       | Path in your container to mount the volume, should agree with your `bitstore.xml`                                                                                                                                                                                             |
| `backendAssetstores[].existingPvcName` | Set if you want to use an existing PVC for this assetstore, otherwise omit                                                                                                                                                                                                    |
| `backendAssetstores[].storageClass`    | Kubernetes Storage Class for this PVC, only set if you want to dynamically provide a PVC for this assetstore                                                                                                                                                                  |
| `backendAssetstores[].storageSize`     | Size of the deployed PVC, only set if you want to dynamically provide a PVC for this assetstore                                                                                                                                                                               |
| `backendInitCommands`                  | Array of shell commands that run in an init container before the backend start-up                                                                                                                                                                                             |
| `backendAdditionalEnvVariables`        | Key value pairs that are injected into the backend as environment variables                                                                                                                                                                                                   |
| `frontendImageName`                    | Name of the DSpace frontend image                                                                                                                                                                                                                                             |
| `frontendImageVersion`                 | Tag of the DSpace frontend image                                                                                                                                                                                                                                              |
| `backendUIHost`                        | `ui.host` value in your frontend `config.yml`                                                                                                                                                                                                                                 |
| `frontendUINamespace`                  | Context path of your frontend, usually `/`                                                                                                                                                                                                                                    |
| `frontendRunInDevelopmentMode`         | If `true`, the frontend container will run with `npm run serve` and disable the host check. This way, the frontend image provided by DSpace runs in Minikube, for productive environments this should be `false` and the appropriate `command` should be set by the container |
| `frontendAdditionalEnvVariables`       | Key value pairs that are injected into the frontend as environment variables                                                                                                                                                                                                  |
| `proxyImageName`                       | Name of the Apache httpd image                                                                                                                                                                                                                                                |
| `proxyImageVersion`                    | Tag of the Apache httpd image                                                                                                                                                                                                                                                 |
| `proxyIngressClass`                    | Ingress class of the Kubernetes Cluster, depends on your cluster.                                                                                                                                                                                                             |
| `iiifEnabled`                          | `true` if the IIIF addon should be enabled in your backend, else `false`. If `true`, an image server will be part of the deployment                                                                                                                                           |
| `iiifServerImageName`                  | Name of the IIIF image server Docker image                                                                                                                                                                                                                                    |
| `iiifServerImageVersion`               | Tag of the IIIF image server Docker image                                                                                                                                                                                                                                     |
| `cronJobs`                             | Array with a CronJob running for each entry (also using the backend image and configuration)                                                                                                                                                                                  |
| `cronJobs[].name`                      | Internal Kubernetes resource name of your CronJob                                                                                                                                                                                                                             |
| `cronJobs[].schedule`                  | Schedule of the CronJob, needs to adhere to the schedule syntax of Kubernetes                                                                                                                                                                                                 |
| `cronJobs[].active`                    | Toggle the job on and off by setting this to `true` or `false`                                                                                                                                                                                                                |
| `cronJobs[].command`                   | Shell command to run in the Job, usually `["sh", "-c"]`                                                                                                                                                                                                                       |
| `cronJobs[].args`                      | Arguments for the shell command, set your job here.                                                                                                                                                                                                                           |


## Acknowledgement

This is a project originally created by the [UBLabs](https://labs.ub.uni-frankfurt.de/) group 
at [Frankfurt University Library](https://www.ub.uni-frankfurt.de/),
with contributions from the [VABiKo](https://vabiko.eu/) project, which is funded by the 
German Research Foundation (DFG; project identifier [531013489](https://gepris.dfg.de/project/531013489)).