# OpenShift Route → Ingress Migration & SCC Annotations

## Overview

This update unifies external access across all Kubernetes distributions by replacing OpenShift-specific Route resources with standard Kubernetes Ingress. Additionally, explicit SecurityContextConstraints (SCC) annotations are added to deployments for improved OpenShift security context handling.

## Key Changes

### 1. Unified Ingress for All Platforms

**What Changed:**
- ❌ Removed: OpenShift Route resources
- ✅ Added: Unified Ingress support for all platforms including OpenShift
- ✅ Auto-configuration: `ingressClassName: nginx` for OpenShift

**Before (1.8.8 and earlier):**
```yaml
# Standard Kubernetes
k8s_tutum_engine_ingress_enabled: true
k8s_tutum_engine_ingress_class_name: nginx

# OpenShift - different resource
k8s_tutum_engine_route_enabled: true
k8s_tutum_engine_route_host: tutum.apps.example.com
k8s_tutum_engine_route_termination: edge
```

**After (Current):**
```yaml
# All platforms - unified configuration
k8s_distribution: openshift  # or standard, microk8s, k3s
k8s_tutum_engine_ingress_enabled: true
k8s_tutum_engine_ingress_host: tutum.apps.example.com
# ingressClassName: nginx is auto-set for OpenShift
```

### 2. Explicit SCC Annotations

**What Changed:**
- ✅ Added: `openshift.io/required-scc: restricted-v2` annotation to all deployments
- ✅ Conditional: Only added when `k8s_distribution=openshift`
- ✅ Components: PostgreSQL, Engine, Operator

**Deployment Annotation:**
```yaml
spec:
  template:
    metadata:
      annotations:
        openshift.io/required-scc: restricted-v2
```

**Benefits:**
- Explicit SCC assignment (no ambiguity)
- Support for arbitrary UID (required by OpenShift)
- Compliance with PodSecurity Standards (restricted:latest)

## Migration Guide for OpenShift Users

### Prerequisites

**1. Install nginx Ingress Controller**

OpenShift does NOT include nginx Ingress Controller by default. Install it before upgrading:

```bash
# Option A: Using Helm (recommended)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace nginx-ingress \
  --create-namespace \
  --set controller.service.type=LoadBalancer

# Option B: Using manifests
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Verify installation
oc get ingressclass
# Expected output should include 'nginx'

oc get pods -n nginx-ingress
# Should show nginx-ingress-controller pod(s) running
```

**2. Verify nginx Ingress Controller**

```bash
# Check IngressClass
oc get ingressclass nginx -o yaml

# Check controller pods
oc get pods -n nginx-ingress -l app.kubernetes.io/name=ingress-nginx

# Test with sample ingress
cat <<EOF | oc apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - host: test.apps.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-service
            port:
              number: 80
EOF

oc get ingress test-ingress
# Should show ADDRESS assigned

oc delete ingress test-ingress
```

### Migration Steps

**Step 1: Update Inventory**

```yaml
# inventory.yml or group_vars/all.yml

# Set distribution
k8s_distribution: openshift

# Use oc wrapper
k8s_kubectl_command: oc

# Enable Ingress (replaces route_enabled)
k8s_tutum_engine_ingress_enabled: true

# Configure hostname
k8s_tutum_engine_ingress_host: tutum.apps.example.com

# Remove old Route variables (if present)
# k8s_tutum_engine_route_enabled: true  # DELETE
# k8s_tutum_engine_route_host: ...      # DELETE
# k8s_tutum_engine_route_*: ...         # DELETE ALL
```

**Step 2: Deploy Updated Collection**

```bash
# Install/upgrade collection
ansible-galaxy collection install tutum_pro.cicd --force

# Deploy Tutum Platform
ansible-playbook -i inventory.yml \
  playbooks/install-tutum-k8s.yml
```

**Step 3: Verify Ingress Creation**

```bash
# Check Ingress resource
oc get ingress -n tutum-system

# Expected output:
# NAME           CLASS   HOSTS                         ADDRESS   PORTS   AGE
# tutum-engine   nginx   tutum.apps.example.com        ...       80      1m

# Check Ingress details
oc describe ingress tutum-engine -n tutum-system

# Test API endpoint
curl -k https://tutum.apps.example.com/api/health
```

**Step 4: Clean Up Old Route (Optional)**

Old Route resources are NOT automatically deleted. Remove manually if desired:

```bash
# List existing Routes
oc get route -n tutum-system

# Delete old Route
oc delete route tutum-engine -n tutum-system

# Verify deletion
oc get route -n tutum-system
```

### Troubleshooting

**Issue: Ingress Not Working**

```bash
# 1. Check nginx Ingress Controller
oc get pods -n nginx-ingress
oc logs -n nginx-ingress <nginx-pod-name>

# 2. Verify IngressClass
oc get ingressclass
# Should show 'nginx' as available

# 3. Check Ingress status
oc describe ingress tutum-engine -n tutum-system

# 4. Check Service
oc get svc tutum-engine -n tutum-system
```

