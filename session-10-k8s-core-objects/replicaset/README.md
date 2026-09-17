# ReplicaSet

## Objective
Create ReplicaSet `yatri-backend-rs` with 3 replicas, scale to 5, scale back to 3, delete, verify gone.

## Files used
- `backend-rs.yaml` - ReplicaSet `yatri-backend-rs`, `nginx:1.27-alpine`, namespace `session10`.
  Selector `app: yatri-backend-rs` matches the pod template labels exactly.

## Commands executed
```bash
kubectl apply -f replicaset/backend-rs.yaml
kubectl get rs yatri-backend-rs -n session10
kubectl get pods -n session10 -l app=yatri-backend-rs
kubectl scale rs/yatri-backend-rs -n session10 --replicas=5
kubectl scale rs/yatri-backend-rs -n session10 --replicas=3
kubectl delete rs yatri-backend-rs -n session10
kubectl get rs -n session10 -l app=yatri-backend-rs
```

## Expected vs actual verified result
| Step | Expected | Actual (verified) |
|---|---|---|
| Create | 3 ready | `yatri-backend-rs 3 3 3`, 3 pods Running |
| Scale up | 5 ready | `yatri-backend-rs 5 5 5`, 5 pods Running |
| Scale down | 3 ready | `yatri-backend-rs 3 3 3`, 3 pods Running |
| Delete | gone | `No resources found in session10 namespace.` for both rs and pods |

Outputs captured in `Outputs/01-created-3.txt` .. `Outputs/04-deleted.txt`.

## Caveat
This ReplicaSet was **deleted** as the final step of the exercise, so it is no longer running.
Re-apply `backend-rs.yaml` before screenshotting.

## Final verification
```bash
kubectl get rs -n session10
```
