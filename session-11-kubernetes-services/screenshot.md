# Session 11 - Kubernetes Services

Submission checklist covering all five Service types: **ClusterIP, NodePort, LoadBalancer,
ExternalName and Headless**.

> **Status: evidence not yet captured.** Every screenshot below is a placeholder. The commands
> are the exact ones to run; nothing in this file is copied from documentation and no output has
> been invented. Fill each placeholder in with the real capture and delete this note when done.

## Environment assumed

- A running `minikube` cluster (`minikube start`)
- `kubectl` pointed at that cluster
- A debug client pod with both `curl` and `nslookup`:

```bash
kubectl run client-pod --image=nicolaka/netshoot --restart=Never -- sleep 3600
kubectl wait --for=condition=Ready pod/client-pod --timeout=120s
```

## Shared workload

Four of the five demonstrations route to the same Deployment. Create it once:

```bash
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:alpine
          ports:
            - containerPort: 80
EOF
```

---

## 1. ClusterIP

**Objective:** Show the default Service type - a stable virtual IP reachable only from inside the
cluster, load-balancing across the pods selected by its label selector.

### Screenshot 1

**Demonstrates:** The backing Deployment and its pods are running.
**Command:**
```bash
kubectl get deployment web-deployment && kubectl get pods -l app=web -o wide
```
**Evidence:** Deployment reports 3/3 ready; three pods in `Running` state, each with its own pod IP
in the `-o wide` output. Those IPs are what the Service must resolve to in Screenshot 3.
**Screenshot:**

### Screenshot 2

**Demonstrates:** A ClusterIP Service exists and has been assigned a cluster-internal virtual IP.
**Command:**
```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web-service-clusterip
spec:
  type: ClusterIP
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
EOF
kubectl get svc web-service-clusterip
```
**Evidence:** `TYPE` is `ClusterIP`, `CLUSTER-IP` holds an address from the service CIDR, and
`EXTERNAL-IP` is `<none>` - proving this Service is not reachable from outside the cluster.
**Screenshot:**

### Screenshot 3

**Demonstrates:** The Service endpoints resolve to the actual backend pod IPs.
**Command:**
```bash
kubectl get endpoints web-service-clusterip
kubectl describe svc web-service-clusterip
```
**Evidence:** The `ENDPOINTS` column lists three `<pod-ip>:80` entries that match the pod IPs from
Screenshot 1. This is the link between the label selector and the real pods.
**Screenshot:**

### Screenshot 4

**Demonstrates:** The client pod exists and can reach the Service by DNS name from inside the cluster.
**Command:**
```bash
kubectl get pod client-pod
kubectl exec client-pod -- nslookup web-service-clusterip.default.svc.cluster.local
kubectl exec client-pod -- curl -s -o /dev/null -w 'clusterip -> HTTP %{http_code}\n' http://web-service-clusterip
```
**Evidence:** `client-pod` is `Running`; `nslookup` resolves the Service name to the ClusterIP from
Screenshot 2; the curl returns `HTTP 200`, proving in-cluster reachability.
**Screenshot:**

---

## 2. NodePort

**Objective:** Expose the same Deployment on a fixed port on every cluster node, making it reachable
from outside the cluster via the node's IP.

### Screenshot 5

**Demonstrates:** The backing Deployment and its pods are running.
**Command:**
```bash
kubectl get deployment web-deployment && kubectl get pods -l app=web
```
**Evidence:** 3/3 replicas ready and three pods `Running` before the NodePort Service is layered on top.
**Screenshot:**

### Screenshot 6

**Demonstrates:** A NodePort Service has been created.
**Command:**
```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web-service-nodeport
spec:
  type: NodePort
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
EOF
kubectl get svc web-service-nodeport
```
**Evidence:** `TYPE` is `NodePort` and the Service was accepted with the explicitly requested port.
**Screenshot:**

### Screenshot 7

**Demonstrates:** The Service maps port 80 to node port 30080.
**Command:**
```bash
kubectl get svc web-service-nodeport -o wide
kubectl describe svc web-service-nodeport
```
**Evidence:** The `PORT(S)` column reads `80:30080/TCP`, and `describe` shows a `NodePort:` line of
`30080/TCP` alongside the same endpoint IPs as the ClusterIP Service - a NodePort is a ClusterIP
with a node-level port added.
**Screenshot:**

