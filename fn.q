\d .qs

/ testing functions
fn.add:{x+y}
fn.add3:{x+y+z}

/ .qs.fn = functions
fn.sma:{[px;n] n mavg px}
fn.stdev:{[px;n] n mdev px}

fn.atr:{[high;low;close;n]
  tr:high-low;
  hcl:abs high-pclose:prev close;
  lcl:abs low-pclose;
  n mavg max(tr;hcl;lcl)  / TODO - change to Wilder's smoothing?
  }

/ .qs.fp = for functions with projected arguments
fp.atr:`high`low`close

{[f] fn[`$string[f],"x"]:fn f}each 1_key fp;
fn:asc[key fn]#fn;

/ .qs.fv = function valence
{[f] sv[`;`.qs.fv,f]set count[get[fn f]1]-$[(::)~p:fp f;0;count p]}each 1_key fn;