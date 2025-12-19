---
name: add-feature-flag
description: Scaffold feature flag plumbing. Can be triggered with "feature flag it" or "add the feature flag" or "let's add a feature flag".
license: MIT
allowed-tools: 
  - read
  - write
  - edit
  - bash
  - glob
metadata:
  version: "2.0"
---

# Feature Flag It

This skill adds all the plumbing for a feature flag. We work in two repositories:
- **MCP** (`/Users/jbaldwin/repos/mcp`) - Uses Split.io with env var overrides
- **AI Command Center** (`/Users/jbaldwin/repos/ai-command-center`) - Uses Harness (via Split.io) with Edge Config

## When to Use This Skill

Activate this skill when James explicitly says:
- "feature flag it"
- "add the feature flag"
- "let's add a feature flag"
- "add feature flag [NAME]" or "feature flag [NAME]"

**Do NOT** automatically invoke this skill. Wait for James to explicitly request it.

## Step 1: Detect Repository

Check the current working directory or recent file paths to determine which repo we're in:

| Repository | Detection | Flag System |
|------------|-----------|-------------|
| MCP | Path contains `/repos/mcp` | Split.io + env vars |
| AI Command Center | Path contains `/repos/ai-command-center` | Harness + Edge Config |

If unclear, ask James: "Which repo are we working in - MCP or AI Command Center?"

## Step 2: Determine Flag Name

If coming from a Jira ticket, derive the flag name from the ticket summary.
If not, ask James: "What should the feature flag be called?"

### Naming Conventions

**MCP:**
| Format | Example | Used In |
|--------|---------|---------|
| Env var | `FF_BATCH_OPERATIONS` | schema.ts, turbo.json, .env |
| Split flag | `batch_operations` | split.ts (Split.io dashboard) |
| Getter | `getIsBatchOperationsEnabled` | split.ts, index.ts |

**AI Command Center:**
| Format | Example | Used In |
|--------|---------|---------|
| Flag key | `batch_operations` | constants.ts, Harness dashboard |
| Env override | `OVERRIDE_FEATURE_FLAG_BATCH_OPERATIONS` | .env |

**Confirm with James:** "I'll create flag `batch_operations`. Sound good?"

---

## MCP Repository

### Files to Update (5 files)

All paths relative to `/Users/jbaldwin/repos/mcp`:

| File | Purpose |
|------|---------|
| `packages/env-config/src/schema.ts` | Define env var type |
| `turbo.json` | Add to globalEnv for build |
| `packages/feature-flags/src/split.ts` | Getter function |
| `packages/feature-flags/src/index.ts` | Export getter |
| `.env.development.local.example` | Document for devs |

### 2.1 Update env-config schema

**File:** `packages/env-config/src/schema.ts`

Add near the other `FF_*` variables:

```typescript
FF_BATCH_OPERATIONS: Type.Optional(Type.Boolean()),
```

### 2.2 Update turbo.json

**File:** `turbo.json`

Add to the `globalEnv` array (keep alphabetical with other FF_ vars):

```json
"FF_BATCH_OPERATIONS",
```

### 2.3 Add getter function

**File:** `packages/feature-flags/src/split.ts`

Add at the end of the file, following the existing pattern:

```typescript
/**
 * Check if [description] is enabled
 *
 * @param user - User context for targeting (userId is used as the Split key)
 */
export const getIsBatchOperationsEnabled = async (
  user: SplitUserAttributes,
): Promise<boolean> => {
  // In local/test environments, check env var first (bypasses Split.io)
  if (env.APP_ENV === "local" || env.APP_ENV === "test") {
    return env.FF_BATCH_OPERATIONS ?? false;
  }

  // Fall back to Split.io for staging/production
  if (!client) {
    return false;
  }

  return getFeatureFlag(user.userId, "batch_operations", user);
};
```

### 2.4 Export the function

**File:** `packages/feature-flags/src/index.ts`

Add to the export list:

```typescript
getIsBatchOperationsEnabled,
```

### 2.5 Update env example file

**File:** `.env.development.local.example`

Add:

```bash
# [Description of what this flag controls]
FF_BATCH_OPERATIONS=false
```

### MCP Summary

```
Feature flag `batch_operations` scaffolded.

Files updated:
- packages/env-config/src/schema.ts
- turbo.json  
- packages/feature-flags/src/split.ts
- packages/feature-flags/src/index.ts
- .env.development.local.example

Next steps:
1. Create flag in Split.io dashboard (name: `batch_operations`)
2. Call `getIsBatchOperationsEnabled(user)` where you need the check
```