### Screenshot 8

**Demonstrates:** The minikube node and the IP that the node port is exposed on.
**Command:**
```bash
kubectl get nodes -o wide
minikube ip
```
**Evidence:** The node's `INTERNAL-IP` matches the address printed by `minikube ip`. That address
plus port 30080 is the URL used in the next two screenshots.
**Screenshot:**

### Screenshot 9

**Demonstrates:** The application answers over the NodePort from the host, outside the cluster.
**Command:**
```bash
curl -s -o /dev/null -w 'nodeport -> HTTP %{http_code}\n' http://$(minikube ip):30080
curl -s http://$(minikube ip):30080 | head -5
```
**Evidence:** `HTTP 200` and the first lines of the nginx welcome page, returned to the host shell -
not from inside a pod. This is the difference from ClusterIP.
**Screenshot:**

### Screenshot 10

**Demonstrates:** Browser verification of the NodePort Service.
**Command:**
```bash
minikube service web-service-nodeport --url   # prints the URL to open
```
**Evidence:** A browser window showing the nginx welcome page, with `http://<minikube-ip>:30080`
visible in the address bar.
**Screenshot:**

---

## 3. LoadBalancer

**Objective:** Request an external IP from the platform's load balancer. On minikube this is
provided by `minikube tunnel` rather than a cloud provider.

### Screenshot 11

**Demonstrates:** The backing Deployment and its pods are running.
**Command:**
```bash
kubectl get deployment web-deployment && kubectl get pods -l app=web
```
**Evidence:** 3/3 replicas ready and three pods `Running`.
**Screenshot:**

### Screenshot 12

**Demonstrates:** A LoadBalancer Service has been created and is initially pending an external IP.
**Command:**
```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web-service-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
EOF
kubectl get svc web-service-loadbalancer
```
**Evidence:** `TYPE` is `LoadBalancer`. Capture this *before* starting the tunnel - `EXTERNAL-IP`
should read `<pending>`, which is the point: nothing is assigning one yet.
**Screenshot:**

### Screenshot 13

**Demonstrates:** `minikube tunnel` supplying the external IP, and the Service picking it up.
**Command:**
```bash
# Terminal 1 - leave running, it asks for sudo
minikube tunnel

# Terminal 2
kubectl get svc web-service-loadbalancer
```
**Evidence:** Two panes or two captures: the tunnel process running, and `EXTERNAL-IP` on the
Service having changed from `<pending>` to a real address. Compare against Screenshot 12.
**Screenshot:**

### Screenshot 14

**Demonstrates:** Reaching the Service through its LoadBalancer address.
**Command:**
```bash
minikube service web-service-loadbalancer
curl -s -o /dev/null -w 'loadbalancer -> HTTP %{http_code}\n' \
  http://$(kubectl get svc web-service-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```
**Evidence:** `minikube service` prints the service URL and opens it; the curl against the
`EXTERNAL-IP` returns `HTTP 200`.
**Screenshot:**

### Screenshot 15

**Demonstrates:** Browser verification of the LoadBalancer Service.
**Command:**
```bash
minikube service web-service-loadbalancer --url
```
**Evidence:** A browser window showing the nginx welcome page, with the LoadBalancer URL in the
address bar - a different address from the NodePort capture in Screenshot 10.
**Screenshot:**

---

## 4. ExternalName

**Objective:** Show a Service that performs no proxying and has no selector or endpoints - it is
purely a CNAME record mapping an in-cluster DNS name to an external hostname.

### Screenshot 16

**Demonstrates:** An ExternalName Service pointing at `api.github.com`.
**Command:**
```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: github-api-service
spec:
  type: ExternalName
  externalName: api.github.com
EOF
kubectl get svc github-api-service
kubectl describe svc github-api-service
```
**Evidence:** `TYPE` is `ExternalName`, `EXTERNAL-IP` column shows `api.github.com`, and `CLUSTER-IP`
is `<none>`. `describe` shows no `Endpoints:` - unlike every Service above, nothing is selected.
**Screenshot:**

### Screenshot 17