**Issue: SCC Violations**

```bash
# Check pod events
oc describe pod -n tutum-system tutum-postgres-<pod-id>

# Verify SCC annotation
oc get deployment tutum-postgres -n tutum-system -o yaml | grep -A 2 annotations

# Should show:
#   annotations:
#     openshift.io/required-scc: restricted-v2

# Check assigned SCC
oc get pod -n tutum-system tutum-postgres-<pod-id> -o yaml | grep "openshift.io/scc"
```

**Issue: ImagePullBackOff**

```bash
# For PostgreSQL, use OpenShift-compatible image
k8s_tutum_postgres_image: quay.io/sclorg/postgresql-16-c9s
k8s_tutum_postgres_version: latest

# Or corporate registry
k8s_tutum_postgres_image: dll-quay-registry.apps.example.com/db/postgresql
k8s_tutum_postgres_version: "16"
```

## Technical Details

### Files Modified

**Runtime Roles:**
- `roles/k8s/tutum_engine/defaults/main.yml` - removed Route variables, updated ingress_class_name
- `roles/k8s/tutum_engine/tasks/install.yml` - removed Route creation, simplified Ingress
- `roles/k8s/tutum_engine/templates/deployment.yml.j2` - added SCC annotation
- `roles/k8s/tutum_postgres/templates/deployment.yml.j2` - added SCC annotation
- `roles/k8s/tutum_operator/templates/deployment.yml.j2` - added SCC annotation

**Manifest Generator:**
- `roles/k8s/tutum_manifests/defaults/main.yml` - removed Route section, updated ingress_class_name
- `roles/k8s/tutum_manifests/tasks/main.yml` - removed Route generation
- `roles/k8s/tutum_manifests/templates/engine/deployment.yml.j2` - added SCC annotation
- `roles/k8s/tutum_manifests/templates/postgres/deployment.yml.j2` - added SCC annotation
- `roles/k8s/tutum_manifests/templates/operator/deployment.yml.j2` - added SCC annotation

**Removed Files:**
- `roles/k8s/tutum_engine/templates/route.yml.j2`
- `roles/k8s/tutum_manifests/templates/engine/route.yml.j2`

### Code Statistics

```
12 files changed, 33 insertions(+), 136 deletions(-)
```

**Breakdown:**
- Route removal: -103 lines
- SCC annotations: +24 lines
- Documentation updates: +12 lines

### SCC restricted-v2 Specification

The `restricted-v2` SCC provides:

- ✅ `runAsUser: MustRunAsRange` - supports arbitrary UID
- ✅ `fsGroup: MustRunAs` - proper volume permissions
- ✅ `allowPrivilegeEscalation: false` - security hardening
- ✅ `capabilities: drop ALL` - minimal permissions
- ✅ `seccompProfile: RuntimeDefault` - PodSecurity compliance

Applied to:
- `system:serviceaccount:tutum-system:tutum-postgres`
- `system:serviceaccount:tutum-system:tutum-engine`
- `system:serviceaccount:tutum-system:tutum-operator`

## Benefits

### For All Platforms

1. **Unified Configuration** - single approach for external access
2. **Reduced Complexity** - 136 lines of code removed
3. **Better Maintenance** - one resource type to manage
4. **Ecosystem Alignment** - standard Kubernetes Ingress

### For OpenShift

1. **nginx Features** - rate limiting, auth, custom headers
2. **Flexibility** - easier to customize and extend
3. **Portability** - same config works on other platforms
4. **Explicit SCC** - no ambiguity in security context assignment

## Compatibility

**Backward Compatibility:**
- ✅ Standard Kubernetes - no changes required
- ✅ microk8s, k3s, rke2 - no changes required
- ⚠️ OpenShift - requires nginx Ingress Controller installation
- ⚠️ OpenShift - old Route variables ignored (not error)

**Breaking Changes:**
- OpenShift Route resources no longer created
- `k8s_tutum_engine_route_*` variables are ignored
- nginx Ingress Controller is now required for OpenShift

## Questions & Support

**Q: Why replace Route with Ingress?**
A: Standard Kubernetes Ingress provides unified configuration, better ecosystem support, and more flexibility for advanced features.

**Q: Can I still use OpenShift Route?**
A: No, Route support has been removed. Use nginx Ingress Controller instead.

**Q: What if I don't have nginx Ingress on OpenShift?**
A: Installation is required. See Prerequisites section for installation commands.

**Q: Will this work with other ingress controllers?**
A: Yes, but `ingressClassName` may need adjustment. nginx is recommended and auto-configured.

**Q: What about existing Route resources?**
A: They are not automatically removed. Clean up manually with `oc delete route tutum-engine -n tutum-system`.

**Q: Why add SCC annotations?**
A: Explicit SCC assignment ensures proper security context handling and prevents admission controller ambiguity.

## See Also

- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [OpenShift Security Context Constraints](https://docs.openshift.com/container-platform/latest/authentication/managing-security-context-constraints.html)
- [CHANGELOG.md](CHANGELOG.md) - Complete changelog
