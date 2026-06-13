---
title: Kubernetes
description: Semantic and architectural guidance for Kubernetes manifests.
paths:
  - "**/k8s/**/*.yaml"
  - "**/manifests/**/*.yaml"
---

# Kubernetes — semantic guidance

> Schema validity and field correctness are owned by `kubeconform` (run in hooks).
> This file is architecture only.

- **Declarative and idempotent.** A manifest describes desired state; applying it
  twice changes nothing. Never design imperative, run-once steps into manifests.
- **Set resource requests and limits** on every container — capacity planning and
  fair scheduling depend on it. Flag any workload missing them.
- **Health probes are mandatory** for long-running services: readiness gates
  traffic, liveness restarts. Don't conflate the two.
- **Least privilege by default:** non-root user, read-only root filesystem where
  feasible, drop capabilities, no host namespaces unless justified.
- **Configuration via ConfigMap/Secret**, injected as env or mounts — never baked
  into images. Treat Secret contents as opaque; never echo them.
- **Namespaces are boundaries.** Group by team/concern; don't deploy to `default`.
- Prefer Deployments/StatefulSets over bare Pods so the control loop can heal them.
