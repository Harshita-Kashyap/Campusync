# Campusync demo script (~2 min)

## Offline/demo-only run
Before: fresh app start with seeded data; airplane mode on. The water form should show that reports are local demo state and are not stored in MySQL.

1. **0:00 Problem** – "Campus waste of water, power and paper goes unnoticed because reports and data are disconnected."
2. **0:15 Student** – Student view → Report → submit a manual leaking-tap report → show the explicit local/demo confirmation → My activity shows it as *Open*.
3. **0:35 Admin** – ⇄ Switch → Admin. Overview: new item in Priority queue; note estimated litres (rate × hours).
4. **1:05 Action** – Water → tap item → *In progress* → then *Resolved*. Open count and **current** water loss drop; Activity tab logs the change. The Water page indicates these offline edits are not written to MySQL.
5. **1:25 Energy & paper** – Energy tab: actual vs expected, kWh/₹/CO₂e. Submissions: submit a file, submit it again → duplicate flagged; pages avoided rises.
6. **1:45 Close** – "SDGs 6, 7, 12, 13. Demo data and estimates, not sensor measurements — but the report → action → impact loop works."

## Connected water demo
Before: start MySQL and Flask (`backend/README.md`), confirm `/health` reports `database=connected`, and set the app API URL. Submit a photo report to demonstrate Flask/Gemini analysis and MySQL persistence; in Admin → Water, refresh, open the report, and change its repair status. If Gemini is unavailable, the response is stored as `fallback`, not labelled AI.

Fallback: if a module fails, skip it and say it is the next step.
