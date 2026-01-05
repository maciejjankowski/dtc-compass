#!/usr/bin/env python3
"""
Decision Trail Logger for DTC Compass
Records decision alternatives, trade-offs, and viability conditions

Usage:
    dtc decide --topic "Cloud migration approach" \
        --chosen "Lift-and-shift to AWS" \
        --alternatives "Replatform to containers" "Stay on-prem with modernization" \
        --conditions "Works IF: Budget ≥ $500k, Timeline ≥ 6mo, DevOps team available" \
        --confidence 0.75 \
        --client acme
"""

import json
from datetime import datetime
from pathlib import Path
import argparse


class DecisionTrail:
    """
    Logs consulting decisions with alternatives and viability conditions.
    Stored in client/ folder (gitignored for IP protection).
    """

    def __init__(self, client_name: str):
        self.client_name = client_name
        self.client_dir = Path("client") / client_name
        self.decisions_file = self.client_dir / "decisions.jsonl"
        self.client_dir.mkdir(parents=True, exist_ok=True)

    def log_decision(
        self,
        topic: str,
        chosen: str,
        alternatives: list[str],
        rationale: str,
        viability_conditions: str,
        confidence: float,
        impact: str = "high",
        reversibility: str = "medium",
        trade_offs: dict = None,
    ):
        """
        Log a decision with full audit trail.

        Args:
            topic: What decision is being made
            chosen: The selected option
            alternatives: Other options considered
            rationale: Why chosen over alternatives
            viability_conditions: "Works IF..." conditions
            confidence: 0.0-1.0 confidence in decision
            impact: high/medium/low business impact
            reversibility: easy/medium/hard to reverse
            trade_offs: Dict of trade-offs made
        """
        decision = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "topic": topic,
            "chosen": chosen,
            "alternatives": alternatives,
            "rationale": rationale,
            "viability_conditions": viability_conditions,
            "confidence": confidence,
            "impact": impact,
            "reversibility": reversibility,
            "trade_offs": trade_offs or {},
            "meta": {
                "client": self.client_name,
                "framework": "dtc-compass",
                "version": "1.0",
            },
        }

        # Append to JSONL
        with open(self.decisions_file, "a") as f:
            f.write(json.dumps(decision) + "\n")

        # Also write markdown for human readability
        self._write_markdown(decision)

        return decision

    def _write_markdown(self, decision: dict):
        """Write human-readable markdown version."""
        md_file = self.client_dir / f"decision_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md"

        content = f"""# Decision: {decision['topic']}

**Date**: {decision['timestamp']}
**Confidence**: {decision['confidence']:.0%}
**Impact**: {decision['impact']}
**Reversibility**: {decision['reversibility']}

---

## Chosen Path

{decision['chosen']}

### Rationale

{decision['rationale']}

### Viability Conditions

{decision['viability_conditions']}

---

## Alternatives Considered

"""
        for i, alt in enumerate(decision['alternatives'], 1):
            content += f"{i}. {alt}\n"

        if decision['trade_offs']:
            content += "\n---\n\n## Trade-Offs\n\n"
            for key, value in decision['trade_offs'].items():
                content += f"- **{key}**: {value}\n"

        content += f"""

---

## When to Revisit This Decision

If any viability condition changes, re-evaluate.

Alternative paths remain viable under different conditions:
"""
        for alt in decision['alternatives']:
            content += f"- {alt}\n"

        with open(md_file, "w") as f:
            f.write(content)

        print(f"✅ Decision logged: {md_file}")

    def get_decisions(self, topic_filter: str = None):
        """Retrieve decisions, optionally filtered by topic."""
        if not self.decisions_file.exists():
            return []

        decisions = []
        with open(self.decisions_file) as f:
            for line in f:
                d = json.loads(line)
                if topic_filter is None or topic_filter.lower() in d["topic"].lower():
                    decisions.append(d)

        return decisions

    def find_alternatives(self, current_topic: str):
        """
        Find alternative paths for a given topic.
        Useful when conditions change and you need plan B.
        """
        decisions = self.get_decisions(current_topic)

        if not decisions:
            return None

        # Get most recent decision on this topic
        latest = decisions[-1]

        return {
            "current_choice": latest["chosen"],
            "alternatives": latest["alternatives"],
            "conditions_for_current": latest["viability_conditions"],
            "confidence": latest["confidence"],
            "timestamp": latest["timestamp"],
        }


def main():
    parser = argparse.ArgumentParser(description="Log consulting decisions with alternatives")
    parser.add_argument("--client", required=True, help="Client name")
    parser.add_argument("--topic", required=True, help="Decision topic")
    parser.add_argument("--chosen", required=True, help="Chosen option")
    parser.add_argument("--alternatives", nargs="+", required=True, help="Alternative options")
    parser.add_argument("--rationale", required=True, help="Why chosen")
    parser.add_argument("--conditions", required=True, help="Viability conditions (Works IF...)")
    parser.add_argument("--confidence", type=float, default=0.7, help="Confidence 0.0-1.0")
    parser.add_argument("--impact", default="high", choices=["high", "medium", "low"])
    parser.add_argument("--reversibility", default="medium", choices=["easy", "medium", "hard"])

    args = parser.parse_args()

    trail = DecisionTrail(args.client)
    decision = trail.log_decision(
        topic=args.topic,
        chosen=args.chosen,
        alternatives=args.alternatives,
        rationale=args.rationale,
        viability_conditions=args.conditions,
        confidence=args.confidence,
        impact=args.impact,
        reversibility=args.reversibility,
    )

    print(f"\n✅ Decision logged for {args.client}")
    print(f"📋 Topic: {decision['topic']}")
    print(f"✓ Chosen: {decision['chosen']}")
    print(f"⚠️  Conditions: {decision['viability_conditions']}")
    print(f"🔄 Alternatives: {len(decision['alternatives'])} options preserved")


if __name__ == "__main__":
    main()
