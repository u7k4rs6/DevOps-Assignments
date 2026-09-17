# Pod Lifecycle

## Objective
Demonstrate six pod states: Pending, Failed/Error, CrashLoopBackOff, Succeeded/Completed,
ImagePullBackOff/ErrImagePull, and Readiness.

## Files used
| File | State | Mechanism |
|---|---|---|
| `01-pending.yaml` | Pending | requests 500Gi memory / 200 CPU - unschedulable |
| `02-failed.yaml` | Failed | `exit 1` with `restartPolicy: Never` |
| `03-crashloop.yaml` | CrashLoopBackOff | `exit 1` with `restartPolicy: Always` |
| `04-succeeded.yaml` | Succeeded | `exit 0` with `restartPolicy: Never` |
| `05-imagepull.yaml` | ImagePullBackOff | tag `busybox:this-tag-does-not-exist-v999` |
| `06-readiness.yaml` | Readiness | readiness probe fails until `/tmp/ready` appears at 30s |

All in namespace `session10`.

## Commands executed
```bash
kubectl apply -f pod-lifecycle/
kubectl get pods -n session10 -l app=lifecycle -o wide
kubectl logs lifecycle-succeeded -n session10
kubectl logs lifecycle-failed -n session10
kubectl describe pod lifecycle-pending -n session10
```

## Expected vs actual verified result

| Pod | Expected | Actual (verified) |
|---|---|---|
| `lifecycle-pending` | Pending | `Pending`, event `0/1 nodes are available: 1 Insufficient cpu, 1 Insufficient memory` |
| `lifecycle-failed` | Failed | `Error`, `phase=Failed exitCode=1`, logs `Task started` / `Task failed` |
| `lifecycle-crashloop` | CrashLoopBackOff | reached `CrashLoopBackOff`, restart count rising (9 observed) |
| `lifecycle-succeeded` | Completed | `Completed`, logs `Task started` / `Task completed successfully` |
| `lifecycle-imagepull` | ImagePullBackOff | `ErrImagePull` then `ImagePullBackOff` |
| `lifecycle-readiness` | 0/1 then 1/1 | `Running` `0/1` for ~30s, then `1/1 ready=true` |

## Caveats
- **`lifecycle-crashloop` alternates** between `Error` (container just died) and
  `CrashLoopBackOff` (kubelet waiting out the backoff). Both are correct; the restart count is the
  stable proof. Run `kubectl get pods` a few times to catch `CrashLoopBackOff` for a screenshot.
- **`lifecycle-readiness` is already `1/1`.** The 0/1 -> 1/1 transition only happens in the first
  30 seconds. To screenshot it, recreate and watch:
  ```bash
  kubectl delete pod lifecycle-readiness -n session10
  kubectl apply -f pod-lifecycle/06-readiness.yaml
  kubectl get pods -n session10 -l state=readiness -w
  ```
- The four broken pods are **intentional** and must not be fixed.

## Final verification
```bash
kubectl get pods -n session10 -l app=lifecycle
```
