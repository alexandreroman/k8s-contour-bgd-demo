# Blue/green deployment using Contour on Kubernetes

This project shows how to use [Contour](https://projectcontour.io)
to implement blue/green deployment between two apps running in a Kubernetes
cluster.

<img src="https://i.imgur.com/lpC4ST9.gif"/>

## How to use it?

Make sure to install Contour first:
[please follow these instructions](https://projectcontour.io/getting-started).

This repository relies on [Carvel tools](https://carvel.dev)
for templating Kubernetes manifest
files: make sure you have `ytt`, `kbld` and `kapp` installed on your workstation.

Deploy a sample app to your cluster (`app-v1` and `app-v2`):
```bash
$ make deploy
```

This app deploys its resources in the namespace `k8s-contour-bgd`:
```bash
$ kubectl -n k8s-contour-bgd get po,svc,proxy
```

This app is served by an ingress controller defined by this configuration:
```yaml
---
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata: 
  name: app
  namespace: k8s-contour-bgd
spec: 
  virtualhost:
    fqdn: foobar.com
  routes: 
  - match: / 
    services:
    - name: app-v1
      port: 8080
      weight: 100
```

Contour is using a `LoadBalancer` service to accept traffic.
Get the public endpoint for this ingress controller:
```bash
$ APP_ADDR=$(kubectl -n projectcontour get svc contour -o json | jq -r ".status.loadBalancer.ingress[].ip")
$ echo $APP_ADDR
1.2.3.4
```

Hit app endpoint:
```bash
$ curl -s -w "\n" -H "Host: foobar.com" $APP_ADDR
Hello V1!
```

Let's add a new service in the ingress configuration to enable `app-v2`:
```yaml
---
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata: 
  name: app
  namespace: k8s-contour-bgd
spec: 
  virtualhost:
    fqdn: foobar.com
  routes: 
  - match: / 
    services:
    - name: app-v1
      port: 8080
      weight: 100
    - name: app-v2
      port: 8080
      weight: 0
```

Since we use "`weight: 0`" for `app-v2`, all traffic is still sent to `app-v1`:
```bash
$ curl -s -w "\n" -H "Host: foobar.com" $APP_ADDR
Hello V1!
```

Now let's update ingress configuration by redirecting 10% of traffic to `app-v2`:
```yaml
---
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata: 
  name: app
  namespace: k8s-contour-bgd
spec: 
  virtualhost:
    fqdn: foobar.com
  routes: 
  - match: / 
    services:
    - name: app-v1
      port: 8080
      weight: 90
    - name: app-v2
      port: 8080
      weight: 10
```

From now on, 10% of traffic is now hitting `app-v2`:
```bash
$ while true; do sleep .1 && curl -s -w "\n" -H 'Host: foobar.com' $APP_ADDR; done
Hello V1!
Hello V1!
Hello V1!
Hello V1!
Hello V2!
Hello V1!
Hello V1!
Hello V1!
Hello V1!
Hello V1!
Hello V1!
Hello V1!
Hello V2!
Hello V1!
```

You can edit ingress configuration live, and see how this configuration is applied
without loosing a single request:
```bash
$ kubectl -n k8s-contour-bgd edit proxy app
```

## Contribute

Contributions are always welcome!

Feel free to open issues & send PR.

## License

Copyright &copy; 2021 [VMware, Inc. or its affiliates](https://vmware.com).

This project is licensed under the [Apache Software License version 2.0](https://www.apache.org/licenses/LICENSE-2.0).