**Demonstrates:** DNS resolution of the Service name from a client pod returns a CNAME to the
external host.
**Command:**
```bash
kubectl exec client-pod -- nslookup github-api-service.default.svc.cluster.local
```
**Evidence:** The lookup resolves through `api.github.com` to GitHub's public IP addresses - proving
cluster DNS is doing the redirection, not kube-proxy.
**Screenshot:**

### Screenshot 18

**Demonstrates:** Reaching the real external API through the ExternalName Service name.
**Command:**
```bash
kubectl exec client-pod -- \
  curl -sk -o /dev/null -w 'externalname -> HTTP %{http_code}\n' \
  https://github-api-service.default.svc.cluster.local/
```
**Evidence:** `HTTP 200` from GitHub's API, reached via the in-cluster name.
**Note for the write-up:** `-k` is required here and that is worth explaining rather than hiding.
The TLS certificate is issued for `api.github.com`, but the URL requests
`github-api-service.default.svc.cluster.local`, so verification fails. It is a genuine limitation of
ExternalName with HTTPS backends. The alternative that passes verification is
`curl -s --resolve` or sending the correct SNI:
```bash
kubectl exec client-pod -- \
  curl -s -o /dev/null -w 'externalname (correct SNI) -> HTTP %{http_code}\n' \
  --connect-to github-api-service.default.svc.cluster.local:443:api.github.com:443 \
  https://api.github.com/
```
**Screenshot:**

---

## 5. Headless Service

**Objective:** Show `clusterIP: None` - no virtual IP and no load balancing. DNS returns the pod IPs
directly, and each StatefulSet pod gets its own stable DNS name, which is how stateful clients
address a specific replica.

### Screenshot 19

**Demonstrates:** A Headless Service with `ClusterIP: None`.
**Command:**
```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web-service-headless
spec:
  clusterIP: None
  selector:
    app: web-sts
  ports:
    - port: 80
      targetPort: 80
EOF
kubectl get svc web-service-headless
```
**Evidence:** The `CLUSTER-IP` column reads `None` - contrast directly with Screenshot 2, where a
real virtual IP was allocated.
**Screenshot:**

### Screenshot 20

**Demonstrates:** StatefulSet pods running with stable ordinal names.
**Command:**
```bash
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-statefulset
spec:
  serviceName: web-service-headless
  replicas: 3
  selector:
    matchLabels:
      app: web-sts
  template:
    metadata:
      labels:
        app: web-sts
    spec:
      containers:
        - name: web
          image: nginx:alpine
          ports:
            - containerPort: 80
EOF
kubectl rollout status statefulset/web-statefulset --timeout=180s
kubectl get pods -l app=web-sts -o wide
```
**Evidence:** Exactly three pods named `web-statefulset-0`, `-1`, `-2` - ordinal, not the random
suffixes the Deployment's pods carry in Screenshot 1 - each `Running` with its own pod IP.
**Screenshot:**

### Screenshot 21

**Demonstrates:** DNS against a headless Service returns all pod IPs rather than one virtual IP.
**Command:**
```bash
kubectl exec client-pod -- nslookup web-service-headless.default.svc.cluster.local
kubectl exec client-pod -- nslookup web-statefulset-0.web-service-headless.default.svc.cluster.local
```
**Evidence:** The first lookup returns three A records - the three pod IPs from Screenshot 20. The
second resolves the per-pod name to exactly one of them. This is the defining behaviour of a
headless Service.
**Screenshot:**

### Screenshot 22

**Demonstrates:** Addressing one specific StatefulSet pod through the headless Service.
**Command:**
```bash
kubectl exec client-pod -- \
  curl -s -o /dev/null -w 'web-statefulset-0 -> HTTP %{http_code}\n' \
  http://web-statefulset-0.web-service-headless.default.svc.cluster.local
kubectl exec client-pod -- \
  curl -s http://web-statefulset-0.web-service-headless.default.svc.cluster.local | head -5
```
**Evidence:** `HTTP 200` and the nginx welcome page served from pod `-0` specifically, not from a
load-balanced pick among the three.
**Screenshot:**

---

## Cleanup

```bash
kubectl delete statefulset web-statefulset
kubectl delete deployment web-deployment
kubectl delete svc web-service-clusterip web-service-nodeport web-service-loadbalancer \
  github-api-service web-service-headless
kubectl delete pod client-pod
```

Stop `minikube tunnel` with Ctrl-C in the terminal running it.
