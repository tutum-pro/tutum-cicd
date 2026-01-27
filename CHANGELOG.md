# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **Replaced OpenShift Route with unified Ingress** - standardized external access across all Kubernetes distributions
  - Removed OpenShift Route resources in favor of standard Kubernetes Ingress
  - Automatic `ingressClassName: nginx` configuration for OpenShift deployments
  - Simplified configuration - single flag `k8s_tutum_engine_ingress_enabled` works for all platforms
  - Reduced codebase by 136 lines through Route removal

- **Added explicit SCC annotations to deployments** - improved OpenShift security context handling
  - PostgreSQL, Engine, and Operator deployments now include `openshift.io/required-scc: restricted-v2`
  - Annotation added conditionally only for OpenShift distributions
  - Ensures proper SecurityContextConstraints assignment with arbitrary UID support

- **`roles/k8s/tutum_engine/defaults/main.yml`**
  - Removed all `k8s_tutum_engine_route_*` variables (9 variables)
  - Updated `k8s_tutum_engine_ingress_class_name` to auto-select nginx for OpenShift
  - Added documentation comments for ingress class selection

- **`roles/k8s/tutum_engine/tasks/install.yml`**
  - Removed "Create OpenShift Route" task block (22 lines)
  - Simplified "Create Ingress" condition - removed OpenShift exclusion
  - Removed `/tmp/tutum-engine-route.yml` from cleanup list

- **`roles/k8s/tutum_engine/templates/deployment.yml.j2`**
  - Added conditional SCC annotation for OpenShift

- **`roles/k8s/tutum_engine/templates/route.yml.j2`**
  - REMOVED - OpenShift Route template no longer needed

- **`roles/k8s/tutum_manifests/defaults/main.yml`**
  - Removed "OpenShift Route Configuration" section (9 variables)
  - Updated `k8s_tutum_engine_ingress_class_name` to auto-select nginx for OpenShift
  - Added documentation comments for ingress class selection

- **`roles/k8s/tutum_manifests/tasks/main.yml`**
  - Removed "Generate Route manifest (OpenShift)" task (12 lines)
  - Updated section comment from "Generate Ingress/Route" to "Generate Ingress"

- **`roles/k8s/tutum_manifests/templates/engine/deployment.yml.j2`**
  - Added conditional SCC annotation for OpenShift

- **`roles/k8s/tutum_manifests/templates/engine/route.yml.j2`**
  - REMOVED - Route template no longer generated in manifests

- **`roles/k8s/tutum_manifests/templates/operator/deployment.yml.j2`**
  - Added conditional SCC annotation for OpenShift

- **`roles/k8s/tutum_manifests/templates/postgres/deployment.yml.j2`**
  - Added conditional SCC annotation for OpenShift

- **`roles/k8s/tutum_operator/templates/deployment.yml.j2`**
  - Added conditional SCC annotation for OpenShift

- **`roles/k8s/tutum_postgres/templates/deployment.yml.j2`**
  - Added conditional SCC annotation for OpenShift

### Removed

- OpenShift Route support in favor of unified Ingress approach
- Route-specific configuration variables from defaults
- Route template files from both runtime and manifest generator roles

### Migration Notes

**For OpenShift Users:**

This change replaces OpenShift Route with standard Kubernetes Ingress using nginx Ingress Controller.

**Prerequisites:**
- nginx Ingress Controller must be installed on OpenShift cluster before upgrade
- Verify with: `oc get ingressclass`

**What Changed:**
- `k8s_tutum_engine_route_enabled` flag is no longer recognized
- Use `k8s_tutum_engine_ingress_enabled: true` instead
- `ingressClassName: nginx` is automatically set for OpenShift

**Migration Steps:**
1. Install nginx Ingress Controller on OpenShift (if not already present)
2. Update inventory to use `k8s_tutum_engine_ingress_enabled: true`
3. Remove any `k8s_tutum_engine_route_*` variables from inventory
4. Deploy updated collection
5. Optional: Clean up old Route manually with `oc delete route tutum-engine -n tutum-system`

**Example Configuration:**
```yaml
k8s_distribution: openshift
k8s_kubectl_command: oc
k8s_tutum_engine_ingress_enabled: true
k8s_tutum_engine_ingress_host: tutum.apps.example.com
# ingressClassName: nginx is auto-configured
```

**Benefits:**
- Unified configuration across all Kubernetes distributions
- Better alignment with Kubernetes ecosystem
- Support for advanced nginx features (rate limiting, auth, etc.)
- Easier migration between platforms

**SCC Annotations:**
The `openshift.io/required-scc: restricted-v2` annotation is now automatically added to deployments when `k8s_distribution=openshift`. This ensures:
- Proper security context assignment
- Support for arbitrary UID (required by OpenShift)
- Compliance with PodSecurity Standards

### Notes

- All changes maintain backward compatibility for non-OpenShift platforms
- Standard Kubernetes deployments are unaffected
- OpenShift deployments require nginx Ingress Controller
- Route resources are NOT automatically cleaned up - manual removal recommended

---

## Version Numbering

- **Major (X.0.0)**: Breaking changes, major features
- **Minor (1.X.0)**: New features, backward compatible
- **Patch (1.8.X)**: Bug fixes, improvements, backward compatible
