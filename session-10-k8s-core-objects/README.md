# Session 10 - Kubernetes Core Objects

All eight exercises were **executed against the live minikube cluster**, not just written as YAML.
Every result in the per-exercise READMEs was captured from a real command run.

**Cluster:** minikube, node `192.168.49.2`, Kubernetes `v1.37.0`, runtime `containerd://2.3.4`.

## Namespaces

| Namespace | Contents |
|---|---|
| `session10` | all healthy exercises + the pod-lifecycle demos |
| `session10-broken` | exercise 8 only - the intentionally broken Deployment |

> **Why namespaces:** a live `yatri-backend` Deployment already exists in `default` - it is
> session 12's ingress demo (`python:3.11-alpine3.19`, behind `yatri-backend-service`). Exercise 2
> and exercise 8 also both require the name `yatri-backend`. Three objects, one name. Separate
> namespaces let all three coexist, keep the broken one out of `kubectl get all -n session10`, and
> leave sessions 11 and 12 completely untouched.

## Exercises

| # | Directory | Object | Status |
|---|---|---|---|
| 1 | [pod-lifecycle/](pod-lifecycle/) | 6 Pods | 6 states verified |
| 2 | [deployment/](deployment/) | Deployment `yatri-backend` | 3 -> 5 replicas, healthy |
| 3 | [replicaset/](replicaset/) | ReplicaSet `yatri-backend-rs` | 3 -> 5 -> 3 -> deleted -> re-created |
| 4 | [blue-green/](blue-green/) | `app-blue`, `app-green`, `myapp-service` | switch verified both ways |
| 5 | [canary/](canary/) | `app-stable`, `app-canary`, `app-canary-service` | traffic split verified |
| 6 | [recreate/](recreate/) | Deployment `app-recreate` | `running=4 -> 0 -> 4` captured |
| 7 | [daemonset/](daemonset/) | DaemonSet `node-logging-agent` | 1/1 on the minikube node |
| 8 | [troubleshooting/](troubleshooting/) | broken `yatri-backend` | ImagePullBackOff (intentional) |

## Ports

| NodePort | Service | Exercise |
|---|---|---|
| 30020 | `myapp-service` | Blue-Green |
| 30030 | `app-canary-service` | Canary |
| 30040 | `app-recreate-service` | Recreate |

Chosen to avoid `30080` / `31683` / `32311` / `32404`, which sessions 11 and 12 already use.

## Reproducing

```bash
kubectl apply -f 00-namespaces.yaml
kubectl apply -f pod-lifecycle/ -f deployment/ -f replicaset/ -f blue-green/ \
               -f canary/ -f recreate/ -f daemonset/ -f troubleshooting/
```

Screenshot commands: **[SCREENSHOT_COMMANDS.md](SCREENSHOT_COMMANDS.md)**

## Intentional failures - do not fix

`lifecycle-pending`, `lifecycle-failed`, `lifecycle-crashloop`, `lifecycle-imagepull`
(namespace `session10`) and the `yatri-backend` Deployment in `session10-broken`. These are the
exercises.

## Teardown

```bash
kubectl delete namespace session10 session10-broken
```
