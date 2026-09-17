# Blue-Green Deployment

## Objective
Run two full environments side by side and cut traffic over instantly by editing a single
Service selector.

## Files used
- `app-blue.yaml` - ConfigMap `blue-content` + Deployment `app-blue` (labels `app=myapp, slot=blue`)
- `app-green.yaml` - ConfigMap `green-content` + Deployment `app-green` (labels `app=myapp, slot=green`)
- `myapp-service.yaml` - Service `myapp-service`, NodePort **30020**, selector `app=myapp, slot=blue`
- `myapp-service-green.yaml` - same Service with selector `slot=green` (the promotion)

The identifying page is supplied by a ConfigMap mounted at `/usr/share/nginx/html`, so no custom
image build is needed.

## Commands executed
```bash
kubectl apply -f blue-green/
kubectl describe svc myapp-service -n session10 | grep -i selector
curl http://$(minikube ip):30020
kubectl patch svc myapp-service -n session10 -p '{"spec":{"selector":{"app":"myapp","slot":"green"}}}'
kubectl describe svc myapp-service -n session10 | grep -i selector
curl http://$(minikube ip):30020
```

## Expected vs actual verified result

**Before the switch** - selector `app=myapp,slot=blue`, curl returned:
```
BLUE ENVIRONMENT
Version: v1
Slot: BLUE (LIVE)
```

**After the switch** - selector `app=myapp,slot=green`, curl returned:
```
GREEN ENVIRONMENT
Version: v2
Slot: GREEN (STANDBY -> PROMOTED)
```

Endpoints were confirmed to move to the green pod IPs (`10.244.0.42`, `10.244.0.43`).

## Current state
The Service is currently pointing at **green** (promoted). To reset for a fresh demo:
```bash
kubectl apply -f blue-green/myapp-service.yaml
```

## Final verification
```bash
kubectl describe svc myapp-service -n session10 | grep -i selector
curl http://$(minikube ip):30020
```
