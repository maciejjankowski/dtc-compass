"""
Prolog Validation Engine for nSENS

Integrates SWI-Prolog for formal logic validation of business decisions.
Prevents hallucination, ensures mathematical correctness.
"""

from pathlib import Path
from typing import Dict, Any, List, Optional
import subprocess
import json


class PrologValidator:
    """
    Prolog validation engine using SWI-Prolog

    If SWI-Prolog is not installed, falls back to Python-based validation.
    """

    def __init__(self, prolog_file: Path = None):
        self.prolog_file = prolog_file or Path(__file__).parent.parent / "validation" / "logic" / "validation_core.pl"
        self.prolog_available = self._check_prolog_available()

    def _check_prolog_available(self) -> bool:
        """Check if SWI-Prolog is available"""
        try:
            subprocess.run(["swipl", "--version"], capture_output=True, check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("⚠ SWI-Prolog not available. Using Python fallback validation.")
            return False

    def validate_roi(self, revenue: float, costs: float) -> Dict[str, Any]:
        """Validate ROI is at least 1.5x"""
        if costs <= 0:
            return {"valid": False, "reason": "Costs must be positive", "roi": None}

        roi = (revenue - costs) / costs

        if self.prolog_available:
            # Use Prolog validation
            query = f"roi_positive({revenue}, {costs}, ROI)."
            result = self._query_prolog(query)
            if result:
                return {
                    "valid": True,
                    "roi": roi,
                    "threshold": 1.5,
                    "validated_by": "prolog"
                }

        # Python fallback
        valid = roi >= 1.5
        return {
            "valid": valid,
            "roi": roi,
            "threshold": 1.5,
            "reason": "ROI below 1.5x threshold" if not valid else "ROI acceptable",
            "validated_by": "python"
        }

    def validate_ltv_cac(self, ltv: float, cac: float) -> Dict[str, Any]:
        """Validate LTV:CAC ratio is at least 3:1"""
        if cac <= 0:
            return {"valid": False, "reason": "CAC must be positive", "ratio": None}

        ratio = ltv / cac

        if self.prolog_available:
            query = f"ltv_cac_acceptable({ltv}, {cac}, Ratio)."
            result = self._query_prolog(query)
            if result:
                return {
                    "valid": True,
                    "ratio": ratio,
                    "threshold": 3.0,
                    "validated_by": "prolog"
                }

        # Python fallback
        valid = ratio >= 3.0
        return {
            "valid": valid,
            "ratio": ratio,
            "threshold": 3.0,
            "reason": "LTV:CAC below 3:1 threshold" if not valid else "Unit economics strong",
            "validated_by": "python"
        }

    def validate_margin(self, revenue: float, costs: float) -> Dict[str, Any]:
        """Validate margin is at least 20%"""
        if revenue <= 0:
            return {"valid": False, "reason": "Revenue must be positive", "margin": None}

        margin = ((revenue - costs) / revenue) * 100

        if self.prolog_available:
            query = f"margin_acceptable({revenue}, {costs}, Margin)."
            result = self._query_prolog(query)
            if result:
                return {
                    "valid": True,
                    "margin": margin,
                    "threshold": 20.0,
                    "validated_by": "prolog"
                }

        # Python fallback
        valid = margin >= 20.0
        return {
            "valid": valid,
            "margin": margin,
            "threshold": 20.0,
            "reason": "Margin below 20% threshold" if not valid else "Margin acceptable",
            "validated_by": "python"
        }

    def validate_phase_gate(self, phase: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """Validate can proceed to next phase"""
        gate_validators = {
            "p1": self._validate_gate_p1,
            "p2": self._validate_gate_p2,
            "p3": self._validate_gate_p3,
            "p4": self._validate_gate_p4,
            "p5": self._validate_gate_p5,
        }

        validator = gate_validators.get(phase)
        if not validator:
            return {"valid": False, "reason": f"Unknown phase: {phase}"}

        return validator(context)

    def _validate_gate_p1(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """P0 → P1: Research complete, tier T1/T2"""
        checks = []

        # Check research complete
        if context.get("research_complete"):
            checks.append("✓ Research complete")
        else:
            checks.append("✗ Research incomplete")

        # Check tier
        tier = context.get("tier", "t4")
        if tier in ["t1", "t2"]:
            checks.append(f"✓ Tier {tier.upper()} (proceed)")
        else:
            checks.append(f"✗ Tier {tier.upper()} (no-go)")

        valid = context.get("research_complete") and tier in ["t1", "t2"]

        return {
            "valid": valid,
            "gate": "P0 → P1",
            "checks": checks,
            "decision": "PROCEED" if valid else "HALT",
            "reason": "Research validated, tier acceptable" if valid else "Research or tier insufficient"
        }

    def _validate_gate_p2(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """P1 → P2: Business model sound, market validated"""
        checks = []

        if context.get("business_model_sound"):
            checks.append("✓ Business model sound")
        else:
            checks.append("✗ Business model weak")

        if context.get("market_validated"):
            checks.append("✓ Market validated")
        else:
            checks.append("✗ Market not validated")

        valid = context.get("business_model_sound") and context.get("market_validated")

        return {
            "valid": valid,
            "gate": "P1 → P2",
            "checks": checks,
            "decision": "PROCEED" if valid else "HALT"
        }

    def _validate_gate_p3(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """P2 → P3: Week 6 gate - CRITICAL (return sacred $100 decision)"""
        checks = []

        # AXIS: Business model sound
        if context.get("business_model_sound"):
            checks.append("✓ AXIS: Business model sound")
        else:
            checks.append("✗ AXIS: Business model weak")

        # BILL: No BS detected
        if not context.get("unvalidated_claims"):
            checks.append("✓ BILL: No unvalidated claims")
        else:
            checks.append("✗ BILL: Unvalidated claims exist")

        # MIDAS: ROI positive
        if context.get("revenue") and context.get("costs"):
            roi_result = self.validate_roi(context["revenue"], context["costs"])
            if roi_result["valid"]:
                checks.append(f"✓ MIDAS: ROI {roi_result['roi']:.2f}x")
            else:
                checks.append(f"✗ MIDAS: ROI {roi_result.get('roi', 0):.2f}x (need 1.5x+)")

        # GANTT: Timeline realistic
        if context.get("timeline_realistic"):
            checks.append("✓ GANTT: Timeline realistic")
        else:
            checks.append("✗ GANTT: Timeline unrealistic")

        # SENECA: Risks mitigated
        if context.get("risks_mitigated"):
            checks.append("✓ SENECA: Risks mitigated")
        else:
            checks.append("✗ SENECA: Risks not addressed")

        # Tech stack validated
        if context.get("tech_stack_validated"):
            checks.append("✓ TURING: Tech stack validated")
        else:
            checks.append("✗ TURING: Tech stack not validated")

        all_checks_passed = all("✓" in check for check in checks)

        return {
            "valid": all_checks_passed,
            "gate": "P2 → P3 (Week 6 - Sacred $100 decision)",
            "checks": checks,
            "decision": "PROCEED (return $100)" if all_checks_passed else "HALT (keep $100)",
            "reason": "All validation passed" if all_checks_passed else "Critical validation failed"
        }

    def _validate_gate_p4(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """P3 → P4: Code complete, tests passing"""
        checks = []

        if context.get("code_complete"):
            checks.append("✓ Code complete")
        else:
            checks.append("✗ Code incomplete")

        if context.get("tests_passing"):
            checks.append("✓ All tests passing")
        else:
            checks.append("✗ Tests failing")

        if context.get("deployment_ready"):
            checks.append("✓ Deployment ready")
        else:
            checks.append("✗ Deployment not ready")

        valid = all(context.get(key) for key in ["code_complete", "tests_passing", "deployment_ready"])

        return {
            "valid": valid,
            "gate": "P3 → P4",
            "checks": checks,
            "decision": "PROCEED" if valid else "HALT"
        }

    def _validate_gate_p5(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """P4 → P5: Week 10 gate - Sustainability proven"""
        checks = []

        if context.get("validation_complete"):
            checks.append("✓ Validation complete")
        else:
            checks.append("✗ Validation incomplete")

        # Check ROI from actual results
        if context.get("actual_revenue") and context.get("actual_costs"):
            roi_result = self.validate_roi(context["actual_revenue"], context["actual_costs"])
            if roi_result["valid"]:
                checks.append(f"✓ Actual ROI: {roi_result['roi']:.2f}x")
            else:
                checks.append(f"✗ Actual ROI: {roi_result.get('roi', 0):.2f}x (need 1.5x+)")

        if context.get("sustainability_proven"):
            checks.append("✓ Sustainability proven")
        else:
            checks.append("✗ Sustainability not proven")

        valid = all("✓" in check for check in checks)

        return {
            "valid": valid,
            "gate": "P4 → P5 (Week 10 - Sustainability check)",
            "checks": checks,
            "decision": "PROCEED (iterate)" if valid else "HALT (pivot or kill)",
            "reason": "Sustainable" if valid else "Not sustainable"
        }

    def validate_tech_stack(self, tech_choices: List[str]) -> Dict[str, Any]:
        """Validate tech stack choices"""
        results = []

        for tech in tech_choices:
            # Check if simpler alternative exists
            simpler = self._check_simpler_alternative(tech)
            ai_friendly = self._check_ai_friendly(tech)
            deploy_simple = self._check_deploy_simple(tech)

            result = {
                "tech": tech,
                "simpler_checked": simpler["valid"],
                "ai_friendly": ai_friendly,
                "deploy_simple": deploy_simple,
                "recommendation": "✓ Approved" if simpler["valid"] and ai_friendly and deploy_simple else "⚠ Reconsider"
            }

            if not simpler["valid"]:
                result["warning"] = simpler["alternative"]

            results.append(result)

        all_valid = all(r["recommendation"] == "✓ Approved" for r in results)

        return {
            "valid": all_valid,
            "tech_choices": results,
            "overall": "Stack approved" if all_valid else "Stack needs review"
        }

    def _check_simpler_alternative(self, tech: str) -> Dict[str, Any]:
        """Check if simpler alternative should be considered"""
        simple_choices = ["fastapi", "flask", "go", "htmx", "alpine", "tailwind", "postgres", "sqlite"]

        tech_lower = tech.lower()
        if any(simple in tech_lower for simple in simple_choices):
            return {"valid": True, "alternative": None}

        # Suggest alternatives for complex choices
        alternatives = {
            "react": "Consider HTMX + Alpine.js for simpler SSR",
            "angular": "Consider HTMX or plain JS",
            "kubernetes": "Consider Fly.io or Heroku unless 10K+ users",
            "microservices": "Start with monolith, split later",
            "mongodb": "Use PostgreSQL unless specific need validated"
        }

        for complex_tech, alt in alternatives.items():
            if complex_tech in tech_lower:
                return {"valid": False, "alternative": alt}

        return {"valid": True, "alternative": None}

    def _check_ai_friendly(self, tech: str) -> bool:
        """Check if tech is AI code generation friendly"""
        ai_unfriendly = ["react", "angular", "vue", "django"]
        tech_lower = tech.lower()
        return not any(unfriendly in tech_lower for unfriendly in ai_unfriendly)

    def _check_deploy_simple(self, tech: str) -> bool:
        """Check if tech allows single-command deploy"""
        complex_deploy = ["kubernetes", "k8s", "docker-compose"]
        tech_lower = tech.lower()
        return not any(complex in tech_lower for complex in complex_deploy)

    def _query_prolog(self, query: str) -> Optional[Dict[str, Any]]:
        """Query SWI-Prolog (if available)"""
        if not self.prolog_available:
            return None

        try:
            # Create temporary Prolog script
            script = f"""
            :- consult('{self.prolog_file}').
            :- {query}
            :- halt.
            """

            result = subprocess.run(
                ["swipl", "-g", query, "-t", "halt", str(self.prolog_file)],
                capture_output=True,
                text=True,
                timeout=5
            )

            # If query succeeds (exit code 0), validation passed
            if result.returncode == 0:
                return {"success": True}
            else:
                return None

        except (subprocess.TimeoutExpired, Exception) as e:
            print(f"Prolog query failed: {e}")
            return None

    def generate_validation_report(self, context: Dict[str, Any]) -> str:
        """Generate human-readable validation report"""
        report = ["# Validation Report\n"]

        # Financial validation
        if "revenue" in context and "costs" in context:
            roi_result = self.validate_roi(context["revenue"], context["costs"])
            report.append(f"## ROI Validation")
            report.append(f"- ROI: {roi_result.get('roi', 0):.2f}x (threshold: {roi_result['threshold']}x)")
            report.append(f"- Status: {'✓ PASS' if roi_result['valid'] else '✗ FAIL'}")
            report.append("")

        # LTV:CAC validation
        if "ltv" in context and "cac" in context:
            ltv_cac_result = self.validate_ltv_cac(context["ltv"], context["cac"])
            report.append(f"## Unit Economics Validation")
            report.append(f"- LTV:CAC: {ltv_cac_result.get('ratio', 0):.2f} (threshold: {ltv_cac_result['threshold']})")
            report.append(f"- Status: {'✓ PASS' if ltv_cac_result['valid'] else '✗ FAIL'}")
            report.append("")

        # Phase gate validation
        if "current_phase" in context:
            gate_result = self.validate_phase_gate(context["current_phase"], context)
            report.append(f"## Phase Gate: {gate_result['gate']}")
            for check in gate_result["checks"]:
                report.append(f"- {check}")
            report.append(f"- Decision: **{gate_result['decision']}**")
            report.append("")

        # Tech stack validation
        if "tech_stack" in context:
            tech_result = self.validate_tech_stack(context["tech_stack"])
            report.append(f"## Tech Stack Validation")
            for tech in tech_result["tech_choices"]:
                report.append(f"- {tech['tech']}: {tech['recommendation']}")
                if "warning" in tech:
                    report.append(f"  ⚠ {tech['warning']}")
            report.append("")

        return "\n".join(report)
