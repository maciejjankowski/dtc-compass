# DTC Compass - Digital Transformation Consultant Framework

**IP-protected consulting toolkit for high-level Digital Transformation consulting.**

Extracted from nSENS framework (personal IP).

---

## Purpose

Augment Digital Transformation Consultant work with AI-powered analysis:
- **Multi-perspective analysis** via 8 expert personas
- **Decision trail** with alternatives and viability conditions
- **Cognitive bias detection** (47 biases)
- **ROI validation** via Prolog (prevents hallucination)
- **Strategic frameworks** (15 thinking tools)
- **Structured discovery** (6 research workflows)

All client work stored in gitignored `client/` folders for IP protection.

---

## Quick Start

### Installation

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Usage

```python
from cli.decision_trail import DecisionTrail

# Log decision with alternatives
trail = DecisionTrail("acme-corp")
trail.log_decision(
    topic="Cloud migration strategy",
    chosen="AWS with Terraform",
    alternatives=["Azure", "GCP", "Multi-cloud"],
    rationale="Team has AWS experience, Terraform IaC proven",
    viability_conditions="Assumes: AWS pricing stable, team retention >80%, no regulatory changes requiring EU-only data",
    confidence=0.82,
    impact="high",
    reversibility="medium",
    trade_offs={
        "vendor_lock_in": "Medium risk - mitigated by Terraform abstraction",
        "cost": "Higher than GCP for compute, lower for storage"
    }
)

# Output: client/acme-corp/decisions.jsonl + decision_20260105_143022.md
```

### ROI Validation

```python
from validators.roi_validator import PrologValidator

validator = PrologValidator()

# Validate ROI (must be ≥ 1.5x)
result = validator.validate_roi(revenue=150000, costs=80000)
print(result)  # {'valid': True, 'roi': 0.875, 'threshold': 1.5}

# Validate LTV:CAC (must be ≥ 3:1)
result = validator.validate_ltv_cac(ltv=12000, cac=3000)
print(result)  # {'valid': True, 'ratio': 4.0, 'threshold': 3.0}
```

---

## Framework Components

### 1. Personas (`catalogs/personas.yaml`)

8 expert perspectives for ethical, high-level consulting:

| Persona | Role | Use For |
|---------|------|---------|
| **Silas** | Counter-Intel Analyst | Competitive analysis, expose unvalidated claims |
| **Bill** | Truth Engine | Pattern recognition, brutal clarity |
| **Midas** | Cash Flow Predator | ROI focus, unit economics validation |
| **Steve** | Blue Ocean Shark | Strategic positioning, differentiation |
| **Curie** | Experimental Proof Enforcer | Evidence requirements, assumption testing |
| **Dick** | Contrarian Timing Oracle | "Why now?" analysis |
| **Scout** | Research Methodology Architect | Discovery workflow design |
| **Axis** | Business Model Architect | Sustainable, ethical business models |

### 2. Cognitive Biases (`catalogs/biases.yaml`)

47 biases with detection patterns:
- Confirmation Bias, Anchoring, Sunk Cost Fallacy
- Availability Heuristic, Recency Bias, Authority Bias
- Dunning-Kruger Effect, Groupthink, NIH Syndrome
- And 38 more...

### 3. Thinking Tools (`catalogs/thinking_tools.yaml`)

15 strategic frameworks:
- **Competitive Strategy**: Porter's Five Forces
- **Strategic Planning**: SWOT Analysis, Value Chain
- **Risk Management**: Premortem, Inversion
- **Decision Making**: OODA Loop, Cynefin, Decision Matrix
- **Prioritization**: Eisenhower Matrix, Pareto Principle
- **Problem Solving**: First Principles, Second-Order Thinking
- **Customer Insights**: Jobs To Be Done
- **Bias Detection**: Ladder of Inference

### 4. Discovery Prompts (`catalogs/discovery_prompts.yaml`)

Structured client research workflows:
- **Strategic Context** (30-45 min): Business goals, constraints, stakeholders
- **Market Analysis** (45-60 min): TAM/SAM/SOM, competitors, positioning
- **Technology Assessment** (60-90 min): Current state, pain points, future needs
- **ROI Validation** (30-45 min): Costs, benefits, risks, assumptions
- **Change Readiness** (30-45 min): Culture, capabilities, governance
- **Failure Modes** (30-45 min): Premortem, dependencies, mitigation

### 5. Validators (`validators/`)

Prolog-based business logic validation:
- `roi_validator.py`: ROI, LTV:CAC, margin, phase gates
- `rules.pl`: Formal logic rules (prevents hallucination)

---

## Architecture

```
dtc-compass/
├── catalogs/           # Knowledge bases
│   ├── personas.yaml   # 8 expert personas
│   ├── biases.yaml     # 47 cognitive biases
│   ├── thinking_tools.yaml  # 15 strategic frameworks
│   └── discovery_prompts.yaml  # Client research workflows
│
├── validators/         # ROI & business logic validation
│   ├── roi_validator.py  # Python + Prolog validation
│   └── rules.pl        # Formal business rules
│
├── cli/                # Command-line tools
│   └── decision_trail.py  # Decision logging with alternatives
│
└── client/             # Client work (gitignored)
    └── {client-name}/
        ├── decisions.jsonl  # Machine-readable decision log
        ├── decision_*.md    # Human-readable decision records
        └── discovery_*.md   # Client research outputs
```

---

## Decision Trail Philosophy

Every decision is logged with:
1. **Chosen path**: What we decided
2. **Alternatives**: What we didn't choose (and why)
3. **Viability conditions**: Assumptions that must hold
4. **Plan B**: When to switch to alternative path

**Why?** Conditions change. When an assumption breaks, you need the alternative paths preserved.

Example:
```
Decision: Use AWS
Alternatives: Azure (if EU regulation requires), GCP (if cost becomes critical)
Viability conditions: AWS pricing stable, no EU-only data laws, team retention >80%
Plan B: If EU regulation passes → switch to Azure (condition: regulatory requirement)
```

---

## IP Protection

**Critical:** This framework was created BEFORE Future Processing employment (2026-01-04).

- All client work goes in `client/` (gitignored)
- Framework itself is personal IP
- FP gets deliverables, not framework source
- Decision trail enables knowledge extraction without exposing client data

---

## Validation Rules

Based on Future Processing's performance model:

| Rule | Threshold | Purpose |
|------|-----------|---------|
| ROI | ≥ 1.5x | Minimum return on investment |
| LTV:CAC | ≥ 3:1 | Unit economics must be sustainable |
| Margin | ≥ 20% | Healthy profit margin |
| Payback | ≤ 12 months | Customer acquisition payback period |

Prolog validation prevents hallucination on numeric claims.

---

## License

Personal IP - Maciej Jankowski (created 2026-01-04, pre-employment)
