# DEVEOPS PROJECT 
This project is a solution to the [capstone project](https://thedevops.guide/capstone-project) given by Rishab Kumar


# Architectural Design






# GITHUB ACTIONS PIPELINE

This pipeline starts with building the docker image of each part of the application and pushing them to docker hub. Next, is the creation of the Kubernetes cluster using Terraform.

The piepline was used to create kubernetes secrets into the cluster by setting the environmental variables in Github Secrets, as well as install the folllowing tools
- Grafana
- Ingress nginx
- Cert mnager
- Flux CD
- Cloud watch

# Flux CD
Flux CD like Argo CD is used to deploy application into the kubernetes cluster. The creation of flux requires the following steps highlighted in the workflow script.

# Flux Dashboard
To visualise your deployment you need to see your deployment on a dashboard. Unfortunately deploying with Flux doesn't automatically mean you can visualise it. You have to install Capacitor on yourf cluster to visualize it. Check [Here](https://bit.ly/4gCuH9Q) to see more on capacitor.

After applying the configuration of the dashboard as stated in the workflow scripts, you can monitor the sync status to ensure FluxCD pulls the Capacitor manifests successfully using 
```
    flux get kustomizations -A

```

Once the dashboard is deployed, you'll need to expose it as stated in the documentation
```
    kubectl -n flux-system port-forward svc/capacitor 9000:9000

```


# Challenges
- CrashLoopBackOff for both frontend and backend
- OOMKilled for the front end application