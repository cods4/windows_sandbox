# Opencode Agents: Fresh Start and Resume Guide

This document defines how the Opencode automation agents should operate, how progress is tracked across sessions, and how to resume work after interruptions. It also provides a minimal state model and example workflows to ensure continuity when starting fresh or picking up where you left off.

## Note on GitHub-sourced startup script
- The host startup.bat now fetches select_apps.ps1, install_apps.ps1, and apps.json from a public GitHub repository before running. This keeps scripts up-to-date but means the host must rely on the remote repo for the exact versions used during execution.
- Do not manually modify startup.bat on the host. If updates are needed, make changes in the GitHub repository and re-run or re-pull on the host to apply.

## Repo URL
- Public repo: https://github.com/cods4/windows_sandbox
- Raw files are pulled from https://raw.githubusercontent.com/cods4/windows_sandbox/main/

## Goals
- Allow Opencode to be started fresh and #pick up where it left off by persisting a lightweight state.
- Provide a deterministic, observable workflow for multi-step tasks.
- Make it easy to extend with new steps and tasks while keeping the history auditable.

## Where the state is stored
- State file path (root of project): .\agents_state.json
- If a deeper project structure is desired, you can switch to a dedicated directory (eg. .\state\agents_state.json). The examples below assume root-level state for simplicity.

Note: If you already have a memory file (.github/instructions/memory.instruction.md), use that as guidance to seed initial steps when there is no existing state.

## State schema (JSON)
A minimal, future-proof model. This is designed to be simple to read/write and upgrade in place.

```
{
  "version": "1.0",
  "created": "2025-08-08T12:00:00Z",
  "lastUpdated": "2025-08-08T12:00:00Z",
  "steps": [
    { "id": 1, "name": "Initial workspace scan", "status": "pending", "notes": "Describe current state and inputs" },
    { "id": 2, "name": "Identify missing pieces", "status": "pending", "notes": "List gaps to fill" },
    { "id": 3, "name": "Implement changes", "status": "pending", "notes": "Code, tests, docs" }
  ],
  "currentStepId": 1,
  "lastCompletedStepId": null,
  "notes": "Optional high-level notes about the session."
}
```

Field explanations:
- version: schema version for compatibility as you evolve the agent system.
- created/lastUpdated: timestamps for auditing and retries.
- steps: ordered tasks with a readable name and status.
- currentStepId: the step you are currently working on or plan to start next.
- lastCompletedStepId: the most recent step finished successfully.
- notes: any extra context for this session.

Status values:
- pending: not started yet
- in-progress: actively being worked on
- done: completed
- blocked: awaiting external input or a dependency

## How to start fresh
1. Remove any existing state file (to start from scratch):
   - PowerShell/Windows: del .\agents_state.json
   - Or delete manually via file explorer.
2. Create an initial state with the default starter steps. Example:
   - Step 1: "Initial workspace scan" -> status: pending
   - Step 2: "Identify missing pieces" -> status: pending
   - Step 3: "Implement changes" -> status: pending
3. Run the agent workflow from the first step. As each step completes, update the state accordingly (see below for update conventions).

## How to resume from an existing state
1. Ensure .\agents_state.json exists.
2. Read the currentStepId and lastCompletedStepId
3. Continue from currentStepId, or set up the agent to automatically advance once a step completes.
4. After each step, update lastUpdated and lastCompletedStepId accordingly.

## How to update the state (programmatic guidance)
- Loading state:
  - Read and parse agents_state.json
- Updating a step:
  - Find the step by id and set status to in-progress or done as appropriate
  - If a step is completed, set lastCompletedStepId to that id and increment currentStepId to the next step (if any)
  - Update lastUpdated timestamp
- Appending new steps:
  - Push a new object into the steps array with an incremental id and status pending
- Saving:
  - Overwrite .\agents_state.json with the new JSON content

## Example workflow (pseudo-trace)
- Initial state: steps 1-3 all pending, currentStepId = 1
- Run Step 1: set steps[0].status = "in-progress"; on success, steps[0].status = "done"; lastCompletedStepId = 1; currentStepId = 2; lastUpdated = now
- Run Step 2: same pattern; then Step 3
- If an unexpected error occurs, set steps[x].status = "blocked" and populate notes with required actions

## Extensibility guidance
- Add per-step metadata (expected inputs, outputs, and time estimates) to help orchestration.
- Store per-step logs or references to artifacts in a separate log/file store if needed.
- Consider versioning the state schema and writing a small compatibility layer in case formats change.

## Interaction with existing memory/instructions
- If you have a memory/instruction outline in .github/instructions/memory.instruction.md, use that as guidance to seed the initial steps when there is no existing state.

## Versioning and governance
- Increment the version field when the structure of the state changes.
- Maintain a simple changelog within the repo to document what changes the agents perform between versions.

If you want, I can extend this with a small sample Python/PowerShell helper to read/write agents_state.json and a CLI to manage steps from the command line. Also tell me if you want the state to be stored in a dedicated hidden folder (e.g., .opencode/state) to avoid clutter in the project root.
