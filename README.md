# Claude Code Agents - Team Nation of Elites

<p align="center">
  <em>Created by: Yassine Boumiza</em>
</p>

<p align="center">
  <img src="https://i.imgur.com/9g2s1Yy.jpg" alt="Nation of Elites Banner" width="600"/>
</p>

<p align="center">
  <strong>An orchestrated AI workforce that functions like a real-world IT company.</strong>
  <br />
  Supercharge your development with a complete, role-based AI team that can take a project from initial idea to production-ready deployment.
</p>

---

## 🎯 The Problem & The Solution

A single, generalist AI, no matter how powerful, lacks the specialized expertise and structured workflow of a real-world company. Complex projects require a team of specialists—architects, managers, developers, testers, and security experts—all working in concert.

**The "Nation of Elites" is the solution.** It's not just a collection of agents; it's a fully-realized, virtual IT organization. Each agent has a specific role, a clear mission, and defined responsibilities, mirroring the structure of a high-performing tech company. This allows for unparalleled coordination, deep expertise, and a systematic approach to building software.

## 🚀 Quick Start (3-Step Deployment)

Get your AI workforce operational in under two minutes.

### 1. Install the "Nation of Elites" Agents

Option A — Automated (recommended):

```bash
# From the repository root
bash scripts/deploy_agents.sh
```

Option B — Manual (sanitized deploy):

```bash
# Clone the repository
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git

# Navigate into the cloned repository
cd claude-code-agents-team-nation-of-elites

# Sanitize target to avoid conflicts with older configurations
rm -rf ~/.claude/agents ~/.claude/projects

# Deploy current agents set
mkdir -p ~/.claude
cp -r agents ~/.claude/agents

# Validate key files
test -f ~/.claude/agents/07_Orchestrators/Tech_Lead_Orchestrator.md && echo "Tech Lead Orchestrator present"
! grep -R "tech-lead-orchestrator-deprecated" ~/.claude/agents -n && echo "No deprecated orchestrator found"
```

WSL2 note: The Linux path `~/.claude` appears in Windows Explorer as `\\wsl.localhost\Ubuntu\home\<USER>\.claude`. You can verify post-deploy there.

### 2. Create a New Project

Navigate to your project's root directory or create a new one.

```bash
mkdir my-new-app
cd my-new-app
```

### 3. Initialize Your Project with the AI Workforce

Run a single command to have your AI team analyze your project, understand its goals, and prepare for execution. This is the equivalent of a company-wide kickoff meeting.

**Tell Claude to initialize the project:**
```
claude "Use the 'project-sponsor' to define the high-level business goal for this project: 'Build a secure, scalable e-commerce platform for selling custom t-shirts'. Then, have the 'program-manager' and 'product-manager' create an initial high-level roadmap and feature backlog. Finally, instruct the 'solution-architect' to propose a technology stack. Save all artifacts in a new '/docs' directory."
```

This single, powerful command kicks off the entire organizational workflow. The `project-sponsor` sets the vision, the managers create the plan, and the architect defines the technology, setting the stage for the entire project lifecycle. You are now ready to start building features with your complete AI workforce.

## 🏛️ Team Structure and Workflow

The "Nation of Elites" is organized hierarchically to mirror a real-world IT company, ensuring a clear flow of command and responsibility from high-level strategy to hands-on implementation. With **36 specialized agents** across **6 strategic divisions**, the team now includes enhanced coverage for high-performance systems, event-driven architectures, and financial applications.

```
/agents
├── 00_Executive_Wing/
│   └── (Project Sponsor, Program Manager)
├── 01_Strategy_and_Planning_Wing/
│   └── (Product Manager, Solution Architect, etc.)
├── 02_Project_Management_Office/
│   └── (Project Manager/Scrum Master)
├── 03_Engineering_Division/
│   └── (Tech Lead, Developers, Specialists)
├── 04_Quality_Assurance_Battalion/
│   └── (QA Engineer, QA Planners, Testers)
├── 05_SecOps_and_Infrastructure_Division/
│   └── (DevOps, Security, Cloud Architects)
└── 06_AI_and_Machine_Learning_Division/
    └── (Data Scientists, ML Engineers)
```

-   **`00_Executive_Wing`**: Sets the high-level business vision and provides resources. The project starts here.
-   **`01_Strategy_and_Planning_Wing`**: Takes the vision and creates a concrete plan. They define *what* to build, *why*, and the high-level technical approach.
-   **`02_Project_Management_Office`**: Manages the project's execution, timeline, and agile processes.
-   **`03_Engineering_Division`**: The core builders. The Tech Lead orchestrates the various developers and specialists to write the code.
-   **`04_Quality_Assurance_Battalion`**: Systematically tests the software to ensure it's bug-free and meets requirements.
-   **`05_SecOps_and_Infrastructure_Division`**: Deploys the application to a secure, scalable production environment.
-   **`06_AI_and_Machine_Learning_Division`**: Integrates data-driven intelligence and machine learning capabilities into the product.
-   **`07_Orchestrators`**: Coordinates multi-agent execution and team setup.
    - `tech-lead-orchestrator`: Central execution coordinator (planning, delegation, gates).
    - `team-configurator`: Team setup orchestrator (stack detection, subagent selection, CLAUDE.md config).

## 🧠 Thinking Policies & Budgets

The orchestrator enforces explicit, budgeted internal reasoning across roles. Agents use an internal scratchpad only when triggered and surface concise rationale summaries (no raw chain-of-thought) in outputs.

- **Architects (Solution, UX/UI, API, Cloud):** 600–800 tokens
- **Analysts (e.g., Business/Functional Analyst, QA Test Planner):** 400–600 tokens
- **Framework Specialists (e.g., React/Vue/Next.js, Tailwind):** 200–300 tokens
- **SecOps/Infra/DevOps (Cyber Sentinel, Infra Specialist, DevOps Engineer):** 200–300 tokens
- **Implementers (Backend, Frontend, QA Engineer, Scripted automation):** 100–200 tokens
- **Orchestrator:** ≤300 tokens

Guardrails (enforced by orchestrator):
- Trigger thinking only for complex tradeoffs/uncertainty. Stop at budget.
- Output concise rationale sections only (bullets). No raw chain-of-thought.
- After two passes, if uncertainty remains → request clarification or delegate to the appropriate role.

## 🤝 Contributing

The "Nation of Elites" is an ambitious project, and contributions are welcome! Whether you want to refine an existing agent's prompt, add a new specialist role, or improve the orchestration workflow, please feel free to fork the repository and submit a pull request.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingNewAgent`)
3.  Commit your Changes (`git commit -m 'Add some AmazingNewAgent'`)
4.  Push to the Branch (`git push origin feature/AmazingNewAgent`)
5.  Open a Pull Request

## 📚 Credits and References

-   **Author's Main Repository:** [https://github.com/advisely/](https://github.com/advisely/)
-   **Inspiration & Best Practices:** [Building Effective Agents - Anthropic Engineering](https://www.anthropic.com/engineering/building-effective-agents), [How we built our multi-agent research system](https://www.anthropic.com/engineering/built-multi-agent-research-system)

## 📄 License

Distributed under the MIT License with a friendly request for attribution. See the `LICENSE` file for more information.
