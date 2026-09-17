# Broken Deployment / Troubleshooting

## Objective
Diagnose a Deployment that cannot pull its image. **This exercise is intentionally broken and
must not be fixed.**

## Files used
- `broken-deployment.yaml` - Deployment `yatri-backend`, image `yatri-backend:non-existent-tag-v999`,
  namespace **`session10-broken`**

> **Isolation:** this sits in its own `session10-broken` namespace for two reasons. It shares the
> name `yatri-backend` with the healthy Deployment in exercise 2, and a third live `yatri-backend`
> (session 12's ingress demo) exists in `default`. Separate namespaces keep all three from
> overwriting each other, and keep the broken one from polluting `kubectl get all -n session10`.

## Commands executed
```bash
kubectl apply -f troubleshooting/broken-deployment.yaml
kubectl get all -n session10-broken
kubectl describe pod <broken-pod> -n session10-broken
```

## Expected vs actual verified result

Expected: pods stuck in `ErrImagePull` / `ImagePullBackOff`, Deployment never becomes available.

Actual:
```
pod/yatri-backend-69987f6996-h6rzw   0/1   ImagePullBackOff   0   28s
pod/yatri-backend-69987f6996-vmfpm   0/1   ImagePullBackOff   0   28s
deployment.apps/yatri-backend        0/2   2                  0   28s
```

Events section confirms the root cause:
```
Warning  Failed   kubelet  Failed to pull image "yatri-backend:non-existent-tag-v999":
  failed to resolve reference "docker.io/library/yatri-backend:non-existent-tag-v999":
  pull access denied, repository does not exist or may require authorization:
  server message: insufficient_scope: authorization failed
Warning  Failed   kubelet  Error: ErrImagePull
Normal   BackOff  kubelet  Back-off pulling image "yatri-backend:non-existent-tag-v999"
Warning  Failed   kubelet  Error: ImagePullBackOff
```

**Diagnosis:** the image reference resolves to `docker.io/library/yatri-backend`, which does not
exist. The registry returns an authorization failure rather than a 404 because Docker Hub cannot
distinguish "no such repo" from "private repo" for anonymous clients - a common source of
confusion when debugging image pulls.

## Final verification
```bash
kubectl get pods -n session10-broken
kubectl describe pod $(kubectl get pods -n session10-broken -o jsonpath='{.items[0].metadata.name}') -n session10-broken | sed -n '/^Events:/,$p'
```
