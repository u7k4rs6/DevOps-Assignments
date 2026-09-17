# Deployment

## Objective
Create Deployment `yatri-backend` with 3 replicas, verify the Deployment and its ReplicaSet,
then scale to 5 and verify.

## Files used
- `deployment-v1.yaml` - Deployment `yatri-backend`, image `nginx:1.27-alpine`, namespace `session10`

> **Namespace note:** this lives in `session10`, not `default`, because a *different* live
> `yatri-backend` Deployment (session 12's ingress demo, `python:3.11-alpine3.19`) already occupies
> `default`. Applying here would have destroyed it.

## Commands executed
```bash
kubectl apply -f deployment/deployment-v1.yaml
kubectl rollout status deploy/yatri-backend -n session10
kubectl get deploy,rs,pods -n session10 -l app=yatri-backend
kubectl scale deploy/yatri-backend -n session10 --replicas=5
kubectl get deployment,rs,pods -n session10 -l app=yatri-backend
```

## Expected vs actual verified result
- Expected 3/3 ready -> **actual `deployment.apps/yatri-backend 3/3 3 3`**, ReplicaSet
  `yatri-backend-77f6b975d 3 3 3`, three pods `1/1 Running`.
- Expected 5/5 after scaling -> **actual `5/5 5 5`**, same ReplicaSet scaled to `5 5 5`,
  five pods `1/1 Running`. No pod left in `ContainerCreating`.

## Final verification
```bash
kubectl get deployment yatri-backend -n session10
kubectl get rs -n session10 -l app=yatri-backend
kubectl get pods -n session10 -l app=yatri-backend -o wide
```
