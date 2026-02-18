from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Optional

from sqlalchemy import func

from app.models import UserContent


@dataclass(frozen=True)
class LocationFilterSpec:
    """Structured representation of an incoming location filter."""

    kind: str
    label: Optional[str] = None


class InvalidLocation(ValueError):
    """Raised when a provided location filter cannot be normalized."""


def _collapse_whitespace(value: str) -> str:
    return " ".join(value.strip().split())


def normalize_location_value(raw: Optional[str]) -> Optional[str]:
    if raw is None:
        return None

    collapsed = _collapse_whitespace(raw)
    return collapsed or None


def parse_location_filter(raw: Optional[str]) -> LocationFilterSpec:
    """Normalize and classify a location filter string.

    ``None`` defaults to ``Seattle (All)`` semantics to preserve the legacy
    behavior where feeds are scoped to Seattle unless explicitly expanded.
    """

    if raw is None:
        return LocationFilterSpec("seattle_all")

    normalized = normalize_location_value(raw)
    if not normalized:
        raise InvalidLocation("Location filter cannot be empty")

    lowered = normalized.lower()

    if lowered in {"seattle", "seattle (all)"}:
        return LocationFilterSpec("seattle_all")

    if lowered == "outside seattle":
        return LocationFilterSpec("outside")

    if lowered.endswith(", seattle"):
        neighborhood = normalized.rsplit(",", 1)[0].strip()
        if not neighborhood:
            return LocationFilterSpec("seattle_all")
        canonical = f"{neighborhood}, Seattle"
        return LocationFilterSpec("seattle_neighborhood", canonical)

    return LocationFilterSpec("exact", normalized)


def apply_location_filter(query, spec: Optional[LocationFilterSpec]):
    """Apply a ``LocationFilterSpec`` to a SQLAlchemy query."""

    if spec is None:
        return query

    if spec.kind == "seattle_all":
        return query.filter(UserContent.is_in_seattle.is_(True))

    if spec.kind == "outside":
        return query.filter(UserContent.is_in_seattle.is_(False))

    if spec.kind == "seattle_neighborhood" and spec.label:
        return query.filter(
            UserContent.is_in_seattle.is_(True),
            func.lower(UserContent.location) == spec.label.lower(),
        )

    if spec.kind == "exact" and spec.label:
        return query.filter(func.lower(UserContent.location) == spec.label.lower())

    return query


def display_location_value(raw_location: Optional[str], spec: LocationFilterSpec) -> str:
    normalized = normalize_location_value(raw_location) if raw_location is not None else None

    if spec.kind == "seattle_all":
        return "Seattle"
    if spec.kind == "outside":
        return "Outside Seattle"
    if getattr(spec, "label", None):
        return spec.label
    return normalized or "Seattle"


def format_post_location(content: Any) -> str:
    """Return the canonical location label for serialized output."""

    raw = None
    is_in_seattle = None

    if isinstance(content, dict):
        raw = content.get("location")
        is_in_seattle = content.get("is_in_seattle")
    else:
        raw = getattr(content, "location", None)
        is_in_seattle = getattr(content, "is_in_seattle", None)

    label = _collapse_whitespace(raw) if raw else ""

    if label:
        return label

    if bool(is_in_seattle):
        return "Seattle"

    return "Outside Seattle - Unknown Location"


__all__ = [
    "LocationFilterSpec",
    "InvalidLocation",
    "apply_location_filter",
    "display_location_value",
    "format_post_location",
    "normalize_location_value",
    "parse_location_filter",
]
