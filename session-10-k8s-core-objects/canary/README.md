# Canary Deployment

## Objective
Run two versions behind one Service and split traffic by replica count, then shift the
proportion by scaling.

## Files used
- `app-stable.yaml` - ConfigMap `stable-content` + Deployment `app-stable` (`app=app, version=stable`), serves `STABLE v1`
- `app-canary.yaml` - ConfigMap `canary-content` + Deployment `app-canary` (`app=app, version=canary`), serves `CANARY v2`
- `app-canary-service.yaml` - Service `app-canary-service`, NodePort **30030**, selector `app=app` only

The Service selects on `app=app` alone and deliberately **ignores** `version`, so both
Deployments' pods become endpoints. Traffic share therefore equals replica share.

## Commands executed
```bash
kubectl apply -f canary/
kubectl get pods -n session10 -l app=app -L version
for i in $(seq 1 20); do curl -s http://$(minikube ip):30030 | grep -o "STABLE v1\|CANARY v2"; done | sort | uniq -c
kubectl scale deployment app-canary -n session10 --replicas=3
kubectl scale deployment app-stable -n session10 --replicas=7
for i in $(seq 1 20); do curl -s http://$(minikube ip):30030 | grep -o "STABLE v1\|CANARY v2"; done | sort | uniq -c
```

## Expected vs actual verified result

| Replica ratio | Expected share | Actual over 20 requests |
|---|---|---|
| 4 stable : 1 canary | 80% / 20% | **15 STABLE v1, 5 CANARY v2** |
| 7 stable : 3 canary | 70% / 30% | **14 STABLE v1, 6 CANARY v2** |

Both versions demonstrably answer through the same Service, and the proportion tracks the
replica counts.

## Caveat
The very first sampling run returned `17 STABLE` and no canary, because the canary pod was 1
second old and had not yet been added to the Service EndpointSlice. Wait for all pods to be
`Ready` before sampling, or the split will look wrong. Verify with:
```bash
kubectl get endpointslices -n session10 -l kubernetes.io/service-name=app-canary-service
```

## Final verification
```bash
kubectl get deploy -n session10 -l app=app
for i in $(seq 1 20); do curl -s http://$(minikube ip):30030 | grep -o "STABLE v1\|CANARY v2"; done | sort | uniq -c
```
