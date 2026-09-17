# DaemonSet

## Objective
Run exactly one logging-agent pod per node.

## Files used
- `node-logging-agent.yaml` - DaemonSet `node-logging-agent`, `busybox:1.36`

The container runs `while true; do echo ...; sleep 30; done` so it stays `Running`. A bare
`busybox` with no command exits immediately and would CrashLoopBackOff. The node name is injected
via the downward API (`spec.nodeName`) so the log line proves which node it landed on.

## Commands executed
```bash
kubectl apply -f daemonset/node-logging-agent.yaml
kubectl get ds -n session10
kubectl get pods -n session10 -l app=node-logging-agent -o wide
kubectl logs -n session10 -l app=node-logging-agent --tail=3
```

## Expected vs actual verified result
Expected 1 desired / 1 ready on single-node minikube.

Actual: `node-logging-agent 1 1 1 1 1 <none>` and pod `node-logging-agent-bxfm4 1/1 Running`
on node `minikube` (IP `10.244.0.62`). Logs show
`[Thu Sep 17 20:43:09 UTC 2026] log agent alive on node minikube`, confirming the container is
alive and the downward API resolved the node name.

## Final verification
```bash
kubectl get ds -n session10
kubectl get pods -n session10 -l app=node-logging-agent -o wide
```
