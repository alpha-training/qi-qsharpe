kind: solo

params:
  bb_n, bb_sd, atr_n, atr_mult

indicators:
  bb  = bbands(close, bb_n, bb_sd, bb_sd, 0)
  vol = atr(atr_n)
  
  is_oversold = close < bb.lower
  vol_filter  = vol > sma(vol, 50) 

enter:
  is_oversold
  vol_filter

exits:
  stop_loss:
    price: entry_price - (vol * atr_mult)
  
  take_profit:
    price: bb.mid

  stale_exit:
    bars_since_entry > 30
    upnl_r <= 0.5