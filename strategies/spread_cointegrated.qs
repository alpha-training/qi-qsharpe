kind: spread

params:
  lookback, entry_z, exit_z

state:
  # Calculate rolling hedge ratio
  beta = lin_reg_slope(leg1.close, leg2.close, lookback)
  
  # Residual calculation: L1 - (beta * L2)
  actual_spread = leg1.close - (beta * leg2.close)

indicators:
  # Standard stats on the residual
  m = sma(actual_spread, lookback)
  s = stdev(actual_spread, lookback)
  zscore = (actual_spread - m) / s

enter:
  long_spread:  zscore < -entry_z
  short_spread: zscore > entry_z

exits:
  target:
    long_exit:  zscore >= -exit_z
    short_exit: zscore <= exit_z

execution:
  type: multi_leg
  weights: [1, -beta]