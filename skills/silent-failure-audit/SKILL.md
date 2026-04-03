---
name: silent-failure-audit
description: Detect silent failures in status, health, detection, and initialization code. Catches hardcoded status values, swallowed errors, stale data, no-op handlers, and single-path detection that corrupt real system state.
---

# Silent Failure Audit

## When to Use This Skill

- Reviewing PRs that touch status, health, detection, or initialization code
- Auditing Electron/desktop apps, subprocess management, or multi-service architectures
- After discovering a bug caused by a function that "worked" but lied about reality
- Security audits on IPC handlers, log output, or file-based status readers
- Any code that reports system state to a UI or monitoring system

## Target Agents

- `code-reviewer` - Primary user during PR reviews (silent failure checklist)
- `cyber-sentinel` - Security implications of silent failures
- `chief-operations-orchestrator` - Quality gate enforcement (truth audit)
- `qa-test-planner` - Environment-diversity test planning
- `automated-test-scripter` - Implementing env-variation tests

## The Problem

Standard pipelines (pytest, linters, TypeScript compiler, manual review) validate **syntax, types, and logic** but not **truthfulness of status reports**. Code can run correctly, return valid types, and pass all tests while lying about reality.

Example: `mcpAvailable: true` is a valid boolean that passes type checks, but if it's hardcoded rather than derived from an actual check, it silently corrupts the real status.

---

## 7 Mandatory Checks

Every PR touching **status, health, detection, or initialization** code MUST pass ALL of these:

### 1. No Hardcoded Status Values

**Rule**: Flag any `true`/`false` literal in a status/health return object. Status fields MUST be derived from an actual check, never hardcoded.

**Grep patterns**:
```bash
# Find hardcoded status returns
grep -rn "available:\s*true\|healthy:\s*true\|connected:\s*true\|running:\s*true" --include="*.ts" --include="*.js" --include="*.py"
grep -rn "status:\s*['\"]success['\"]" --include="*.ts" --include="*.js" --include="*.py"
grep -rn "return\s*{\s*success:\s*true" --include="*.ts" --include="*.js" --include="*.py"
```

**Bad**:
```typescript
getDegradationStatus() {
  return { mcpAvailable: true, apiHealthy: true };  // HARDCODED LIE
}
```

**Good**:
```typescript
async getDegradationStatus() {
  const mcpAvailable = await this.checkMcpConnection();
  const apiHealthy = await this.pingApi();
  return { mcpAvailable, apiHealthy };
}
```

### 2. Multi-Strategy Environment Detection

**Rule**: Flag any function that checks ONE filesystem path for external tool detection. MUST use fallback chains: filesystem paths -> env vars -> running process detection -> system queries (WMI/PowerShell/registry).

**Grep patterns**:
```bash
# Find single-path detection
grep -rn "existsSync\|exists_sync\|os.path.exists\|Path.*exists" --include="*.ts" --include="*.js" --include="*.py" -A 3
# Check if the function has fallback logic
```

**Bad**:
```typescript
function findClaude(): string | null {
  const path = 'C:\\Users\\user\\AppData\\Local\\AnthropicClaude\\claude.exe';
  return fs.existsSync(path) ? path : null;  // MISSES Store installs
}
```

**Good**:
```typescript
function findClaude(): string | null {
  // Strategy 1: Standard installer path
  const installerPath = path.join(process.env.LOCALAPPDATA, 'AnthropicClaude', 'claude.exe');
  if (fs.existsSync(installerPath)) return installerPath;

  // Strategy 2: Microsoft Store (WindowsApps)
  const storePath = findInWindowsApps('claude');
  if (storePath) return storePath;

  // Strategy 3: PATH lookup
  const pathResult = which.sync('claude', { nothrow: true });
  if (pathResult) return pathResult;

  // Strategy 4: Running process detection
  const running = findRunningProcess('claude');
  if (running?.execPath) return running.execPath;

  return null;
}
```

### 3. No Swallowed Errors in Status/Health Functions

**Rule**: Flag empty `catch {}` blocks in any function that reports status, health, or installation state. The catch block MUST either (a) try a fallback strategy, or (b) surface the error in the return value.

**Grep patterns**:
```bash
# Find empty catch blocks
grep -rn "catch\s*(\w*)\s*{\s*}" --include="*.ts" --include="*.js"
grep -rn "catch\s*(.*Error.*):\s*$" --include="*.py" -A 1
# Also check for catch blocks that only log
grep -rn "catch.*{" --include="*.ts" --include="*.js" -A 2 | grep -B 1 "console.log\|// ignore\|pass$"
```

