# Technical Architecture Document — <System Name>

| Field        | Value                          |
|--------------|--------------------------------|
| Status       | Draft / Reviewed / Approved    |
| Version      | 0.1                            |
| Authors      | <name>                         |
| Last updated | YYYY-MM-DD                     |

## 1. Overview
One paragraph: what this system does and why it exists.

## 2. Context & Scope
- **In scope:** …
- **Out of scope:** …
- **Stakeholders:** …
- **System context diagram:** (Mermaid / description — show external actors and
  neighbouring systems, e.g. `service-a` calls `gateway-x`).

## 3. Architecture Drivers
- **Functional requirements:** the capabilities that shape structure.
- **Quality attributes:** scalability, availability, security, latency,
  maintainability — ranked, with target figures where known.
- **Constraints:** budget, compliance, existing platforms, team skills.

## 4. Architecture
### 4.1 High-level structure
Containers/services and how they collaborate (diagram + narrative).

### 4.2 Key components
Per significant component: responsibility, interfaces, data owned.

### 4.3 Data
Stores, ownership, flow, retention. Note any sensitive data class (handled, never
shown in clear).

### 4.4 Cross-cutting concerns
Observability, security, configuration, failure handling.

## 5. Key Decisions & Trade-offs
Summarise the decisive choices. Link each to its ADR.
| Decision | Chosen | Rejected | Rationale | ADR |
|----------|--------|----------|-----------|-----|

## 6. Risks & Open Questions
- Risk → mitigation.
- Open question → owner.

## 7. References
ADRs, standards, external docs.
