"""SchemaValidator — validate LLM outputs against JSON Schema and format rules."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field

import jsonschema


@dataclass
class ValidationResult:
    """Result of validating an LLM output against a schema or format rules."""

    is_valid: bool
    errors: list[str] = field(default_factory=list)
    missing_fields: list[str] = field(default_factory=list)
    type_errors: list[str] = field(default_factory=list)


class SchemaValidator:
    """Validate LLM output against JSON Schema and simple format rules."""

    def validate(self, output: str, schema: dict) -> ValidationResult:
        """Validate *output* (a string) against *schema* (a JSON Schema dict).

        Attempts to parse *output* as JSON first, then validates the parsed
        object against *schema* using ``jsonschema``.
        """
        # Step 1: parse JSON
        try:
            parsed = json.loads(output)
        except (json.JSONDecodeError, TypeError) as exc:
            return ValidationResult(
                is_valid=False,
                errors=[f"Output is not valid JSON: {exc}"],
            )

        # Step 2: validate against schema
        errors: list[str] = []
        missing_fields: list[str] = []
        type_errors: list[str] = []

        validator_cls = jsonschema.Draft7Validator
        validator = validator_cls(schema)
        for err in sorted(validator.iter_errors(parsed), key=lambda e: list(e.path)):
            path = ".".join(str(p) for p in err.absolute_path) if err.absolute_path else "(root)"
            msg = f"{path}: {err.message}"
            errors.append(msg)

            # Classify error
            if err.validator == "required":
                # err.message is like "'name' is a required property"
                match = re.search(r"'(.+?)'", err.message)
                if match:
                    missing_fields.append(match.group(1))
            elif err.validator == "type":
                type_errors.append(msg)

        return ValidationResult(
            is_valid=len(errors) == 0,
            errors=errors,
            missing_fields=missing_fields,
            type_errors=type_errors,
        )

    def validate_format(self, output: str, format_rules: list[str]) -> ValidationResult:
        """Validate *output* against simple format rules.

        Supported rule syntax:
        - ``word_count:min:max`` — word count must be between min and max (inclusive)
        - ``char_count:min:max`` — character count must be between min and max
        - ``contains:keyword`` — output must contain the keyword
        - ``not_contains:keyword`` — output must NOT contain the keyword
        - ``regex:pattern`` — output must match the regex pattern
        """
        errors: list[str] = []
        missing_fields: list[str] = []
        type_errors: list[str] = []

        for rule in format_rules:
            parts = rule.split(":", 2)
            rule_type = parts[0]

            if rule_type == "word_count":
                try:
                    min_words = int(parts[1])
                    max_words = int(parts[2])
                except (IndexError, ValueError):
                    errors.append(f"Invalid word_count rule: {rule}")
                    continue
                word_count = len(output.split())
                if word_count < min_words or word_count > max_words:
                    errors.append(
                        f"Word count {word_count} not in range [{min_words}, {max_words}]"
                    )

            elif rule_type == "char_count":
                try:
                    min_chars = int(parts[1])
                    max_chars = int(parts[2])
                except (IndexError, ValueError):
                    errors.append(f"Invalid char_count rule: {rule}")
                    continue
                char_count = len(output)
                if char_count < min_chars or char_count > max_chars:
                    errors.append(
                        f"Character count {char_count} not in range [{min_chars}, {max_chars}]"
                    )

            elif rule_type == "contains":
                try:
                    keyword = parts[1]
                except IndexError:
                    errors.append(f"Invalid contains rule: {rule}")
                    continue
                if keyword not in output:
                    missing_fields.append(keyword)
                    errors.append(f"Output does not contain required keyword: {keyword}")

            elif rule_type == "not_contains":
                try:
                    keyword = parts[1]
                except IndexError:
                    errors.append(f"Invalid not_contains rule: {rule}")
                    continue
                if keyword in output:
                    errors.append(f"Output contains forbidden keyword: {keyword}")

            elif rule_type == "regex":
                try:
                    pattern = parts[1]
                except IndexError:
                    errors.append(f"Invalid regex rule: {rule}")
                    continue
                if not re.search(pattern, output):
                    errors.append(f"Output does not match regex pattern: {pattern}")

            else:
                errors.append(f"Unknown format rule type: {rule_type}")

        return ValidationResult(
            is_valid=len(errors) == 0,
            errors=errors,
            missing_fields=missing_fields,
            type_errors=type_errors,
        )