**Bad**:
```typescript
async checkOllamaStatus() {
  try {
    const resp = await fetch('http://localhost:11434/api/tags');
    return { available: true, models: resp.models };
  } catch {
    return { available: false };  // WHY did it fail? Port? Auth? DNS?
  }
}
```

**Good**:
```typescript
async checkOllamaStatus() {
  const host = process.env.OLLAMA_HOST || 'http://localhost:11434';
  try {
    const resp = await fetch(`${host}/api/tags`, { signal: AbortSignal.timeout(3000) });
    if (!resp.ok) return { available: false, error: `HTTP ${resp.status}` };
    return { available: true, models: (await resp.json()).models };
  } catch (err) {
    return { available: false, error: err.message, host };
  }
}
```

### 4. Success Must Require Verification

**Rule**: Flag any multi-step operation that unconditionally returns `status: 'success'` or `success: true`. Success MUST be derived from the actual outcome.

**Grep patterns**:
```bash
# Find unconditional success returns after async operations
grep -rn "return.*success.*true\|resolve.*success\|status.*success" --include="*.ts" --include="*.js" --include="*.py" -B 5
```

**Bad**:
```typescript
async installPlugin(url: string) {
  await downloadFile(url, pluginDir);
  await extractArchive(pluginDir);
  return { status: 'success' };  // What if extract failed silently?
}
```

**Good**:
```typescript
async installPlugin(url: string) {
  const downloadResult = await downloadFile(url, pluginDir);
  if (!downloadResult.ok) return { status: 'failed', step: 'download', error: downloadResult.error };

  const extractResult = await extractArchive(pluginDir);
  if (!extractResult.ok) return { status: 'failed', step: 'extract', error: extractResult.error };

  const manifest = await readManifest(pluginDir);
  if (!manifest) return { status: 'failed', step: 'validate', error: 'No manifest found after extract' };

  return { status: 'success', plugin: manifest.name, version: manifest.version };
}
```

### 5. Staleness Guards on File-Based Status

**Rule**: Flag any status reader that reads a file/JSON without checking the timestamp for freshness. Stale data from a dead process MUST be detected (10s default threshold).

**Grep patterns**:
```bash
# Find status file readers without timestamp checks
grep -rn "readFileSync\|readFile\|read_json\|json.load" --include="*.ts" --include="*.js" --include="*.py" -A 5 | grep -i "status\|health\|state"
```

**Bad**:
```typescript
function getServiceStatus(): ServiceStatus {
  const data = JSON.parse(fs.readFileSync(statusFile, 'utf-8'));
  return data;  // Could be from a crashed process 3 hours ago
}
```

**Good**:
```typescript
function getServiceStatus(): ServiceStatus {
  const stat = fs.statSync(statusFile);
  const ageMs = Date.now() - stat.mtimeMs;

  if (ageMs > 10_000) {
    return { stale: true, lastUpdate: stat.mtime, error: 'Status file older than 10s — process may be dead' };
  }

  const data = JSON.parse(fs.readFileSync(statusFile, 'utf-8'));
  return { ...data, stale: false, ageMs };
}
```

### 6. IPC/API Handlers Must Implement Their Contract

**Rule**: Flag any handler that accepts arguments but does nothing with them (no-op stubs). Must return an error indicating "not implemented" rather than silently succeeding.

**Grep patterns**:
```bash
# Find potential no-op handlers
grep -rn "ipcMain.handle\|ipcMain.on\|app.post\|app.put\|@app.route" --include="*.ts" --include="*.js" --include="*.py" -A 5 | grep -B 3 "return;\|return undefined\|pass$\|return {}"
```

**Bad**:
```typescript
ipcMain.handle('save-preferences', async (_event, prefs) => {
  // TODO: implement persistence
  return;  // Silently succeeds — prefs are lost on restart
});
```

**Good**:
```typescript
ipcMain.handle('save-preferences', async (_event, prefs) => {
  throw new Error('save-preferences: not yet implemented — preferences will not persist');
  // OR: implement it
});
```

### 7. Fire-and-Forget Startup Verification

**Rule**: Flag any `start()`/`initialize()` that resolves after a blind `setTimeout` or `sleep` without verifying the subprocess is alive. MUST wait for first output or handle error/exit events.

