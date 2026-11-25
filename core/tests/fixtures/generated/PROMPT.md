# Author more generated sessions

Write a pair of files per case in this folder:

- `<name>.txt` — lab export lines: `<t_ms>\t<raw>`
- `<name>.expect.json` — expected motion windows

`$DFDMD` present: `$DFDMD,1,1,<distance_m>,<speed>,<energy>, , *`  
`$DFDMD` empty: `$DFDMD,0, , , , , , *`

Detector rules (do not copy live engine output):

- Lookback 3 s. Min span 1 s before Approaching or Receding.
- Newest vs oldest in the lookback: net change ≤ 15 cm is Stationary.
- Newest lower by more than 15 cm is Approaching. Higher is Receding.
- Four consecutive empty `$DFDMD` frames after a present target is Lost. Fewer empty frames coast as Stationary.

`expect.json` fields (all optional):

```json
{
  "approaching_between_ms": [1000, 1200],
  "never_approaching_before_ms": 1000,
  "never_approaching": false,
  "receding_between_ms": [1000, 1200],
  "lost_between_ms": [2000, 2100]
}
```

Times are inclusive. Prefer realistic 10 Hz sampling. Invent cases that are not already here: two-stage closes, late dropouts, vehicles, jitter plus a real close.
