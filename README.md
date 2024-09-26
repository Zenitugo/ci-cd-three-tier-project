


# Flux CD



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
- OOMKilled for the front end applicatio