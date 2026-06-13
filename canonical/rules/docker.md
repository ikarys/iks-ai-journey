---
title: Docker
description: Semantic and architectural guidance for Dockerfiles and Compose.
paths:
  - "**/Dockerfile*"
  - "**/compose*.yml"
  - "**/compose*.yaml"
  - "**/docker-compose*.yml"
---

# Docker — semantic guidance

> Lint rules and best-practice syntax are owned by `hadolint` (run in hooks).
> This file is architecture only.

- **Multi-stage builds:** build in one stage, ship only the runtime artifact.
  The final image carries no compilers, no build deps, no source.
- **Small, single-purpose images.** One concern per image; one process per
  container. Compose wires multiple containers, it doesn't justify a fat image.
- **Immutable and reproducible.** Pin base images by digest or explicit version,
  not `latest`. Build args in, no environment-specific values baked in.
- **Run as non-root.** Create and `USER` a dedicated unprivileged account.
- **Layer for cache, not for size alone.** Copy dependency manifests and install
  before copying source so dependency layers stay cached across code changes.
- **No secrets in layers** — not in `ENV`, not in `ARG`, not copied in. Use build
  secrets or runtime injection. Anything written to a layer is permanent.
- Compose files declare dependencies and health, not deployment topology — keep
  orchestration concerns in Kubernetes.
