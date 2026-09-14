---
name: production-triage
description: Triage production pages, alerts, and vague service symptoms to decide whether they are transient, need monitoring, or require action. Use when James says "is this a nothing-burger", "triage this page", "check the latest alert", "investigate this production issue", or asks whether an operational symptom needs action.
---

# Production Triage

Reach a fast, evidence-based verdict without turning every alert into a broad investigation.

## Safety

- Perform read-only investigation by default.
- Never deploy, roll back, restart workloads, scale services, change production configuration, acknowledge or resolve incidents, or post to Slack without James's explicit approval in the current conversation.
- Do not expose secrets or unnecessary production data in the response.

## Workflow

### 1. Establish the alert

Find the relevant alert in the source James names, such as Slack or PagerDuty. If he only names a channel or service, use the latest clearly relevant alert rather than asking for details already available there.

Record:

- Service, environment, region, and affected dependency or workload
- Signal, threshold, severity, and current state
- Fired and resolved times in UTC
- Incident, dashboard, and alert links when available
- Repeats, thread replies, and any existing teammate assessment

Separate confirmed facts from assumptions. A resolved notification proves recovery of the signal, not the cause.

### 2. Check current health and correlation

Start with the cheapest checks that can change the verdict:

1. Confirm whether the alert is active, resolved, or repeating.
2. Check deployment revision, revision age, rollout status, desired and ready replicas, and current availability.
3. Check pod or task restarts, failed health checks, recent events, and autoscaling state.
4. Check the directly affected dependency when available, such as a database proxy, queue consumer, cache, or load balancer.
5. Compare every event against the alert window. Do not treat nearby activity as causal without evidence.

If a workload is still starting or scaling, perform one short follow-up check before deciding. Do not begin an open-ended monitoring loop unless James asks.

For Argo-managed Kubernetes workloads, prefer Argo application state when accessible. If Argo is unavailable, inspect the tracked Kubernetes resources and say that this verifies workload state, not Argo sync status. Start with the service namespace because production RBAC may forbid cluster-wide workload listing.

### 3. Deepen only when needed

Stop when the available evidence supports a verdict. Otherwise choose the narrowest next source:

- Load `logs` for Graylog, Datadog, or Sentry evidence around the exact alert window.
- Load `braintrust` for MCP request errors, latency, tools, servers, or trace-level behavior.
- Check the alert provider's service metric for resource-specific pages such as database CPU, queue depth, or load-balancer errors.
- Inspect recent code or configuration changes only when timing or symptoms implicate a rollout.

Use a tight time window and the smallest useful result set. Do not query every available system by default.

## Verdicts

Classify the result as exactly one of:

- **Transient, no action:** The signal recovered quickly, has not repeated, the deployed revision is stable, capacity and dependencies are healthy, and no sustained errors remain.
- **Monitor:** The service recovered, but the alert repeated, capacity remains close to a limit, workload churn continues, or evidence is incomplete.
- **Actionable:** The alert remains active or repeats, availability is impaired, a rollout is unhealthy, capacity is exhausted, errors persist, or a dependency is failing.

Do not call an alert transient solely because it auto-resolved. Require supporting workload or dependency evidence.

## Response

Lead with the verdict in plain language. Then report:

- What paged and when
- Three to six facts supporting the verdict
- Any material uncertainty
- The smallest next action, or state that no action is needed

Keep routine transient-alert reports short. Include commands, raw events, or long timelines only when they explain a disputed or actionable finding.
