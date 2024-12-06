/*!
  Highlight.js v11.7.0 (git: 82688fad18)
  (c) 2006-2022 undefined and other contributors
  License: BSD-3-Clause
 */
var hljs=function(){"use strict";var e={exports:{}};function t(e){
return e instanceof Map?e.clear=e.delete=e.set=function (){
throw Error("map is read-only")}:e instanceof Set&&(e.add=e.clear=e.delete=function (){
throw Error("set is read-only")
}),Object.freeze(e),Object.getOwnPropertyNames(e).forEach((function (n){var i=e[n]
;"object"!=typeof i||Object.isFrozen(i)||t(i)})),e}
e.exports=t,e.exports.default=t;var n = function n(e){
void 0===e.data&&(e.data={}),this.data=e.data,this.isMatchIgnored=!1};
n.prototype.ignoreMatch = function ignoreMatch (){this.isMatchIgnored=!0};function i(e){
return e.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#x27;")
}function r(e){
var t = [], len = arguments.length - 1;
while ( len-- > 0 ) t[ len ] = arguments[ len + 1 ];
var n=Object.create(null);for(var t$1 in e){ n[t$1]=e[t$1]
; }return t.forEach((function (e){for(var t in e){ n[t]=e[t] }})),n}
var s=function (e){ return !!e.scope||e.sublanguage&&e.language; };var o = function o(e,t){
this.buffer="",this.classPrefix=t.classPrefix,e.walk(this)};o.prototype.addText = function addText (e){
this.buffer+=i(e)};o.prototype.openNode = function openNode (e){if(!s(e)){ return; }var t=""
;t=e.sublanguage?"language-"+e.language:(function (e,ref){
var t = ref.prefix;
if(e.includes(".")){
var n=e.split(".")
;return[("" + t + (n.shift())) ].concat( n.map((function (e,t){ return ("" + e + ("_".repeat(t+1))); }))).join(" ")
}return("" + t + e)})(e.scope,{prefix:this.classPrefix}),this.span(t)};
o.prototype.closeNode = function closeNode (e){s(e)&&(this.buffer+="</span>")};o.prototype.value = function value (){return this.buffer};o.prototype.span = function span (e){
this.buffer+="<span class=\"" + e + "\">"};var a=function (e){
if ( e === void 0 ) e={};
var t={children:[]}
;return Object.assign(t,e),t};var c = function c(){
this.rootNode=a(),this.stack=[this.rootNode]};

var prototypeAccessors = { top: { configurable: true },root: { configurable: true } };prototypeAccessors.top.get = function (){
return this.stack[this.stack.length-1]};prototypeAccessors.root.get = function (){return this.rootNode};c.prototype.add = function add (e){
this.top.children.push(e)};c.prototype.openNode = function openNode (e){var t=a({scope:e})
;this.add(t),this.stack.push(t)};c.prototype.closeNode = function closeNode (){
if(this.stack.length>1){ return this.stack.pop() }};c.prototype.closeAllNodes = function closeAllNodes (){
for(;this.closeNode();){ ; }};c.prototype.toJSON = function toJSON (){return JSON.stringify(this.rootNode,null,4)};
c.prototype.walk = function walk (e){return this.constructor._walk(e,this.rootNode)};c._walk = function _walk (e,t){
var this$1 = this;

return"string"==typeof t?e.addText(t):t.children&&(e.openNode(t),
t.children.forEach((function (t){ return this$1._walk(e,t); })),e.closeNode(t)),e};c._collapse = function _collapse (e){
"string"!=typeof e&&e.children&&(e.children.every((function (e){ return "string"==typeof e; }))?e.children=[e.children.join("")]:e.children.forEach((function (e){
c._collapse(e)})))};

Object.defineProperties( c.prototype, prototypeAccessors );var l = /*@__PURE__*/(function (c) {
  function l(e){c.call(this),this.options=e}

  if ( c ) l.__proto__ = c;
  l.prototype = Object.create( c && c.prototype );
  l.prototype.constructor = l;
l.prototype.addKeyword = function addKeyword (e,t){""!==e&&(this.openNode(t),this.addText(e),this.closeNode())};
l.prototype.addText = function addText (e){""!==e&&this.add(e)};l.prototype.addSublanguage = function addSublanguage (e,t){var n=e.root
;n.sublanguage=!0,n.language=t,this.add(n)};l.prototype.toHTML = function toHTML (){
return new o(this,this.options).value()};l.prototype.finalize = function finalize (){return!0};

  return l;
}(c));function g(e){
return e?"string"==typeof e?e:e.source:null}function d(e){return p("(?=",e,")")}
function u(e){return p("(?:",e,")*")}function h(e){return p("(?:",e,")?")}
function p(){
var e = [], len = arguments.length;
while ( len-- ) e[ len ] = arguments[ len ];
return e.map((function (e){ return g(e); })).join("")}function f(){
var e = [], len = arguments.length;
while ( len-- ) e[ len ] = arguments[ len ];
var t=(function (e){
var t=e[e.length-1]
;return"object"==typeof t&&t.constructor===Object?(e.splice(e.length-1,1),t):{}
})(e);return"("+(t.capture?"":"?:")+e.map((function (e){ return g(e); })).join("|")+")"}
function b(e){return RegExp(e.toString()+"|").exec("").length-1}
var m=/\[(?:[^\\\]]|\\.)*\]|\(\??|\\([1-9][0-9]*)|\\./
;function E(e,ref){
var t = ref.joinWith;
var n=0;return e.map((function (e){n+=1;var t=n
;var i=g(e),r="";for(;i.length>0;){var e$1=m.exec(i);if(!e$1){r+=i;break}
r+=i.substring(0,e$1.index),
i=i.substring(e$1.index+e$1[0].length),"\\"===e$1[0][0]&&e$1[1]?r+="\\"+(Number(e$1[1])+t):(r+=e$1[0],
"("===e$1[0]&&n++)}return r})).map((function (e){ return ("(" + e + ")"); })).join(t)}
var x="[a-zA-Z]\\w*",w="[a-zA-Z_]\\w*",y="\\b\\d+(\\.\\d+)?",_="(-?)(\\b0[xX][a-fA-F0-9]+|(\\b\\d+(\\.\\d*)?|\\.\\d+)([eE][-+]?\\d+)?)",O="\\b(0b[01]+)",v={
begin:"\\\\[\\s\\S]",relevance:0},N={scope:"string",begin:"'",end:"'",
illegal:"\\n",contains:[v]},k={scope:"string",begin:'"',end:'"',illegal:"\\n",
contains:[v]},M=function (e,t,n){
if ( n === void 0 ) n={};
var i=r({scope:"comment",begin:e,end:t,
contains:[]},n);i.contains.push({scope:"doctag",
begin:"[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)",
end:/(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):/,excludeBegin:!0,relevance:0})
;var s=f("I","a","is","so","us","to","at","if","in","it","on",/[A-Za-z]+['](d|ve|re|ll|t|s|n)/,/[A-Za-z]+[-][a-z]+/,/[A-Za-z][a-z]{2,}/)
;return i.contains.push({begin:p(/[ ]+/,"(",s,/[.]?[:]?([.][ ]|[ ])/,"){3}")}),i
},S=M("//","$"),R=M("/\\*","\\*/"),j=M("#","$");var A=Object.freeze({
__proto__:null,MATCH_NOTHING_RE:/\b\B/,IDENT_RE:x,UNDERSCORE_IDENT_RE:w,
NUMBER_RE:y,C_NUMBER_RE:_,BINARY_NUMBER_RE:O,
RE_STARTERS_RE:"!|!=|!==|%|%=|&|&&|&=|\\*|\\*=|\\+|\\+=|,|-|-=|/=|/|:|;|<<|<<=|<=|<|===|==|=|>>>=|>>=|>=|>>>|>>|>|\\?|\\[|\\{|\\(|\\^|\\^=|\\||\\|=|\\|\\||~",
SHEBANG:function (e){
if ( e === void 0 ) e={};
var t=/^#![ ]*\//
;return e.binary&&(e.begin=p(t,/.*\b/,e.binary,/\b.*/)),r({scope:"meta",begin:t,
end:/$/,relevance:0,"on:begin":function (e,t){0!==e.index&&t.ignoreMatch()}},e)},
BACKSLASH_ESCAPE:v,APOS_STRING_MODE:N,QUOTE_STRING_MODE:k,PHRASAL_WORDS_MODE:{
begin:/\b(a|an|the|are|I'm|isn't|don't|doesn't|won't|but|just|should|pretty|simply|enough|gonna|going|wtf|so|such|will|you|your|they|like|more)\b/
},COMMENT:M,C_LINE_COMMENT_MODE:S,C_BLOCK_COMMENT_MODE:R,HASH_COMMENT_MODE:j,
NUMBER_MODE:{scope:"number",begin:y,relevance:0},C_NUMBER_MODE:{scope:"number",
begin:_,relevance:0},BINARY_NUMBER_MODE:{scope:"number",begin:O,relevance:0},
REGEXP_MODE:{begin:/(?=\/[^/\n]*\/)/,contains:[{scope:"regexp",begin:/\//,
end:/\/[gimuy]*/,illegal:/\n/,contains:[v,{begin:/\[/,end:/\]/,relevance:0,
contains:[v]}]}]},TITLE_MODE:{scope:"title",begin:x,relevance:0},
UNDERSCORE_TITLE_MODE:{scope:"title",begin:w,relevance:0},METHOD_GUARD:{
begin:"\\.\\s*[a-zA-Z_]\\w*",relevance:0},END_SAME_AS_BEGIN:function (e){ return Object.assign(e,{
"on:begin":function (e,t){t.data._beginMatch=e[1]},"on:end":function (e,t){
t.data._beginMatch!==e[1]&&t.ignoreMatch()}}); }});function I(e,t){
"."===e.input[e.index-1]&&t.ignoreMatch()}function T(e,t){
void 0!==e.className&&(e.scope=e.className,delete e.className)}function L(e,t){
t&&e.beginKeywords&&(e.begin="\\b("+e.beginKeywords.split(" ").join("|")+")(?!\\.)(?=\\b|\\s)",
e.__beforeBegin=I,e.keywords=e.keywords||e.beginKeywords,delete e.beginKeywords,
void 0===e.relevance&&(e.relevance=0))}function B(e,t){
Array.isArray(e.illegal)&&(e.illegal=f.apply(void 0, e.illegal))}function D(e,t){
if(e.match){
if(e.begin||e.end){ throw Error("begin & end are not supported with match")
; }e.begin=e.match,delete e.match}}function H(e,t){
void 0===e.relevance&&(e.relevance=1)}var P=function (e,t){if(!e.beforeMatch){ return
; }if(e.starts){ throw Error("beforeMatch cannot be used with starts")
; }var n=Object.assign({},e);Object.keys(e).forEach((function (t){delete e[t]
})),e.keywords=n.keywords,e.begin=p(n.beforeMatch,d(n.begin)),e.starts={
relevance:0,contains:[Object.assign(n,{endsParent:!0})]
},e.relevance=0,delete n.beforeMatch
},C=["of","and","for","in","not","or","if","then","parent","list","value"]
;function $(e,t,n){
if ( n === void 0 ) n="keyword";
var i=Object.create(null)
;return"string"==typeof e?r(n,e.split(" ")):Array.isArray(e)?r(n,e):Object.keys(e).forEach((function (n){
Object.assign(i,$(e[n],t,n))})),i;function r(e,n){
t&&(n=n.map((function (e){ return e.toLowerCase(); }))),n.forEach((function (t){var n=t.split("|")
;i[n[0]]=[e,U(n[0],n[1])]}))}}function U(e,t){
return t?Number(t):(function (e){ return C.includes(e.toLowerCase()); })(e)?0:1}var z={},K=function (e){
console.error(e)},W=function (e){
var t = [], len = arguments.length - 1;
while ( len-- > 0 ) t[ len ] = arguments[ len + 1 ];
console.log.apply(console, [ "WARN: "+e ].concat( t ))},X=function (e,t){
z[(e + "/" + t)]||(console.log(("Deprecated as of " + e + ". " + t)),z[(e + "/" + t)]=!0)
},G=Error();function Z(e,t,ref){
var n = ref.key;
var i=0;var r=e[n],s={},o={}
;for(var e$1=1;e$1<=t.length;e$1++){ o[e$1+i]=r[e$1],s[e$1+i]=!0,i+=b(t[e$1-1])
; }e[n]=o,e[n]._emit=s,e[n]._multi=!0}function F(e){(function (e){
e.scope&&"object"==typeof e.scope&&null!==e.scope&&(e.beginScope=e.scope,
delete e.scope)})(e),"string"==typeof e.beginScope&&(e.beginScope={
_wrap:e.beginScope}),"string"==typeof e.endScope&&(e.endScope={_wrap:e.endScope
}),(function (e){if(Array.isArray(e.begin)){
if(e.skip||e.excludeBegin||e.returnBegin){ throw K("skip, excludeBegin, returnBegin not compatible with beginScope: {}"),
G
; }if("object"!=typeof e.beginScope||null===e.beginScope){ throw K("beginScope must be object"),
G; }Z(e,e.begin,{key:"beginScope"}),e.begin=E(e.begin,{joinWith:""})}})(e),(function (e){
if(Array.isArray(e.end)){
if(e.skip||e.excludeEnd||e.returnEnd){ throw K("skip, excludeEnd, returnEnd not compatible with endScope: {}"),
G
; }if("object"!=typeof e.endScope||null===e.endScope){ throw K("endScope must be object"),
G; }Z(e,e.end,{key:"endScope"}),e.end=E(e.end,{joinWith:""})}})(e)}function V(e){
function t(t,n){
return RegExp(g(t),"m"+(e.case_insensitive?"i":"")+(e.unicodeRegex?"u":"")+(n?"g":""))
}var n = function n(){
this.matchIndexes={},this.regexes=[],this.matchAt=1,this.position=0};
n.prototype.addRule = function addRule (e,t){
t.position=this.position++,this.matchIndexes[this.matchAt]=t,this.regexes.push([t,e]),
this.matchAt+=b(e)+1};n.prototype.compile = function compile (){0===this.regexes.length&&(this.exec=function (){ return null; })
;var e=this.regexes.map((function (e){ return e[1]; }));this.matcherRe=t(E(e,{joinWith:"|"
}),!0),this.lastIndex=0};n.prototype.exec = function exec (e){this.matcherRe.lastIndex=this.lastIndex
;var t=this.matcherRe.exec(e);if(!t){ return null
; }var n=t.findIndex((function (e,t){ return t>0&&void 0!==e; })),i=this.matchIndexes[n]
;return t.splice(0,n),Object.assign(t,i)};var i = function i(){
this.rules=[],this.multiRegexes=[],
this.count=0,this.lastIndex=0,this.regexIndex=0};i.prototype.getMatcher = function getMatcher (e){
if(this.multiRegexes[e]){ return this.multiRegexes[e]; }var t=new n
;return this.rules.slice(e).forEach((function (ref){
  var e = ref[0];
  var n = ref[1];

  return t.addRule(e,n);
})),
t.compile(),this.multiRegexes[e]=t,t};i.prototype.resumingScanAtSamePosition = function resumingScanAtSamePosition (){
return 0!==this.regexIndex};i.prototype.considerAll = function considerAll (){this.regexIndex=0};i.prototype.addRule = function addRule (e,t){
this.rules.push([e,t]),"begin"===t.type&&this.count++};i.prototype.exec = function exec (e){
var t=this.getMatcher(this.regexIndex);t.lastIndex=this.lastIndex
;var n=t.exec(e)
;if(this.resumingScanAtSamePosition()){ if(n&&n.index===this.lastIndex){ ; }else{
var t$1=this.getMatcher(0);t$1.lastIndex=this.lastIndex+1,n=t$1.exec(e)} }
return n&&(this.regexIndex+=n.position+1,
this.regexIndex===this.count&&this.considerAll()),n};
if(e.compilerExtensions||(e.compilerExtensions=[]),
e.contains&&e.contains.includes("self")){ throw Error("ERR: contains `self` is not supported at the top-level of a language.  See documentation.")
; }return e.classNameAliases=r(e.classNameAliases||{}),function n(s,o){
var ref;
var a=s
;if(s.isCompiled){ return a
; }[T,D,F,P].forEach((function (e){ return e(s,o); })),e.compilerExtensions.forEach((function (e){ return e(s,o); })),
s.__beforeBegin=null,[L,B,H].forEach((function (e){ return e(s,o); })),s.isCompiled=!0;var c=null
;return"object"==typeof s.keywords&&s.keywords.$pattern&&(s.keywords=Object.assign({},s.keywords),
c=s.keywords.$pattern,
delete s.keywords.$pattern),c=c||/\w+/,s.keywords&&(s.keywords=$(s.keywords,e.case_insensitive)),
a.keywordPatternRe=t(c,!0),
o&&(s.begin||(s.begin=/\B|\b/),a.beginRe=t(a.begin),s.end||s.endsWithParent||(s.end=/\B|\b/),
s.end&&(a.endRe=t(a.end)),
a.terminatorEnd=g(a.end)||"",s.endsWithParent&&o.terminatorEnd&&(a.terminatorEnd+=(s.end?"|":"")+o.terminatorEnd)),
s.illegal&&(a.illegalRe=t(s.illegal)),
s.contains||(s.contains=[]),s.contains=(ref = []).concat.apply(ref, s.contains.map((function (e){ return (function (e){ return (e.variants&&!e.cachedVariants&&(e.cachedVariants=e.variants.map((function (t){ return r(e,{
variants:null},t); }))),e.cachedVariants?e.cachedVariants:q(e)?r(e,{
starts:e.starts?r(e.starts):null
}):Object.isFrozen(e)?r(e):e); })("self"===e?s:e); }))),s.contains.forEach((function (e){n(e,a)
})),s.starts&&n(s.starts,o),a.matcher=(function (e){var t=new i
;return e.contains.forEach((function (e){ return t.addRule(e.begin,{rule:e,type:"begin"
}); })),e.terminatorEnd&&t.addRule(e.terminatorEnd,{type:"end"
}),e.illegal&&t.addRule(e.illegal,{type:"illegal"}),t})(a),a}(e)}function q(e){
return!!e&&(e.endsWithParent||q(e.starts))}var J = /*@__PURE__*/(function (Error) {
  function J(e,t){Error.call(this, e),this.name="HTMLInjectionError",this.html=t}

  if ( Error ) J.__proto__ = Error;
  J.prototype = Object.create( Error && Error.prototype );
  J.prototype.constructor = J;

  return J;
}(Error));
var Y=i,Q=r,ee=Symbol("nomatch");var te=(function (t){
var i=Object.create(null),r=Object.create(null),s=[];var o=!0
;var a="Could not find the language '{}', did you forget to load/include a language module?",c={
disableAutodetect:!0,name:"Plain text",contains:[]};var g={
ignoreUnescapedHTML:!1,throwUnescapedHTML:!1,noHighlightRe:/^(no-?highlight)$/i,
languageDetectRe:/\blang(?:uage)?-([\w-]+)\b/i,classPrefix:"hljs-",
cssSelector:"pre code",languages:null,__emitter:l};function b(e){
return g.noHighlightRe.test(e)}function m(e,t,n){var i="",r=""
;"object"==typeof t?(i=e,
n=t.ignoreIllegals,r=t.language):(X("10.7.0","highlight(lang, code, ...args) has been deprecated."),
X("10.7.0","Please use highlight(code, options) instead.\nhttps://github.com/highlightjs/highlight.js/issues/2277"),
r=e,i=t),void 0===n&&(n=!0);var s={code:i,language:r};k("before:highlight",s)
;var o=s.result?s.result:E(s.language,s.code,n)
;return o.code=s.code,k("after:highlight",o),o}function E(e,t,r,s){
var c=Object.create(null);function l(){if(!N.keywords){ return void M.addText(S)
; }var e=0;N.keywordPatternRe.lastIndex=0;var t=N.keywordPatternRe.exec(S),n=""
;for(;t;){n+=S.substring(e,t.index)
;var r=y.case_insensitive?t[0].toLowerCase():t[0],s=(i=r,N.keywords[i]);if(s){
var e$1 = s[0];
var i$1 = s[1];if(M.addText(n),n="",c[r]=(c[r]||0)+1,c[r]<=7&&(R+=i$1),e$1.startsWith("_")){ n+=t[0]; }else{
var n$1=y.classNameAliases[e$1]||e$1;M.addKeyword(t[0],n$1)}}else { n+=t[0]
; }e=N.keywordPatternRe.lastIndex,t=N.keywordPatternRe.exec(S)}var i
;n+=S.substring(e),M.addText(n)}function d(){null!=N.subLanguage?(function (){
if(""===S){ return; }var e=null;if("string"==typeof N.subLanguage){
if(!i[N.subLanguage]){ return void M.addText(S)
; }e=E(N.subLanguage,S,!0,k[N.subLanguage]),k[N.subLanguage]=e._top
}else { e=x(S,N.subLanguage.length?N.subLanguage:null)
; }N.relevance>0&&(R+=e.relevance),M.addSublanguage(e._emitter,e.language)
})():l(),S=""}function u(e,t){var n=1;var i=t.length-1;for(;n<=i;){
if(!e._emit[n]){n++;continue}var i$1=y.classNameAliases[e[n]]||e[n],r=t[n]
;i$1?M.addKeyword(r,i$1):(S=r,l(),S=""),n++}}function h(e,t){
return e.scope&&"string"==typeof e.scope&&M.openNode(y.classNameAliases[e.scope]||e.scope),
e.beginScope&&(e.beginScope._wrap?(M.addKeyword(S,y.classNameAliases[e.beginScope._wrap]||e.beginScope._wrap),
S=""):e.beginScope._multi&&(u(e.beginScope,t),S="")),N=Object.create(e,{parent:{
value:N}}),N}function p(e,t,i){var r=(function (e,t){var n=e&&e.exec(t)
;return n&&0===n.index})(e.endRe,i);if(r){if(e["on:end"]){var i$1=new n(e)
;e["on:end"](t,i$1),i$1.isMatchIgnored&&(r=!1)}if(r){
for(;e.endsParent&&e.parent;){ e=e.parent; }return e}}
if(e.endsWithParent){ return p(e.parent,t,i) }}function f(e){
return 0===N.matcher.regexIndex?(S+=e[0],1):(I=!0,0)}function b(e){
var n=e[0],i=t.substring(e.index),r=p(N,e,i);if(!r){ return ee; }var s=N
;N.endScope&&N.endScope._wrap?(d(),
M.addKeyword(n,N.endScope._wrap)):N.endScope&&N.endScope._multi?(d(),
u(N.endScope,e)):s.skip?S+=n:(s.returnEnd||s.excludeEnd||(S+=n),
d(),s.excludeEnd&&(S=n));do{
N.scope&&M.closeNode(),N.skip||N.subLanguage||(R+=N.relevance),N=N.parent
}while(N!==r.parent);return r.starts&&h(r.starts,e),s.returnEnd?0:n.length}
var m={};function w(i,s){var a=s&&s[0];if(S+=i,null==a){ return d(),0
; }if("begin"===m.type&&"end"===s.type&&m.index===s.index&&""===a){
if(S+=t.slice(s.index,s.index+1),!o){var t$1=Error(("0 width match regex (" + e + ")"))
;throw t$1.languageName=e,t$1.badRule=m.rule,t$1}return 1}
if(m=s,"begin"===s.type){ return(function (e){
var t=e[0],i=e.rule,r=new n(i),s=[i.__beforeBegin,i["on:begin"]]
;for(var i$1 = 0, list = s; i$1 < list.length; i$1 += 1){
  var n$1 = list[i$1];

  if(n$1&&(n$1(e,r),r.isMatchIgnored)){ return f(t)
;
} }return i.skip?S+=t:(i.excludeBegin&&(S+=t),
d(),i.returnBegin||i.excludeBegin||(S=t)),h(i,e),i.returnBegin?0:t.length})(s)
; }if("illegal"===s.type&&!r){
var e$1=Error('Illegal lexeme "'+a+'" for mode "'+(N.scope||"<unnamed>")+'"')
;throw e$1.mode=N,e$1}if("end"===s.type){var e$2=b(s);if(e$2!==ee){ return e$2 }}
if("illegal"===s.type&&""===a){ return 1
; }if(A>1e5&&A>3*s.index){ throw Error("potential infinite loop, way more iterations than matches")
; }return S+=a,a.length}var y=O(e)
;if(!y){ throw K(a.replace("{}",e)),Error('Unknown language: "'+e+'"')
; }var _=V(y);var v="",N=s||_;var k={},M=new g.__emitter(g);(function (){var e=[]
;for(var t=N;t!==y;t=t.parent){ t.scope&&e.unshift(t.scope)
; }e.forEach((function (e){ return M.openNode(e); }))})();var S="",R=0,j=0,A=0,I=!1;try{
for(N.matcher.considerAll();;){
A++,I?I=!1:N.matcher.considerAll(),N.matcher.lastIndex=j
;var e$1=N.matcher.exec(t);if(!e$1){ break; }var n$1=w(t.substring(j,e$1.index),e$1)
;j=e$1.index+n$1}
return w(t.substring(j)),M.closeAllNodes(),M.finalize(),v=M.toHTML(),{
language:e,value:v,relevance:R,illegal:!1,_emitter:M,_top:N}}catch(n$2){
if(n$2.message&&n$2.message.includes("Illegal")){ return{language:e,value:Y(t),
illegal:!0,relevance:0,_illegalBy:{message:n$2.message,index:j,
context:t.slice(j-100,j+100),mode:n$2.mode,resultSoFar:v},_emitter:M}; }if(o){ return{
language:e,value:Y(t),illegal:!1,relevance:0,errorRaised:n$2,_emitter:M,_top:N}
; }throw n$2}}function x(e,t){t=t||g.languages||Object.keys(i);var n=(function (e){
var t={value:Y(e),illegal:!1,relevance:0,_top:c,_emitter:new g.__emitter(g)}
;return t._emitter.addText(e),t})(e),r=t.filter(O).filter(N).map((function (t){ return E(t,e,!1); }))
;r.unshift(n);var s=r.sort((function (e,t){
if(e.relevance!==t.relevance){ return t.relevance-e.relevance
; }if(e.language&&t.language){if(O(e.language).supersetOf===t.language){ return 1
; }if(O(t.language).supersetOf===e.language){ return-1 }}return 0}));
var o = s[0];
var a = s[1];
var l=o
;return l.secondBest=a,l}function w(e){var t=null;var n=(function (e){
var t=e.className+" ";t+=e.parentNode?e.parentNode.className:""
;var n=g.languageDetectRe.exec(t);if(n){var t$1=O(n[1])
;return t$1||(W(a.replace("{}",n[1])),
W("Falling back to no-highlight mode for this block.",e)),t$1?n[1]:"no-highlight"}
return t.split(/\s+/).find((function (e){ return b(e)||O(e); }))})(e);if(b(n)){ return
; }if(k("before:highlightElement",{el:e,language:n
}),e.children.length>0&&(g.ignoreUnescapedHTML||(console.warn("One of your code blocks includes unescaped HTML. This is a potentially serious security risk."),
console.warn("https://github.com/highlightjs/highlight.js/wiki/security"),
console.warn("The element with unescaped HTML:"),
console.warn(e)),g.throwUnescapedHTML)){ throw new J("One of your code blocks includes unescaped HTML.",e.innerHTML)
; }t=e;var i=t.textContent,s=n?m(i,{language:n,ignoreIllegals:!0}):x(i)
;e.innerHTML=s.value,(function (e,t,n){var i=t&&r[t]||n
;e.classList.add("hljs"),e.classList.add("language-"+i)
})(e,n,s.language),e.result={language:s.language,re:s.relevance,
relevance:s.relevance},s.secondBest&&(e.secondBest={
language:s.secondBest.language,relevance:s.secondBest.relevance
}),k("after:highlightElement",{el:e,result:s,text:i})}var y=!1;function _(){
"loading"!==document.readyState?document.querySelectorAll(g.cssSelector).forEach(w):y=!0
}function O(e){return e=(e||"").toLowerCase(),i[e]||i[r[e]]}
function v(e,ref){
var t = ref.languageName;
"string"==typeof e&&(e=[e]),e.forEach((function (e){
r[e.toLowerCase()]=t}))}function N(e){var t=O(e)
;return t&&!t.disableAutodetect}function k(e,t){var n=e;s.forEach((function (e){
e[n]&&e[n](t)}))}
"undefined"!=typeof window&&window.addEventListener&&window.addEventListener("DOMContentLoaded",(function (){
y&&_()}),!1),Object.assign(t,{highlight:m,highlightAuto:x,highlightAll:_,
highlightElement:w,
highlightBlock:function (e){ return (X("10.7.0","highlightBlock will be removed entirely in v12.0"),
X("10.7.0","Please use highlightElement now."),w(e)); },configure:function (e){g=Q(g,e)},
initHighlighting:function (){
_(),X("10.6.0","initHighlighting() deprecated.  Use highlightAll() now.")},
initHighlightingOnLoad:function (){
_(),X("10.6.0","initHighlightingOnLoad() deprecated.  Use highlightAll() now.")
},registerLanguage:function (e,n){var r=null;try{r=n(t)}catch(t$1){
if(K("Language definition for '{}' could not be registered.".replace("{}",e)),
!o){ throw t$1; }K(t$1),r=c}
r.name||(r.name=e),i[e]=r,r.rawDefinition=n.bind(null,t),r.aliases&&v(r.aliases,{
languageName:e})},unregisterLanguage:function (e){delete i[e]
;for(var i$1 = 0, list = Object.keys(r); i$1 < list.length; i$1 += 1){
  var t = list[i$1];

  r[t]===e&&delete r[t]
}},
listLanguages:function (){ return Object.keys(i); },getLanguage:O,registerAliases:v,
autoDetection:N,inherit:Q,addPlugin:function (e){(function (e){
e["before:highlightBlock"]&&!e["before:highlightElement"]&&(e["before:highlightElement"]=function (t){
e["before:highlightBlock"](Object.assign({block:t.el},t))
}),e["after:highlightBlock"]&&!e["after:highlightElement"]&&(e["after:highlightElement"]=function (t){
e["after:highlightBlock"](Object.assign({block:t.el},t))})})(e),s.push(e)}
}),t.debugMode=function (){o=!1},t.safeMode=function (){o=!0
},t.versionString="11.7.0",t.regex={concat:p,lookahead:d,either:f,optional:h,
anyNumberOfTimes:u};for(var t$1 in A){ "object"==typeof A[t$1]&&e.exports(A[t$1])
; }return Object.assign(t,A),t})({});return te}()
;"object"==typeof exports&&"undefined"!=typeof module&&(module.exports=hljs);/*! `pgsql` grammar compiled for Highlight.js 11.7.0 */
(function (){var E=(function (){"use strict";return function (E){
var T=E.COMMENT("--","$"),N="\\$([a-zA-Z_]?|[a-zA-Z_][a-zA-Z_0-9]*)\\$",A="BIGINT INT8 BIGSERIAL SERIAL8 BIT VARYING VARBIT BOOLEAN BOOL BOX BYTEA CHARACTER CHAR VARCHAR CIDR CIRCLE DATE DOUBLE PRECISION FLOAT8 FLOAT INET INTEGER INT INT4 INTERVAL JSON JSONB LINE LSEG|10 MACADDR MACADDR8 MONEY NUMERIC DEC DECIMAL PATH POINT POLYGON REAL FLOAT4 SMALLINT INT2 SMALLSERIAL|10 SERIAL2|10 SERIAL|10 SERIAL4|10 TEXT TIME ZONE TIMETZ|10 TIMESTAMP TIMESTAMPTZ|10 TSQUERY|10 TSVECTOR|10 TXID_SNAPSHOT|10 UUID XML NATIONAL NCHAR INT4RANGE|10 INT8RANGE|10 NUMRANGE|10 TSRANGE|10 TSTZRANGE|10 DATERANGE|10 ANYELEMENT ANYARRAY ANYNONARRAY ANYENUM ANYRANGE CSTRING INTERNAL RECORD PG_DDL_COMMAND VOID UNKNOWN OPAQUE REFCURSOR NAME OID REGPROC|10 REGPROCEDURE|10 REGOPER|10 REGOPERATOR|10 REGCLASS|10 REGTYPE|10 REGROLE|10 REGNAMESPACE|10 REGCONFIG|10 REGDICTIONARY|10 ",R=A.trim().split(" ").map((function (E){ return E.split("|")[0]; })).join("|"),I="ARRAY_AGG AVG BIT_AND BIT_OR BOOL_AND BOOL_OR COUNT EVERY JSON_AGG JSONB_AGG JSON_OBJECT_AGG JSONB_OBJECT_AGG MAX MIN MODE STRING_AGG SUM XMLAGG CORR COVAR_POP COVAR_SAMP REGR_AVGX REGR_AVGY REGR_COUNT REGR_INTERCEPT REGR_R2 REGR_SLOPE REGR_SXX REGR_SXY REGR_SYY STDDEV STDDEV_POP STDDEV_SAMP VARIANCE VAR_POP VAR_SAMP PERCENTILE_CONT PERCENTILE_DISC ROW_NUMBER RANK DENSE_RANK PERCENT_RANK CUME_DIST NTILE LAG LEAD FIRST_VALUE LAST_VALUE NTH_VALUE NUM_NONNULLS NUM_NULLS ABS CBRT CEIL CEILING DEGREES DIV EXP FLOOR LN LOG MOD PI POWER RADIANS ROUND SCALE SIGN SQRT TRUNC WIDTH_BUCKET RANDOM SETSEED ACOS ACOSD ASIN ASIND ATAN ATAND ATAN2 ATAN2D COS COSD COT COTD SIN SIND TAN TAND BIT_LENGTH CHAR_LENGTH CHARACTER_LENGTH LOWER OCTET_LENGTH OVERLAY POSITION SUBSTRING TREAT TRIM UPPER ASCII BTRIM CHR CONCAT CONCAT_WS CONVERT CONVERT_FROM CONVERT_TO DECODE ENCODE INITCAP LEFT LENGTH LPAD LTRIM MD5 PARSE_IDENT PG_CLIENT_ENCODING QUOTE_IDENT|10 QUOTE_LITERAL|10 QUOTE_NULLABLE|10 REGEXP_MATCH REGEXP_MATCHES REGEXP_REPLACE REGEXP_SPLIT_TO_ARRAY REGEXP_SPLIT_TO_TABLE REPEAT REPLACE REVERSE RIGHT RPAD RTRIM SPLIT_PART STRPOS SUBSTR TO_ASCII TO_HEX TRANSLATE OCTET_LENGTH GET_BIT GET_BYTE SET_BIT SET_BYTE TO_CHAR TO_DATE TO_NUMBER TO_TIMESTAMP AGE CLOCK_TIMESTAMP|10 DATE_PART DATE_TRUNC ISFINITE JUSTIFY_DAYS JUSTIFY_HOURS JUSTIFY_INTERVAL MAKE_DATE MAKE_INTERVAL|10 MAKE_TIME MAKE_TIMESTAMP|10 MAKE_TIMESTAMPTZ|10 NOW STATEMENT_TIMESTAMP|10 TIMEOFDAY TRANSACTION_TIMESTAMP|10 ENUM_FIRST ENUM_LAST ENUM_RANGE AREA CENTER DIAMETER HEIGHT ISCLOSED ISOPEN NPOINTS PCLOSE POPEN RADIUS WIDTH BOX BOUND_BOX CIRCLE LINE LSEG PATH POLYGON ABBREV BROADCAST HOST HOSTMASK MASKLEN NETMASK NETWORK SET_MASKLEN TEXT INET_SAME_FAMILY INET_MERGE MACADDR8_SET7BIT ARRAY_TO_TSVECTOR GET_CURRENT_TS_CONFIG NUMNODE PLAINTO_TSQUERY PHRASETO_TSQUERY WEBSEARCH_TO_TSQUERY QUERYTREE SETWEIGHT STRIP TO_TSQUERY TO_TSVECTOR JSON_TO_TSVECTOR JSONB_TO_TSVECTOR TS_DELETE TS_FILTER TS_HEADLINE TS_RANK TS_RANK_CD TS_REWRITE TSQUERY_PHRASE TSVECTOR_TO_ARRAY TSVECTOR_UPDATE_TRIGGER TSVECTOR_UPDATE_TRIGGER_COLUMN XMLCOMMENT XMLCONCAT XMLELEMENT XMLFOREST XMLPI XMLROOT XMLEXISTS XML_IS_WELL_FORMED XML_IS_WELL_FORMED_DOCUMENT XML_IS_WELL_FORMED_CONTENT XPATH XPATH_EXISTS XMLTABLE XMLNAMESPACES TABLE_TO_XML TABLE_TO_XMLSCHEMA TABLE_TO_XML_AND_XMLSCHEMA QUERY_TO_XML QUERY_TO_XMLSCHEMA QUERY_TO_XML_AND_XMLSCHEMA CURSOR_TO_XML CURSOR_TO_XMLSCHEMA SCHEMA_TO_XML SCHEMA_TO_XMLSCHEMA SCHEMA_TO_XML_AND_XMLSCHEMA DATABASE_TO_XML DATABASE_TO_XMLSCHEMA DATABASE_TO_XML_AND_XMLSCHEMA XMLATTRIBUTES TO_JSON TO_JSONB ARRAY_TO_JSON ROW_TO_JSON JSON_BUILD_ARRAY JSONB_BUILD_ARRAY JSON_BUILD_OBJECT JSONB_BUILD_OBJECT JSON_OBJECT JSONB_OBJECT JSON_ARRAY_LENGTH JSONB_ARRAY_LENGTH JSON_EACH JSONB_EACH JSON_EACH_TEXT JSONB_EACH_TEXT JSON_EXTRACT_PATH JSONB_EXTRACT_PATH JSON_OBJECT_KEYS JSONB_OBJECT_KEYS JSON_POPULATE_RECORD JSONB_POPULATE_RECORD JSON_POPULATE_RECORDSET JSONB_POPULATE_RECORDSET JSON_ARRAY_ELEMENTS JSONB_ARRAY_ELEMENTS JSON_ARRAY_ELEMENTS_TEXT JSONB_ARRAY_ELEMENTS_TEXT JSON_TYPEOF JSONB_TYPEOF JSON_TO_RECORD JSONB_TO_RECORD JSON_TO_RECORDSET JSONB_TO_RECORDSET JSON_STRIP_NULLS JSONB_STRIP_NULLS JSONB_SET JSONB_INSERT JSONB_PRETTY CURRVAL LASTVAL NEXTVAL SETVAL COALESCE NULLIF GREATEST LEAST ARRAY_APPEND ARRAY_CAT ARRAY_NDIMS ARRAY_DIMS ARRAY_FILL ARRAY_LENGTH ARRAY_LOWER ARRAY_POSITION ARRAY_POSITIONS ARRAY_PREPEND ARRAY_REMOVE ARRAY_REPLACE ARRAY_TO_STRING ARRAY_UPPER CARDINALITY STRING_TO_ARRAY UNNEST ISEMPTY LOWER_INC UPPER_INC LOWER_INF UPPER_INF RANGE_MERGE GENERATE_SERIES GENERATE_SUBSCRIPTS CURRENT_DATABASE CURRENT_QUERY CURRENT_SCHEMA|10 CURRENT_SCHEMAS|10 INET_CLIENT_ADDR INET_CLIENT_PORT INET_SERVER_ADDR INET_SERVER_PORT ROW_SECURITY_ACTIVE FORMAT_TYPE TO_REGCLASS TO_REGPROC TO_REGPROCEDURE TO_REGOPER TO_REGOPERATOR TO_REGTYPE TO_REGNAMESPACE TO_REGROLE COL_DESCRIPTION OBJ_DESCRIPTION SHOBJ_DESCRIPTION TXID_CURRENT TXID_CURRENT_IF_ASSIGNED TXID_CURRENT_SNAPSHOT TXID_SNAPSHOT_XIP TXID_SNAPSHOT_XMAX TXID_SNAPSHOT_XMIN TXID_VISIBLE_IN_SNAPSHOT TXID_STATUS CURRENT_SETTING SET_CONFIG BRIN_SUMMARIZE_NEW_VALUES BRIN_SUMMARIZE_RANGE BRIN_DESUMMARIZE_RANGE GIN_CLEAN_PENDING_LIST SUPPRESS_REDUNDANT_UPDATES_TRIGGER LO_FROM_BYTEA LO_PUT LO_GET LO_CREAT LO_CREATE LO_UNLINK LO_IMPORT LO_EXPORT LOREAD LOWRITE GROUPING CAST".split(" ").map((function (E){ return E.split("|")[0]; })).join("|")
;return{name:"PostgreSQL",aliases:["postgres","postgresql"],supersetOf:"sql",
case_insensitive:!0,keywords:{
keyword:"ABORT ALTER ANALYZE BEGIN CALL CHECKPOINT|10 CLOSE CLUSTER COMMENT COMMIT COPY CREATE DEALLOCATE DECLARE DELETE DISCARD DO DROP END EXECUTE EXPLAIN FETCH GRANT IMPORT INSERT LISTEN LOAD LOCK MOVE NOTIFY PREPARE REASSIGN|10 REFRESH REINDEX RELEASE RESET REVOKE ROLLBACK SAVEPOINT SECURITY SELECT SET SHOW START TRUNCATE UNLISTEN|10 UPDATE VACUUM|10 VALUES AGGREGATE COLLATION CONVERSION|10 DATABASE DEFAULT PRIVILEGES DOMAIN TRIGGER EXTENSION FOREIGN WRAPPER|10 TABLE FUNCTION GROUP LANGUAGE LARGE OBJECT MATERIALIZED VIEW OPERATOR CLASS FAMILY POLICY PUBLICATION|10 ROLE RULE SCHEMA SEQUENCE SERVER STATISTICS SUBSCRIPTION SYSTEM TABLESPACE CONFIGURATION DICTIONARY PARSER TEMPLATE TYPE USER MAPPING PREPARED ACCESS METHOD CAST AS TRANSFORM TRANSACTION OWNED TO INTO SESSION AUTHORIZATION INDEX PROCEDURE ASSERTION ALL ANALYSE AND ANY ARRAY ASC ASYMMETRIC|10 BOTH CASE CHECK COLLATE COLUMN CONCURRENTLY|10 CONSTRAINT CROSS DEFERRABLE RANGE DESC DISTINCT ELSE EXCEPT FOR FREEZE|10 FROM FULL HAVING ILIKE IN INITIALLY INNER INTERSECT IS ISNULL JOIN LATERAL LEADING LIKE LIMIT NATURAL NOT NOTNULL NULL OFFSET ON ONLY OR ORDER OUTER OVERLAPS PLACING PRIMARY REFERENCES RETURNING SIMILAR SOME SYMMETRIC TABLESAMPLE THEN TRAILING UNION UNIQUE USING VARIADIC|10 VERBOSE WHEN WHERE WINDOW WITH BY RETURNS INOUT OUT SETOF|10 IF STRICT CURRENT CONTINUE OWNER LOCATION OVER PARTITION WITHIN BETWEEN ESCAPE EXTERNAL INVOKER DEFINER WORK RENAME VERSION CONNECTION CONNECT TABLES TEMP TEMPORARY FUNCTIONS SEQUENCES TYPES SCHEMAS OPTION CASCADE RESTRICT ADD ADMIN EXISTS VALID VALIDATE ENABLE DISABLE REPLICA|10 ALWAYS PASSING COLUMNS PATH REF VALUE OVERRIDING IMMUTABLE STABLE VOLATILE BEFORE AFTER EACH ROW PROCEDURAL ROUTINE NO HANDLER VALIDATOR OPTIONS STORAGE OIDS|10 WITHOUT INHERIT DEPENDS CALLED INPUT LEAKPROOF|10 COST ROWS NOWAIT SEARCH UNTIL ENCRYPTED|10 PASSWORD CONFLICT|10 INSTEAD INHERITS CHARACTERISTICS WRITE CURSOR ALSO STATEMENT SHARE EXCLUSIVE INLINE ISOLATION REPEATABLE READ COMMITTED SERIALIZABLE UNCOMMITTED LOCAL GLOBAL SQL PROCEDURES RECURSIVE SNAPSHOT ROLLUP CUBE TRUSTED|10 INCLUDE FOLLOWING PRECEDING UNBOUNDED RANGE GROUPS UNENCRYPTED|10 SYSID FORMAT DELIMITER HEADER QUOTE ENCODING FILTER OFF FORCE_QUOTE FORCE_NOT_NULL FORCE_NULL COSTS BUFFERS TIMING SUMMARY DISABLE_PAGE_SKIPPING RESTART CYCLE GENERATED IDENTITY DEFERRED IMMEDIATE LEVEL LOGGED UNLOGGED OF NOTHING NONE EXCLUDE ATTRIBUTE USAGE ROUTINES TRUE FALSE NAN INFINITY ALIAS BEGIN CONSTANT DECLARE END EXCEPTION RETURN PERFORM|10 RAISE GET DIAGNOSTICS STACKED|10 FOREACH LOOP ELSIF EXIT WHILE REVERSE SLICE DEBUG LOG INFO NOTICE WARNING ASSERT OPEN SUPERUSER NOSUPERUSER CREATEDB NOCREATEDB CREATEROLE NOCREATEROLE INHERIT NOINHERIT LOGIN NOLOGIN REPLICATION NOREPLICATION BYPASSRLS NOBYPASSRLS ",
built_in:"CURRENT_TIME CURRENT_TIMESTAMP CURRENT_USER CURRENT_CATALOG|10 CURRENT_DATE LOCALTIME LOCALTIMESTAMP CURRENT_ROLE|10 CURRENT_SCHEMA|10 SESSION_USER PUBLIC FOUND NEW OLD TG_NAME|10 TG_WHEN|10 TG_LEVEL|10 TG_OP|10 TG_RELID|10 TG_RELNAME|10 TG_TABLE_NAME|10 TG_TABLE_SCHEMA|10 TG_NARGS|10 TG_ARGV|10 TG_EVENT|10 TG_TAG|10 ROW_COUNT RESULT_OID|10 PG_CONTEXT|10 RETURNED_SQLSTATE COLUMN_NAME CONSTRAINT_NAME PG_DATATYPE_NAME|10 MESSAGE_TEXT TABLE_NAME SCHEMA_NAME PG_EXCEPTION_DETAIL|10 PG_EXCEPTION_HINT|10 PG_EXCEPTION_CONTEXT|10 SQLSTATE SQLERRM|10 SUCCESSFUL_COMPLETION WARNING DYNAMIC_RESULT_SETS_RETURNED IMPLICIT_ZERO_BIT_PADDING NULL_VALUE_ELIMINATED_IN_SET_FUNCTION PRIVILEGE_NOT_GRANTED PRIVILEGE_NOT_REVOKED STRING_DATA_RIGHT_TRUNCATION DEPRECATED_FEATURE NO_DATA NO_ADDITIONAL_DYNAMIC_RESULT_SETS_RETURNED SQL_STATEMENT_NOT_YET_COMPLETE CONNECTION_EXCEPTION CONNECTION_DOES_NOT_EXIST CONNECTION_FAILURE SQLCLIENT_UNABLE_TO_ESTABLISH_SQLCONNECTION SQLSERVER_REJECTED_ESTABLISHMENT_OF_SQLCONNECTION TRANSACTION_RESOLUTION_UNKNOWN PROTOCOL_VIOLATION TRIGGERED_ACTION_EXCEPTION FEATURE_NOT_SUPPORTED INVALID_TRANSACTION_INITIATION LOCATOR_EXCEPTION INVALID_LOCATOR_SPECIFICATION INVALID_GRANTOR INVALID_GRANT_OPERATION INVALID_ROLE_SPECIFICATION DIAGNOSTICS_EXCEPTION STACKED_DIAGNOSTICS_ACCESSED_WITHOUT_ACTIVE_HANDLER CASE_NOT_FOUND CARDINALITY_VIOLATION DATA_EXCEPTION ARRAY_SUBSCRIPT_ERROR CHARACTER_NOT_IN_REPERTOIRE DATETIME_FIELD_OVERFLOW DIVISION_BY_ZERO ERROR_IN_ASSIGNMENT ESCAPE_CHARACTER_CONFLICT INDICATOR_OVERFLOW INTERVAL_FIELD_OVERFLOW INVALID_ARGUMENT_FOR_LOGARITHM INVALID_ARGUMENT_FOR_NTILE_FUNCTION INVALID_ARGUMENT_FOR_NTH_VALUE_FUNCTION INVALID_ARGUMENT_FOR_POWER_FUNCTION INVALID_ARGUMENT_FOR_WIDTH_BUCKET_FUNCTION INVALID_CHARACTER_VALUE_FOR_CAST INVALID_DATETIME_FORMAT INVALID_ESCAPE_CHARACTER INVALID_ESCAPE_OCTET INVALID_ESCAPE_SEQUENCE NONSTANDARD_USE_OF_ESCAPE_CHARACTER INVALID_INDICATOR_PARAMETER_VALUE INVALID_PARAMETER_VALUE INVALID_REGULAR_EXPRESSION INVALID_ROW_COUNT_IN_LIMIT_CLAUSE INVALID_ROW_COUNT_IN_RESULT_OFFSET_CLAUSE INVALID_TABLESAMPLE_ARGUMENT INVALID_TABLESAMPLE_REPEAT INVALID_TIME_ZONE_DISPLACEMENT_VALUE INVALID_USE_OF_ESCAPE_CHARACTER MOST_SPECIFIC_TYPE_MISMATCH NULL_VALUE_NOT_ALLOWED NULL_VALUE_NO_INDICATOR_PARAMETER NUMERIC_VALUE_OUT_OF_RANGE SEQUENCE_GENERATOR_LIMIT_EXCEEDED STRING_DATA_LENGTH_MISMATCH STRING_DATA_RIGHT_TRUNCATION SUBSTRING_ERROR TRIM_ERROR UNTERMINATED_C_STRING ZERO_LENGTH_CHARACTER_STRING FLOATING_POINT_EXCEPTION INVALID_TEXT_REPRESENTATION INVALID_BINARY_REPRESENTATION BAD_COPY_FILE_FORMAT UNTRANSLATABLE_CHARACTER NOT_AN_XML_DOCUMENT INVALID_XML_DOCUMENT INVALID_XML_CONTENT INVALID_XML_COMMENT INVALID_XML_PROCESSING_INSTRUCTION INTEGRITY_CONSTRAINT_VIOLATION RESTRICT_VIOLATION NOT_NULL_VIOLATION FOREIGN_KEY_VIOLATION UNIQUE_VIOLATION CHECK_VIOLATION EXCLUSION_VIOLATION INVALID_CURSOR_STATE INVALID_TRANSACTION_STATE ACTIVE_SQL_TRANSACTION BRANCH_TRANSACTION_ALREADY_ACTIVE HELD_CURSOR_REQUIRES_SAME_ISOLATION_LEVEL INAPPROPRIATE_ACCESS_MODE_FOR_BRANCH_TRANSACTION INAPPROPRIATE_ISOLATION_LEVEL_FOR_BRANCH_TRANSACTION NO_ACTIVE_SQL_TRANSACTION_FOR_BRANCH_TRANSACTION READ_ONLY_SQL_TRANSACTION SCHEMA_AND_DATA_STATEMENT_MIXING_NOT_SUPPORTED NO_ACTIVE_SQL_TRANSACTION IN_FAILED_SQL_TRANSACTION IDLE_IN_TRANSACTION_SESSION_TIMEOUT INVALID_SQL_STATEMENT_NAME TRIGGERED_DATA_CHANGE_VIOLATION INVALID_AUTHORIZATION_SPECIFICATION INVALID_PASSWORD DEPENDENT_PRIVILEGE_DESCRIPTORS_STILL_EXIST DEPENDENT_OBJECTS_STILL_EXIST INVALID_TRANSACTION_TERMINATION SQL_ROUTINE_EXCEPTION FUNCTION_EXECUTED_NO_RETURN_STATEMENT MODIFYING_SQL_DATA_NOT_PERMITTED PROHIBITED_SQL_STATEMENT_ATTEMPTED READING_SQL_DATA_NOT_PERMITTED INVALID_CURSOR_NAME EXTERNAL_ROUTINE_EXCEPTION CONTAINING_SQL_NOT_PERMITTED MODIFYING_SQL_DATA_NOT_PERMITTED PROHIBITED_SQL_STATEMENT_ATTEMPTED READING_SQL_DATA_NOT_PERMITTED EXTERNAL_ROUTINE_INVOCATION_EXCEPTION INVALID_SQLSTATE_RETURNED NULL_VALUE_NOT_ALLOWED TRIGGER_PROTOCOL_VIOLATED SRF_PROTOCOL_VIOLATED EVENT_TRIGGER_PROTOCOL_VIOLATED SAVEPOINT_EXCEPTION INVALID_SAVEPOINT_SPECIFICATION INVALID_CATALOG_NAME INVALID_SCHEMA_NAME TRANSACTION_ROLLBACK TRANSACTION_INTEGRITY_CONSTRAINT_VIOLATION SERIALIZATION_FAILURE STATEMENT_COMPLETION_UNKNOWN DEADLOCK_DETECTED SYNTAX_ERROR_OR_ACCESS_RULE_VIOLATION SYNTAX_ERROR INSUFFICIENT_PRIVILEGE CANNOT_COERCE GROUPING_ERROR WINDOWING_ERROR INVALID_RECURSION INVALID_FOREIGN_KEY INVALID_NAME NAME_TOO_LONG RESERVED_NAME DATATYPE_MISMATCH INDETERMINATE_DATATYPE COLLATION_MISMATCH INDETERMINATE_COLLATION WRONG_OBJECT_TYPE GENERATED_ALWAYS UNDEFINED_COLUMN UNDEFINED_FUNCTION UNDEFINED_TABLE UNDEFINED_PARAMETER UNDEFINED_OBJECT DUPLICATE_COLUMN DUPLICATE_CURSOR DUPLICATE_DATABASE DUPLICATE_FUNCTION DUPLICATE_PREPARED_STATEMENT DUPLICATE_SCHEMA DUPLICATE_TABLE DUPLICATE_ALIAS DUPLICATE_OBJECT AMBIGUOUS_COLUMN AMBIGUOUS_FUNCTION AMBIGUOUS_PARAMETER AMBIGUOUS_ALIAS INVALID_COLUMN_REFERENCE INVALID_COLUMN_DEFINITION INVALID_CURSOR_DEFINITION INVALID_DATABASE_DEFINITION INVALID_FUNCTION_DEFINITION INVALID_PREPARED_STATEMENT_DEFINITION INVALID_SCHEMA_DEFINITION INVALID_TABLE_DEFINITION INVALID_OBJECT_DEFINITION WITH_CHECK_OPTION_VIOLATION INSUFFICIENT_RESOURCES DISK_FULL OUT_OF_MEMORY TOO_MANY_CONNECTIONS CONFIGURATION_LIMIT_EXCEEDED PROGRAM_LIMIT_EXCEEDED STATEMENT_TOO_COMPLEX TOO_MANY_COLUMNS TOO_MANY_ARGUMENTS OBJECT_NOT_IN_PREREQUISITE_STATE OBJECT_IN_USE CANT_CHANGE_RUNTIME_PARAM LOCK_NOT_AVAILABLE OPERATOR_INTERVENTION QUERY_CANCELED ADMIN_SHUTDOWN CRASH_SHUTDOWN CANNOT_CONNECT_NOW DATABASE_DROPPED SYSTEM_ERROR IO_ERROR UNDEFINED_FILE DUPLICATE_FILE SNAPSHOT_TOO_OLD CONFIG_FILE_ERROR LOCK_FILE_EXISTS FDW_ERROR FDW_COLUMN_NAME_NOT_FOUND FDW_DYNAMIC_PARAMETER_VALUE_NEEDED FDW_FUNCTION_SEQUENCE_ERROR FDW_INCONSISTENT_DESCRIPTOR_INFORMATION FDW_INVALID_ATTRIBUTE_VALUE FDW_INVALID_COLUMN_NAME FDW_INVALID_COLUMN_NUMBER FDW_INVALID_DATA_TYPE FDW_INVALID_DATA_TYPE_DESCRIPTORS FDW_INVALID_DESCRIPTOR_FIELD_IDENTIFIER FDW_INVALID_HANDLE FDW_INVALID_OPTION_INDEX FDW_INVALID_OPTION_NAME FDW_INVALID_STRING_LENGTH_OR_BUFFER_LENGTH FDW_INVALID_STRING_FORMAT FDW_INVALID_USE_OF_NULL_POINTER FDW_TOO_MANY_HANDLES FDW_OUT_OF_MEMORY FDW_NO_SCHEMAS FDW_OPTION_NAME_NOT_FOUND FDW_REPLY_HANDLE FDW_SCHEMA_NOT_FOUND FDW_TABLE_NOT_FOUND FDW_UNABLE_TO_CREATE_EXECUTION FDW_UNABLE_TO_CREATE_REPLY FDW_UNABLE_TO_ESTABLISH_CONNECTION PLPGSQL_ERROR RAISE_EXCEPTION NO_DATA_FOUND TOO_MANY_ROWS ASSERT_FAILURE INTERNAL_ERROR DATA_CORRUPTED INDEX_CORRUPTED "
},illegal:/:==|\W\s*\(\*|(^|\s)\$[a-z]|\{\{|[a-z]:\s*$|\.\.\.|TO:|DO:/,
contains:[{className:"keyword",variants:[{begin:/\bTEXT\s*SEARCH\b/},{
begin:/\b(PRIMARY|FOREIGN|FOR(\s+NO)?)\s+KEY\b/},{
begin:/\bPARALLEL\s+(UNSAFE|RESTRICTED|SAFE)\b/},{
begin:/\bSTORAGE\s+(PLAIN|EXTERNAL|EXTENDED|MAIN)\b/},{
begin:/\bMATCH\s+(FULL|PARTIAL|SIMPLE)\b/},{begin:/\bNULLS\s+(FIRST|LAST)\b/},{
begin:/\bEVENT\s+TRIGGER\b/},{begin:/\b(MAPPING|OR)\s+REPLACE\b/},{
begin:/\b(FROM|TO)\s+(PROGRAM|STDIN|STDOUT)\b/},{
begin:/\b(SHARE|EXCLUSIVE)\s+MODE\b/},{
begin:/\b(LEFT|RIGHT)\s+(OUTER\s+)?JOIN\b/},{
begin:/\b(FETCH|MOVE)\s+(NEXT|PRIOR|FIRST|LAST|ABSOLUTE|RELATIVE|FORWARD|BACKWARD)\b/
},{begin:/\bPRESERVE\s+ROWS\b/},{begin:/\bDISCARD\s+PLANS\b/},{
begin:/\bREFERENCING\s+(OLD|NEW)\b/},{begin:/\bSKIP\s+LOCKED\b/},{
begin:/\bGROUPING\s+SETS\b/},{
begin:/\b(BINARY|INSENSITIVE|SCROLL|NO\s+SCROLL)\s+(CURSOR|FOR)\b/},{
begin:/\b(WITH|WITHOUT)\s+HOLD\b/},{
begin:/\bWITH\s+(CASCADED|LOCAL)\s+CHECK\s+OPTION\b/},{
begin:/\bEXCLUDE\s+(TIES|NO\s+OTHERS)\b/},{
begin:/\bFORMAT\s+(TEXT|XML|JSON|YAML)\b/},{
begin:/\bSET\s+((SESSION|LOCAL)\s+)?NAMES\b/},{begin:/\bIS\s+(NOT\s+)?UNKNOWN\b/
},{begin:/\bSECURITY\s+LABEL\b/},{begin:/\bSTANDALONE\s+(YES|NO|NO\s+VALUE)\b/
},{begin:/\bWITH\s+(NO\s+)?DATA\b/},{begin:/\b(FOREIGN|SET)\s+DATA\b/},{
begin:/\bSET\s+(CATALOG|CONSTRAINTS)\b/},{begin:/\b(WITH|FOR)\s+ORDINALITY\b/},{
begin:/\bIS\s+(NOT\s+)?DOCUMENT\b/},{
begin:/\bXML\s+OPTION\s+(DOCUMENT|CONTENT)\b/},{
begin:/\b(STRIP|PRESERVE)\s+WHITESPACE\b/},{
begin:/\bNO\s+(ACTION|MAXVALUE|MINVALUE)\b/},{
begin:/\bPARTITION\s+BY\s+(RANGE|LIST|HASH)\b/},{begin:/\bAT\s+TIME\s+ZONE\b/},{
begin:/\bGRANTED\s+BY\b/},{begin:/\bRETURN\s+(QUERY|NEXT)\b/},{
begin:/\b(ATTACH|DETACH)\s+PARTITION\b/},{
begin:/\bFORCE\s+ROW\s+LEVEL\s+SECURITY\b/},{
begin:/\b(INCLUDING|EXCLUDING)\s+(COMMENTS|CONSTRAINTS|DEFAULTS|IDENTITY|INDEXES|STATISTICS|STORAGE|ALL)\b/
},{begin:/\bAS\s+(ASSIGNMENT|IMPLICIT|PERMISSIVE|RESTRICTIVE|ENUM|RANGE)\b/}]},{
begin:/\b(FORMAT|FAMILY|VERSION)\s*\(/},{begin:/\bINCLUDE\s*\(/,
keywords:"INCLUDE"},{begin:/\bRANGE(?!\s*(BETWEEN|UNBOUNDED|CURRENT|[-0-9]+))/
},{
begin:/\b(VERSION|OWNER|TEMPLATE|TABLESPACE|CONNECTION\s+LIMIT|PROCEDURE|RESTRICT|JOIN|PARSER|COPY|START|END|COLLATION|INPUT|ANALYZE|STORAGE|LIKE|DEFAULT|DELIMITER|ENCODING|COLUMN|CONSTRAINT|TABLE|SCHEMA)\s*=/
},{begin:/\b(PG_\w+?|HAS_[A-Z_]+_PRIVILEGE)\b/,relevance:10},{
begin:/\bEXTRACT\s*\(/,end:/\bFROM\b/,returnEnd:!0,keywords:{
type:"CENTURY DAY DECADE DOW DOY EPOCH HOUR ISODOW ISOYEAR MICROSECONDS MILLENNIUM MILLISECONDS MINUTE MONTH QUARTER SECOND TIMEZONE TIMEZONE_HOUR TIMEZONE_MINUTE WEEK YEAR"
}},{begin:/\b(XMLELEMENT|XMLPI)\s*\(\s*NAME/,keywords:{keyword:"NAME"}},{
begin:/\b(XMLPARSE|XMLSERIALIZE)\s*\(\s*(DOCUMENT|CONTENT)/,keywords:{
keyword:"DOCUMENT CONTENT"}},{beginKeywords:"CACHE INCREMENT MAXVALUE MINVALUE",
end:E.C_NUMBER_RE,returnEnd:!0,keywords:"BY CACHE INCREMENT MAXVALUE MINVALUE"
},{className:"type",begin:/\b(WITH|WITHOUT)\s+TIME\s+ZONE\b/},{className:"type",
begin:/\bINTERVAL\s+(YEAR|MONTH|DAY|HOUR|MINUTE|SECOND)(\s+TO\s+(MONTH|HOUR|MINUTE|SECOND))?\b/
},{
begin:/\bRETURNS\s+(LANGUAGE_HANDLER|TRIGGER|EVENT_TRIGGER|FDW_HANDLER|INDEX_AM_HANDLER|TSM_HANDLER)\b/,
keywords:{keyword:"RETURNS",
type:"LANGUAGE_HANDLER TRIGGER EVENT_TRIGGER FDW_HANDLER INDEX_AM_HANDLER TSM_HANDLER"
}},{begin:"\\b("+I+")\\s*\\("},{begin:"\\.("+R+")\\b"},{
begin:"\\b("+R+")\\s+PATH\\b",keywords:{keyword:"PATH",
type:A.replace("PATH ","")}},{className:"type",begin:"\\b("+R+")\\b"},{
className:"string",begin:"'",end:"'",contains:[{begin:"''"}]},{
className:"string",begin:"(e|E|u&|U&)'",end:"'",contains:[{begin:"\\\\."}],
relevance:10},E.END_SAME_AS_BEGIN({begin:N,end:N,contains:[{
subLanguage:["pgsql","perl","python","tcl","r","lua","java","php","ruby","bash","scheme","xml","json"],
endsWithParent:!0}]}),{begin:'"',end:'"',contains:[{begin:'""'}]
},E.C_NUMBER_MODE,E.C_BLOCK_COMMENT_MODE,T,{className:"meta",variants:[{
begin:"%(ROW)?TYPE",relevance:10},{begin:"\\$\\d+"},{begin:"^#\\w",end:"$"}]},{
className:"symbol",begin:"<<\\s*[a-zA-Z_][a-zA-Z_0-9$]*\\s*>>",relevance:10}]}}
})();hljs.registerLanguage("pgsql",E)})();
