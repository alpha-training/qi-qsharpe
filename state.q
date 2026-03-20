/ Generalised script to manage signals
\d .qs

rfills:reverse fills reverse@
DROP_COLS:`enterI`entry`next_enter`next_exit_long`next_exit_short`exiting _
PNL:0w
EQUITY:1000
sizeOrder:7h$(.2*EQUITY)&.1*
pnlf:{[en;ex] PNL<=$[long;ex-en;en-ex]}
ANNUALISE_SHARPE_MIN:sqrt[6.5*60*252]*

checkRow:{[price;entry;next_enter;next_exit;x]
 j:x 0;
 entryPx:x 2;
 qty:x 3;
 position:x 4;
 note:x 5;
 if[x 1;  / if exiting
   if[null en:next_enter j;:x];
   if[en=j;if[null en:next_enter j+1;:x]];
   qty:entry en;
   :(en;0b;price en;qty;0;`)];
 newPos:position+qty;
 if[null ex:next_exit j;:x];
 if[count[pnlExits]>w1:(pnlExits:pnlf[long;entryPx;price w:j+1+til ex-j])?1b;
   :(w w1;1b;entryPx;neg newPos;newPos;`pnl)];
 (ex;1b;entryPx;neg newPos;newPos;`sig)
 }

runPerSym:{[sd;price;j;qty;next_enter;next_exit;initial_stop;r1]
  db;
  flip`I`exiting`entryPx`qty`opos`note!flip checkRow[price;qty;next_enter;next_exit]\[(j;0b;price j;qty j;0;`)]
  }

state:{[sd;a]
  a:update enter:0b from a where signal_exit;
 / a:update enter:1b,enterI:I,qty:.qs.sizeOrder close from a where enter;
  is:$[(::)~sl:first sd`stop_loss;0n;-5!last splitComparison sl];
  agg:`enter`enterI`qty`initial_stop!(1b;`I;(.qs.sizeOrder;`close);is);
  a:![a;1#`enter;byg;agg];
  a:update r1:abs close-initial_stop from a where enter;
  a:update next_enter:.qs.rfills enterI,next_exit:.qs.rfills ?[signal_exit;I;0N]by G from a;
  rs:exec .qs.runPerSym[close;enter?1b;qty;next_enter;next_exit;initial_stop;r1]by sym from a;
  dbg;
  r:DROP_COLS a lj 2!raze{[rs;s]`sym`I xcols update sym:s from rs s}[rs]each key rs;
  r:update fills entryPx,npos:fills opos+qty by sym from r;
  r:update upnl:npos*(price-entryPx)%entryPx from r where null note,npos<>0;
  r:update E:not null note from r;
  r:update trade_ret:signum[qty]*(entryPx-price)%entryPx from r where E;
  r:update rpnl:trade_ret*abs[qty]*entryPx from r where E;
  r:update equity:EQUITY+sums rpnl by sym from r;
  r:update peak:maxs equity by sym from r where E;
  r:update peakTime:time from r where E,equity=peak;
  r:update dd:0f&(equity-peak)%peak from r where E;
  r:update ddd:time-fills peakTime by sym from r;
  r:update bar_ret:{(x-a)%a:prev x}fills equity by sym from r;
  `stats set select pnl:last[equity]-first equity,min dd,max ddd,sharpe:ANNUALISE_SHARPE_MIN avg[bar_ret]%dev bar_ret by sym from r;
  delete enter_long,enter_short,exit_long,exit_short from r
 }

/\ts nbar:run r
/aa:select from nbar where sym=`AAPL