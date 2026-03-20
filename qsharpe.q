/ translate qsharpe files into q

.qi.import`ta
.qi.frompkg[`qsharpe;`state]

\d .qs

TAGS:`strategy`execution`strategy.short`execution.short
HEADERS:string`params`state`indicators`enter`exits.pnl_stop

\l vendor/qi/qs/qsload.q

.qi.loadcfg[`.params.ta;`:vendor/qi/ta/defaults.params]

.strat:1#.q

\d .qs

F:system"f .ta"

/ returns a boolean of where y (at any level of depth) exists in x
find:{$[(t:type x)in 0 99h;raze .z.s[;y]each x;11=abs t;except[(),y?x;count y];()]}
toagg:{last -5!"select ",sv[",";x]," from t"}
dparse:{$[type x;-5!x;.z.s each x]}each   / parse at depth
byds:{x!x}`date`sym
byg:{x!x}1#`G

processStrat:{[strat]
  lparams strat;
  m:(d:.strat strat)`manifest;
  processSection[strat]each`g xasc 0!select body,g:first i by tag,header:section from m where not null section;
  }

processSection:{[strat;x]
  if[`NO~f:@[get;` sv`.qs.ps,hr:x`header;`NO];'"Unrecognized header: ",string hr];
  sv[`;`.strat,strat,hr]set r:f[strat;x`body];
 }

