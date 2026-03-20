\c 30 200
\l lib/qi.q

.qi.use`log

\d .qs

parser:{[tag;sect;x]
  if[not count x;:()];
  a:$[b:x[0;0]=" ";((x[0]=" ")?0b)_'x;x];
  if[not count w:where all a like/:("[A-z]*";"*:");:([]tag;section:sect;body:a)];
  sections:`$-1_'s:a w;
  if[not null sect;sections:` sv'sect,'sections];
  raze .z.s'[tag;sections;1_'w _x]
  }

.qs.load:{[path]
  s:read0 p:.qi.path path;
  s@:where 0<count each s except\:" \t";
  s@:where not trim[s]like"#*";
  s:ssr[;"/";"%"]each s;
  a:enlist["[strategy]"],s;
  w:where all a like/:("[[]*";"*[]]");
  tags:`$-1_'1_'(r:w _a)[;0];
  r:raze parser[;`]'[tags;1_'r];
  r:update fills ptag from(update ptag:tag from r where tag<>`short);
  if[count select from r where null ptag;
    '"Ambiguous [short] tag, because no [strategy] or [execution] block precedes it. Use [strategy.short] or [execution.short] to clarify"];
  r:delete ptag from(update tag:` sv'(ptag,'tag)from r where tag=`short);
  vtags:TAGS,`short;
  if[count ic:select from r where not tag in vtags;
    show ic;'"Invalid tag(s) detected. Must be one of:\n  ",sv["\n  ";string vtags],"\n"];
  file:first` vs $[p like"*/*";last` vs p;p];
  if[count st:select from r where tag like"*strategy*";sv[`;`.strat,file,`manifest]set st];
  if[count ex:select from r where tag like"*execution*";sv[`;`.execution,file,`manifest]set ex];
  }