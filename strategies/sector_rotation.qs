kind: panel

params:
  rsi_n, top_n

indicators:
  # Implicitly calls .ta.rsi for every ticker in the panel
  rsi_val = rsi(close, rsi_n)
  
  # Cross-sectional rank relative to the group
  relative_rank = rank(rsi_val) / count(universe)

enter:
  # Mean Reversion Factor: Buy the relative laggards
  relative_rank < 0.10

exits:
  # Exit when no longer in the bottom 30%
  laggard_exit:
    relative_rank > 0.30

execution:
  rebalance: weekly
  mode: weight_to_target
  target_weight: 1.0 / params.top_n