ps.params:{[strat;x]
  if[count invalid:(p:`$tx:raze","vs'trim x)except 1_key params:.params strat;
    '"Unrecognized params: ",","sv string invalid];
  p#params
  }

ps.indicators:{[strat;x]parse1Definition[strat]each trim x}

psDefault:{[strat;x]parse1Expression[strat]each trim x}
psCatchall:{[strat;x] trim x}

ps.enter:psDefault
ps.exits:{(`,x)!(::),count[x]#psDefault}`pnl_stop`signal_exit`time_stop`stop_loss`pnl_stop`pnl_trailing`take_profit
ps.exit_policy:psCatchall
ps.execution:psCatchall

splitComparison:{
  b:0<count w:x ss"[^[A-z, ]";
  if[not b:x[i:w 0]in e:"<>=";'"Invalid equality comaparison"];
  b+:x[w 1]in e;
  trim(i#x;(i+b)_x)
  }

/ e.g. v1 = stdev(close, lookback) - lookback*some_val
parse1Definition:{[strat;x]
  if[not"="~x eq:not[x in .Q.an," "]?1b;'"Indicator definition should be of the form: variable = expression. Instead it is: ",x];
  k:trim eq#x;
  v:parse1Expression[strat]trim(1+eq)_x;
  k,":",v
  }

findWord:{x ss/:{a,x,a:"[^A-z,_,0-9]"}each y}

/ e.g. stdev(close, lookback) - lookback*some_val
parse1Expression:{[strat;x]
  if[count x ss"==";'"Use a single = to check for equality: ",x];
  s:a,x,a:"\001";
  p:1_key pd:.params strat;
  if[count pm:ungroup([]p;loc:1+findWord[s;string p]);
    pm:update n:count each string p from`loc xasc pm;
    a:pm[`loc]_s;
    s:(first[pm`loc]#s),raze{[pd;x;y] .qi.tostr[pd y`p],y[`n]_x}[pd]'[a;pm]];
  s:ssr[s;"--";""];   / TODO - bit hacky
  m:ungroup([]func:F;loc:findWord[s;string F]);
  replaces:parse1Function[s]each m;
  1_-1_s{ssr[x;y 0;y 1]}/replaces
 }

parse1Function:{
  s:(1+i:y`loc)_x;
  sf:string f:y`func;
  fv:.ta.u.fv f;
  if[(::)~proj:.ta.proj y`func;proj:()];
  if[not(b~asc b)&2=count b:distinct s?"()";'sf," is a reserved function in the .ta namespace. Either choose another variable name or call the function with round brackets"];
  if[";"in as:1_first b _s;'"qs arguments should be separated by , not ; (",as,")"];
  args:`$trim","vs as;
  if[fv<>an:count args;
    'sf," expects ",string[fv]," arguments, not ",string[an],": ",(1+s?")")#s];
  if[not(::)~proj:.ta.proj y`func;args:proj,args];
  frm:(1+b 1)#s;
  to:".ta.",sf,"[",sv[";";string args],"]";
  (frm;to)
  }

{
  if[ok:0<count .z.x;
    if[ok:0<count s:.qi.opts`strats;
      ok:0<count STRATS::`$","vs trim s]];
  if[not ok;
    -1"Usage q qs.q -strats [mr1,mr2...]";exit 1];
  }[];

/ load params
lparams:{[strat]
  -1 "Loading params for ",.qi.tostr strat;
  ns:` sv`.params,strat;
  pd:`:strategies/params;
  .qi.loadcfg[ns;` sv pd,`defaults.params];
  if[.qi.exists f:.qi.path pd,.qi.ext[strat;".params"];
    .qi.loadcfg[ns;f]];
 }

/ ---- testing section  ---

run:{[t;d;s;strat]
  sd:.strat strat;
  if[`exits in key sd;sd,:1_sd`exits];
  fdate:$[2<>count d;in;d[0]<d 1;within;in];
  a:select from t where fdate[date;d],sym in s;
  a:update`g#G,`g#I from(update G:first i,I:-1+sums i=i by date,sym from a);
  d:toagg sd`indicators;
  od:group iasc[od]#od:find[;key d]each d;
  a:{![y;();byg;z#x]}[d]/[a;od];
  a:delete date,transactions from{![y;dparse x z;byg;(1#z)!1#1b]}[sd]/[a;key[sd]inter`enter`signal_exit];
  state[sd;a]
  }

.qs.load each STRATS;
processStrat each 1_key .strat;

\d .

{if[count data:getenv`QSDATA;
  system"l ",data;
  r::.qs.run[`bar1m;last date;`AAPL`JPM;`mr1]]}[]

system"l /Users/kieran/code/qis/qtrader-dev/vendor/qi/qs/state.q"

/

STRATEGY IMPLEMENTATION SPECIFICATIONS - EXECUTION & PNL DERIVATION

STATIC ANCHOR FIELDS Captured once at the bar of entry (t_entry) and persisted as constants for the life of the position.
- entry_px: The execution price derived from exec_profiles.csv (adjusted for spread_factor and impact_bps).
- initial_stop_px: The evaluated result of the formula (mid - (atr1 * atr_mult)) at t_entry.
- r1 (1R): The absolute distance between entry and the initial stop. Formula: abs(entry_px - initial_stop_px). Note: This serves as the denominator for all relative PnL triggers (PnL-to-Risk).

FLOATING PNL FIELDS Calculated at every bar (t >= t_entry) to evaluate exit conditions.
- upnl: Unrealized PnL per unit. Formula: (current_price - entry_px) * side.
- upnl_r: Unrealized PnL normalized to Risk units. Formula: upnl / r1.
- mfe_r: Maximum Favorable Excursion in R-units. Logic: maxs(upnl_r) - the running maximum of upnl_r since entry.
- giveback_r: The current retracement from the trade peak in R-units. Formula: mfe_r - upnl_r.

EXECUTION PROFILE RESOLUTION Rules for mapping DSL urgency values to the urgency.csv parameters.
- Label Mapping: If urgency is a string (e.g., "aggressive"), perform a direct lookup in urgency.csv.
- Linear Interpolation: If urgency is a float (e.g., 0.4), linearly interpolate values for spread_factor and impact_bps using the nearest bounding keys in the CSV.
- Integer Rounding: Round offset_bars to the nearest integer.
Friction Summation: Total transaction friction = base_slippage (from DSL) + impact_bps (from CSV).

EXIT TRIGGER EVALUATION (FIRST_HIT MODE) At each bar, evaluate all boolean conditions and exit on the first true result.
- signal_exit: zscore > -z_exit
- stop_loss (Dynamic): close < (mid - (atr1 * atr_mult)) -- Re-calculate formula at every bar.
- pnl_stop: (-upnl_r) >= max_loss_r
- pnl_trailing: (mfe_r >= trail_activate_r) AND (giveback_r >= trail_giveback_r)
- take_profit: upnl_r >= tp_r_mult
- time_stop: (current_bar_index - entry_bar_index) > max_hold_bars