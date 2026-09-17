# Session 10 - Screenshot Commands

Exact commands to paste into your terminal to reproduce every piece of evidence.
All healthy exercises live in namespace **`session10`**; the intentionally broken deployment lives
in **`session10-broken`**.

Set this once per terminal so the curl commands are short:
```bash
export IP=$(minikube ip)
```

---

## 0. Overview (one screenshot showing everything)

```bash
kubectl get all -n session10
```

---

## 1. Pod Lifecycle

```bash
kubectl get pods -n session10 -l app=lifecycle -o wide
```

Succeeded / Completed:
```bash
kubectl logs lifecycle-succeeded -n session10
```
> prints `Task started` / `Task completed successfully`

Failed:
```bash
kubectl logs lifecycle-failed -n session10
kubectl get pod lifecycle-failed -n session10 -o jsonpath='{.status.phase} exit={.status.containerStatuses[0].state.terminated.exitCode}{"\n"}'
```

CrashLoopBackOff (run twice - it alternates between `Error` and `CrashLoopBackOff`):
```bash
kubectl get pod lifecycle-crashloop -n session10
kubectl describe pod lifecycle-crashloop -n session10 | grep -A3 "Last State"
```

Pending:
```bash
kubectl describe pod lifecycle-pending -n session10 | sed -n '/^Events:/,$p'
```

ImagePullBackOff:
```bash
kubectl describe pod lifecycle-imagepull -n session10 | sed -n '/^Events:/,$p'
```

Readiness - **must be recreated to see 0/1 -> 1/1** (takes 30s):
```bash
kubectl delete pod lifecycle-readiness -n session10
kubectl apply -f pod-lifecycle/06-readiness.yaml
kubectl get pods -n session10 -l state=readiness -w
```
> shows `0/1 Running` for ~30s, then `1/1 Running`. Ctrl-C to stop.

---

## 2. Deployment

```bash
kubectl get deployment yatri-backend -n session10
kubectl get rs -n session10 -l app=yatri-backend
kubectl get pods -n session10 -l app=yatri-backend -o wide
```

Scaling demo:
```bash
kubectl scale deploy/yatri-backend -n session10 --replicas=5
kubectl get pods -n session10 -l app=yatri-backend
kubectl get deployment yatri-backend -n session10
```

---

## 3. ReplicaSet

```bash
kubectl get rs yatri-backend-rs -n session10
kubectl get pods -n session10 -l app=yatri-backend-rs
kubectl scale rs/yatri-backend-rs -n session10 --replicas=5
kubectl get pods -n session10 -l app=yatri-backend-rs
kubectl scale rs/yatri-backend-rs -n session10 --replicas=3
kubectl get pods -n session10 -l app=yatri-backend-rs
kubectl delete rs yatri-backend-rs -n session10
kubectl get rs -n session10
```
> Re-create afterwards with `kubectl apply -f replicaset/backend-rs.yaml`

---

## 4. Blue-Green

Before (currently live - blue):
```bash
kubectl get pods -n session10 -l app=myapp -L slot
kubectl describe svc myapp-service -n session10 | grep -i selector
curl http://$IP:30020
```

Switch to green:
```bash
kubectl patch svc myapp-service -n session10 -p '{"spec":{"selector":{"app":"myapp","slot":"green"}}}'
kubectl describe svc myapp-service -n session10 | grep -i selector
curl http://$IP:30020
```

Reset to blue:
```bash
kubectl apply -f blue-green/myapp-service.yaml
```

---

## 5. Canary

```bash
kubectl get pods -n session10 -l app=app -L version
for i in $(seq 1 20); do curl -s http://$IP:30030 | grep -o "STABLE v1\|CANARY v2"; done
```

Counted summary (nicer for a screenshot):
```bash
for i in $(seq 1 20); do curl -s http://$IP:30030 | grep -o "STABLE v1\|CANARY v2"; done | sort | uniq -c
```

Shift the proportion:
```bash
kubectl scale deployment app-canary -n session10 --replicas=3
kubectl scale deployment app-stable -n session10 --replicas=7
kubectl get pods -n session10 -l app=app -L version
for i in $(seq 1 20); do curl -s http://$IP:30030 | grep -o "STABLE v1\|CANARY v2"; done | sort | uniq -c
```

---

## 6. Recreate

```bash
kubectl get deployment app-recreate -n session10 -o wide
kubectl get pods -n session10 -l app=app-recreate -L version
```

Watch the Recreate transition (run the watch in one pane, the set-image in another):
```bash
# pane 1
kubectl get pods -n session10 -l app=app-recreate -w

# pane 2
kubectl set image deploy/app-recreate -n session10 web=nginx:1.27-alpine
```
> All four pods go `Terminating` and the count reaches **zero** before new pods appear.

Single-pane alternative that prints the running count once a second:
```bash
kubectl set image deploy/app-recreate -n session10 web=nginx:1.27-alpine & \
for i in $(seq 1 30); do echo "$(date +%H:%M:%S) running=$(kubectl get pods -n session10 -l app=app-recreate --no-headers | grep -c ' Running ')"; sleep 1; done
```

---

## 7. DaemonSet

```bash
kubectl get ds -n session10
kubectl get pods -n session10 -l app=node-logging-agent -o wide
kubectl logs -n session10 -l app=node-logging-agent --tail=5
```

---

## 8. Broken Deployment (troubleshooting)

```bash
kubectl get all -n session10-broken
```

```bash
kubectl describe pod $(kubectl get pods -n session10-broken -o jsonpath='{.items[0].metadata.name}') -n session10-broken | sed -n '/^Events:/,$p'
```
> Events show `Failed to pull image ... pull access denied, repository does not exist`,
> `Error: ErrImagePull`, then `Error: ImagePullBackOff`.

---

## Teardown (only when you are finished)

```bash
kubectl delete namespace session10 session10-broken
```
> This removes **only** Session 10 resources. Sessions 11 and 12 live in `default` and are untouched.
