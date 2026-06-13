# Standard — <topic>

> **Rule (one line):** <the normative statement, testable and unambiguous>

| Field        | Value                       |
|--------------|-----------------------------|
| Status       | Draft / Active / Deprecated |
| Version      | 1.0                         |
| Owner        | <team / name>               |
| Last updated | YYYY-MM-DD                  |

## 1. Purpose
Why this standard exists and the problem it prevents.

## 2. Scope
Where it applies (which repos, services, file types) and where it does not.

## 3. Requirements
Use RFC 2119 keywords.
- **MUST** <hard requirement, enforced>
- **MUST NOT** <prohibition>
- **SHOULD** <strong recommendation>
- **MAY** <optional, allowed>

## 4. Examples
### Conformant ✅
```
# e.g. resource named service-a-ingestion-queue
```
### Non-conformant ❌
```
# e.g. resource named Queue1
```

## 5. Enforcement
How violations are caught: name the linter / CI gate (e.g. `tflint` rule,
`ruff` code, a CI job), or state "review-only". Do not restate what the linter
already enforces — link to its config.

## 6. Exceptions
The documented escape hatch and who approves it.

## 7. References
Related standards, ADRs, external specs.
