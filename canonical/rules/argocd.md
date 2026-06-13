---
title: Argo CD
description: Semantic and architectural guidance for Argo CD / GitOps.
paths:
  - "**/argocd/**"
  - "**/*application*.yaml"
---

# Argo CD — semantic guidance

> Manifest schema is owned by `kubeconform` (run in hooks). This file is the
> GitOps architecture only.

- **Git is the single source of truth.** The cluster converges to the repo, never
  the reverse. Never design a change that depends on manual `kubectl` mutation.
- **Applications declare desired state, not actions.** An `Application` points at a
  source (path/chart) and a destination; it does not run procedural steps.
- **Sync should be safe to repeat.** Favour automated sync with self-heal where the
  blast radius is understood; prune deliberately and call it out.
- **Separate config from app.** Keep environment overlays (Kustomize/Helm values)
  distinct from base manifests so promotion is a values change, not a fork.
- **App-of-apps for composition.** Model dependencies explicitly via sync waves
  rather than implicit ordering or timing.
- **No secrets in Git in clear.** Reference a sealed/external secret mechanism;
  the manifest holds a pointer, never the value.