**Grep patterns**:
```bash
# Find blind timeout resolutions after spawn/exec
grep -rn "setTimeout\|sleep\|delay" --include="*.ts" --include="*.js" --include="*.py" -B 5 | grep -i "spawn\|exec\|start\|init\|launch"
```

**Bad**:
```typescript
async startServer(): Promise<void> {
  this.process = spawn('node', ['server.js']);
  await new Promise(resolve => setTimeout(resolve, 2000));  // Hope it started
}
```

**Good**:
```typescript
async startServer(): Promise<void> {
  this.process = spawn('node', ['server.js']);
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error('Server startup timeout (5s)')), 5000);

    this.process.stdout.once('data', (data) => {
      if (data.toString().includes('listening')) {
        clearTimeout(timeout);
        resolve();
      }
    });

    this.process.on('error', (err) => { clearTimeout(timeout); reject(err); });
    this.process.on('exit', (code) => {
      if (code !== 0) { clearTimeout(timeout); reject(new Error(`Server exited with code ${code}`)); }
    });
  });
}
```

---

## Security-Specific Checks (for cyber-sentinel)

### Information Disclosure via Logs
- Structured logs consumed by UI must NEVER include file paths, line numbers, or stack traces
- Class name + message only in user-facing logs; full traceback at DEBUG level to file-only handler
- **Audit check**: `grep -rn "traceback\|stack" --include="*.ts" --include="*.js" --include="*.py"` in JSON-RPC error responses or structured log entries

### Persistence Claims Without Implementation (Integrity Risk)
- Any handler that accepts data MUST persist or return an error; no-op stubs are a security gap
- Renders security settings ineffective if silently lost on restart
- **Audit check**: grep for IPC/API handlers with empty bodies or that ignore their arguments

### Status Spoofing via Stale Data
- Status files persisting on disk after process crash can fool the UI into showing "healthy"
- Any status derived from a file MUST validate freshness; any status field MUST come from a live check
- **Audit check**: grep for status readers that don't compare timestamps

---

## Quality Gate: Truth Audit (for chief-operations-orchestrator)

After ANY feature touching status/health/detection/initialization, require:

1. **Truthfulness check**: Does every status field come from a live verification?
2. **Environment diversity**: Does detection cover all install methods (installer, Store, package managers, custom ports)?
3. **Error surfacing**: Do all error paths return structured errors, not bare `false` or empty catch?
4. **Staleness protection**: Do file-based status readers check timestamps?
5. **Startup verification**: Do subprocess launchers verify the process is alive before resolving?

### Delegation Rules
- After any status/health/detection PR: route to `code-reviewer` with "silent failure checklist" flag
- After any log format change: route to `cyber-sentinel` for information disclosure check
- After any IPC/API handler addition: verify it implements its contract (no no-op stubs)

---

## Environment-Diversity Test Cases (for qa-test-planner)

When planning tests for detection/status code, include these scenarios:

| Scenario | What to Mock | Expected Behavior |
|----------|-------------|-------------------|
| Standard install only | Default path exists, no Store path | Detect via default path |
| Store install only | No default path, WindowsApps path exists | Detect via Store path |
| PATH-only install | No standard paths, binary in PATH | Detect via `which`/`where` |
| Custom port | Default port fails, `OLLAMA_HOST` set | Use env var port |
| Process running but no binary | No exe path, process in task list | Detect via process list |
| Stale status file | Status file exists, timestamp > 10s old | Report stale, not healthy |
| Crashed process | PID file exists, process not running | Report dead, not running |
| Config exists, exe missing | Config dir present, no executable | Report partial install |

---

## CLAUDE.md Template

To enforce these rules at the project level, add this section to your project's CLAUDE.md:

```markdown
## Silent Failure Prevention

- Status/health functions MUST verify what they claim — no hardcoded true/false in return values
- Environment detection MUST use multi-strategy fallback (filesystem paths, env vars, running processes, WMI)
- Error paths MUST surface the reason — no bare `catch {}` in status/health functions; return `{ success, error }`
- Multi-step operations MUST derive success from outcome — no unconditional `status: 'success'`
- Staleness guard: any status read from a file/timestamp MUST check freshness (10s default threshold)
- IPC handlers MUST implement their contract — no no-op stubs without UI indication
- Subprocess start() MUST verify the process is alive — no blind setTimeout/sleep resolutions
- Code review checklist: for every status/health PR, verify (1) actually checks the thing it claims, (2) handles all install paths, (3) error path surfaces the reason, (4) success requires verification
```