---

## AI Command Center Repository

### Files to Update (1 file for web, 1 for MCP app if needed)

All paths relative to `/Users/jbaldwin/repos/ai-command-center`:

| File | Purpose |
|------|---------|
| `apps/web/src/server-sdk/lib/feature-flags/constants.ts` | Define flag with default |
| `apps/mcp/src/server-sdk/lib/feature-flags/split.ts` | MCP app flags (if needed) |

### 3.1 Add to constants (web app)

**File:** `apps/web/src/server-sdk/lib/feature-flags/constants.ts`

Add to the `featureFlagsWithDefaults` object:

```typescript
batch_operations: "off",
```

### 3.2 Add to MCP app (if flag is needed there)

**File:** `apps/mcp/src/server-sdk/lib/feature-flags/split.ts`

Add to the `featureFlagsWithDefaults` object:

```typescript
batch_operations: "off",
```

### AI Command Center Summary

```
Feature flag `batch_operations` scaffolded.

Files updated:
- apps/web/src/server-sdk/lib/feature-flags/constants.ts

Next steps:
1. Create flag in Harness dashboard (name: `batch_operations`, traffic type: "account")
2. Configure for both staging and production environments
3. Use server-side: `getFeatureFlagsFromSession(session)` then check `flags.batch_operations === "on"`
4. Use client-side: `useIsFlagEnabled("batch_operations")` or `isFlagEnabled("batch_operations")`
5. Local override: `OVERRIDE_FEATURE_FLAG_BATCH_OPERATIONS=on` in .env
```

---

## Usage Patterns by Repository

### MCP - Server-side usage

```typescript
import { getIsBatchOperationsEnabled } from "@zapier/feature-flags";

const enabled = await getIsBatchOperationsEnabled(user);
if (enabled) {
  // new behavior
}
```

### AI Command Center - Server-side usage

```typescript
import { getFeatureFlagsFromSession } from "@/server-sdk/lib/feature-flags/split";

const flags = await getFeatureFlagsFromSession(session);
if (flags.batch_operations === "on") {
  // new behavior
}
```

### AI Command Center - Client-side usage

```typescript
import { useIsFlagEnabled, useFeatureFlags } from "@/hooks/user";

// Option 1: Single flag check
const isEnabled = useIsFlagEnabled("batch_operations");

// Option 2: Multiple flags
const { isFlagEnabled } = useFeatureFlags();
if (isFlagEnabled("batch_operations")) {
  // new behavior
}
```

---

## SplitUserAttributes (MCP)

Available for targeting in MCP:

```typescript
interface SplitUserAttributes {
  userId: string;           // Split key for user-level targeting
  accountId: number;
  zapierCustomUserId: number;
  email: string;            // Domain targeting (@zapier.com)
  isStaff: boolean;         // Staff-only rollouts
  role: string;
  signupDate: string;
  planType: string;
}
```

## Targeting Attributes (AI Command Center)

Available for attribute-based targeting rules in Harness:
- `isStaff` - Staff-only rollouts
- `role` - Role-based targeting
- `email` - Email domain targeting
- `accountId` - Account-level targeting
- `userId` - User-level targeting
- `isPaid` - Paid plan targeting
- `isEnterprise` - Enterprise account targeting

---

## Examples

### Example 1: MCP repo, chained from work-on-ticket

```
James: "AGP-999"
Agent: [runs work-on-ticket skill]
Agent: "Bookmark created: agp-999-add-batch-operations. Ready to work on this."

James: "feature flag it"
Agent: "I'll create flag FF_BATCH_OPERATIONS / batch_operations. Sound good?"

James: "yes"
Agent: [scaffolds the 5 MCP files]
Agent: "Feature flag scaffolded. Next: create in Split.io, then implement."
```

### Example 2: AI Command Center repo, standalone

```
James: "add feature flag enable_new_sidebar"
Agent: "I see we're in ai-command-center. I'll add `enable_new_sidebar` to constants.ts. What's the default - on or off?"

James: "off"
Agent: [updates constants.ts]
Agent: "Done. Flag added with default 'off'. Create in Harness, then use useIsFlagEnabled('enable_new_sidebar')."
```

### Example 3: Unclear repo

```
James: "feature flag it"
Agent: "Which repo are we working in - MCP or AI Command Center?"

James: "mcp"
Agent: "What should the feature flag be called?"
...
```

## Success Criteria

1. Correct repository detected
2. Flag names confirmed with James
3. All required files updated for that repo
4. Getter function/constant follows existing patterns
5. James informed of next steps (dashboard setup, usage pattern)
