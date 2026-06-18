# Estimation Methods

## Contents
- T-shirt sizing guide
- Story points with Fibonacci
- Three-point estimation
- Velocity and capacity planning
- Communicating estimates to stakeholders

## T-Shirt Sizing

Best for: roadmap planning, early-stage scoping, large backlogs (50+ items).

| Size | Relative Effort | Typical Duration | Uncertainty |
|------|----------------|-----------------|-------------|
| XS | Trivial | Hours | Very low |
| S | Simple, well-understood | 1-2 days | Low |
| M | Moderate complexity | 3-5 days | Medium |
| L | Complex, some unknowns | 1-2 weeks | High |
| XL | Very complex, significant unknowns | 2-4 weeks | Very high — break it down |

**Process:**
1. Pick 3-5 reference items the team already understands well. Place them on the scale.
2. For each new item, discuss briefly: "Is this bigger or smaller than reference X?"
3. Place it on the scale. If there's disagreement, discuss briefly and converge.
4. Any XL item should be broken into smaller items before sprint planning.

**Converting to time for roadmap purposes:**
```
XS: 0.5 days    S: 2 days    M: 5 days    L: 10 days    XL: 20 days
Sum all items × buffer (1.3-1.5) = rough project duration
```

## Story Points (Fibonacci)

Best for: sprint planning, velocity tracking with mature agile teams.

Scale: 1, 2, 3, 5, 8, 13, 21

| Points | Meaning |
|--------|---------|
| 1 | Trivial — clear, no unknowns, done in minutes to an hour |
| 2 | Small — straightforward, few unknowns |
| 3 | Small-medium — some complexity or one minor unknown |
| 5 | Medium — moderate complexity, some unknowns |
| 8 | Large — significant complexity, multiple unknowns |
| 13 | Very large — high complexity, should consider splitting |
| 21 | Epic — too large for a single sprint, must be broken down |

**Planning Poker process:**
1. Product owner describes the story and acceptance criteria
2. Each team member privately selects a card (Fibonacci number)
3. All cards revealed simultaneously
4. If consensus: record and move on
5. If divergence: highest and lowest explain their reasoning, then re-vote
6. Converge within 2 rounds (don't debate endlessly)

**Calculating velocity:**
```
Sprint 1: 28 points completed
Sprint 2: 32 points completed
Sprint 3: 25 points completed
Sprint 4: 30 points completed

Average velocity: (28 + 32 + 25 + 30) / 4 = 28.75 ≈ 29 points/sprint
Use the last 3-5 sprints (not all-time) for more accurate forecasting
```

## Three-Point Estimation

Best for: budget estimates, high-stakes commitments, uncertain work.

For each task, estimate three values:
- **O** (Optimistic): Everything goes right, no surprises
- **M** (Most Likely): Normal conditions, typical obstacles
- **P** (Pessimistic): Significant problems but not catastrophic

**PERT formula:**
```
Expected = (O + 4M + P) / 6
Standard Deviation = (P - O) / 6
```

**Example:**
```
Task: Integrate payment provider
  O: 3 days (API is clean, docs are accurate)
  M: 7 days (some undocumented behavior, 1-2 issues)
  P: 15 days (API issues, need vendor support, edge cases)

  Expected: (3 + 4×7 + 15) / 6 = 46/6 = 7.7 days
  StdDev: (15 - 3) / 6 = 2 days

  68% confidence: 5.7 - 9.7 days
  95% confidence: 3.7 - 11.7 days

  Communicate: "Roughly 8 days, could range from 6-12."
```

**For full project estimates**, sum the expected values and sum the variances (not standard deviations):
```
Total Expected = sum of all task expected values
Total Variance = sum of all task variances
Total StdDev = sqrt(Total Variance)
```

## Velocity and Capacity Planning

### Sprint capacity
```
Team size: 5 engineers
Sprint length: 2 weeks (10 working days)
Availability: 80% (account for meetings, PTO, on-call, interruptions)

Gross capacity: 5 × 10 = 50 person-days
Net capacity: 50 × 0.8 = 40 person-days

If average velocity is 29 story points per sprint:
  1 story point ≈ 40/29 ≈ 1.4 person-days (for rough conversion only)
```

### Forecasting project completion
```
Total remaining story points: 120
Average velocity: 29 points/sprint
Sprints remaining: 120 / 29 = 4.1 sprints

Optimistic (velocity = 35): 120 / 35 = 3.4 sprints
Pessimistic (velocity = 23): 120 / 23 = 5.2 sprints

Communicate: "4-5 sprints (8-10 weeks), assuming current team and no major scope changes"
```

## Communicating Estimates to Stakeholders

### Do:
- Provide ranges, not single numbers
- State assumptions explicitly ("assumes the team of 4, no major scope changes")
- Update estimates when assumptions change
- Use visual aids (burndown charts, probability cones)
- Distinguish between effort (person-days) and duration (calendar time)

### Don't:
- Convert story points to hours for external communication (this invites micromanagement)
- Present estimates as commitments
- Pad estimates secretly (be transparent about buffers)
- Estimate work you don't understand (do a spike first)
- Let someone else's deadline become your estimate ("we need it by Friday" is not an estimate)

### Useful phrasing:
- "Based on what we know today, this is roughly X-Y weeks of work for a team of N."
- "We'll have a more precise estimate after the technical spike in sprint 1."
- "The main uncertainty is [specific unknown]. If that goes smoothly, it's X weeks. If not, it could be Y weeks."
- "We can commit to delivering [core scope] by [date]. The [stretch goals] depend on how the first sprint goes."
