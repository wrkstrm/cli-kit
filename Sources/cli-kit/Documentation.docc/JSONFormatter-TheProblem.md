# The Problem

JSON artifacts are everywhere in our tooling: agent triads (agent/agency/agenda), audit reports, and status files. Without a shared policy, JSON formatting drifts across tools: keys reorder, URLs are escaped, and diffs get noisy. This slows down reviews, makes automation brittle, and hides meaningful changes in churn.

We needed a single, human‑friendly JSON policy that all tools can adopt, plus a simple way to normalize existing files in place or to a mirror directory for review.
