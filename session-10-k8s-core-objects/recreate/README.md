# Recreate Deployment Strategy

## Objective
Show that `strategy.type: Recreate` terminates **all** old pods before creating **any** new pod -
the opposite of the default RollingUpdate, and it causes real downtime.

## Files used
- `app-recreate.yaml` - Deployment `app-recreate`, 4 replicas, `strategy.type: Recreate`
- `app-recreate-service.yaml` - Service `app-recreate-service`, NodePort **30040**

## Commands executed
```bash
kubectl apply -f recreate/
kubectl rollout status deploy/app-recreate -n session10
kubectl set image deploy/app-recreate -n session10 web=nginx:1.29-alpine
kubectl get pods -n session10 -l app=app-recreate -w
```

## Expected vs actual verified result

Expected: running replica count drops to **zero** before new pods appear.

Actual, sampled once per second across the rollout (`Outputs/02-recreate-transition.txt`):

```
02:11:34 running=4 terminating=0 total=4     <- steady state, v1
02:11:36 running=0 terminating=2 total=7     <- ALL old pods terminating at once
02:11:37 running=0 terminating=0 total=4     <- ZERO pods serving (the downtime window)
02:11:46 running=1 terminating=0 total=4     <- new v2 pods starting
02:11:51 running=4 terminating=0 total=4     <- steady state, v2
```

The `running=0` line is the whole point of the exercise: with RollingUpdate it would never
reach zero.

Final state verified healthy: `app-recreate 4/4 4 4`, image `nginx:1.29-alpine`, all pods
`1/1 Running` with label `version=v2`, rollout history at revision 2.

## Final verification
```bash
kubectl get deployment app-recreate -n session10 -o wide
kubectl get pods -n session10 -l app=app-recreate -L version
```
