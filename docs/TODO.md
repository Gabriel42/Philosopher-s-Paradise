# TODO

## Now
- [ ] Write the pitch and the movement section of `design.md`
- [ ] Enemies: small red capsules that appear ahead, match the runner's speed and try to intercept it; many at once (cheap); F3 debug panel counting touches

## Next
- [ ] First runner: a third-person character that runs, jumps and fast-falls, with its numbers in a Movement resource
- [ ] Slopes: gain speed going down, lose it going up; landing well keeps speed
- [ ] Follow camera (mouse look, pulls back with speed)
- [ ] A first blocked-out test level (CSG)

## Later
Ideas and philosophies (see `design.md`), one session each, in order:
- [ ] Data: `Idea` resource (tags: color, school, stance; what it gives), `PhilosophyRule` (condition + what it takes) and `Philosophy` (ordered rules, slot count) resources, as `.tres`
- [ ] Content: the 10 attacks as tagged ideas, a few passive ideas (stats, movement), and the ideas about the philosophy (more rules, better options, more idea rewards)
- [ ] Picker: pure, seeded `IdeaPicker` (candidates + philosophy + run state → idea + the reason why), with tests
- [ ] Several attacks at once in the run; idea rewards (placeholder trigger); F3 panel shows each pick and the rule that made it; mouse-wheel swap kept as a testing mode
- [ ] Checkpoints in the run (pause the run)
- [ ] Checkpoint report screen: every pick since the last checkpoint, with candidates, the rule that took it and why the rules above didn't match
- [ ] Checkpoint philosophy editor: add / remove / reorder / toggle rules within the slots and options unlocked

## Ideas

## Bugs
