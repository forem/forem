function initializeSwipeGestures(){
  initializeSwipeGestures.called = true;
  swipeState = "middle";
  setTimeout(function(){

    // window.onload=function(){
    (function(d){
    var
    ce=function(e,n){var a=document.createEvent("CustomEvent");a.initCustomEvent(n,true,true,e.target);e.target.dispatchEvent(a);a=null;return false},
    nm=true,sp={x:0,y:0},ep={x:0,y:0},
    touch={
      touchstart:function(e){sp={x:e.touches[0].pageX,y:e.touches[0].pageY,scrollY:window.scrollY}},
      touchmove:function(e){nm=false;ep={x:e.touches[0].pageX,y:e.touches[0].pageY,scrollY:window.scrollY}},
      touchend:function(e){
        if(nm){ce(e,'fc')}
        else {
          var x=ep.x-sp.x,xr=Math.abs(x),y=ep.y-sp.y,yr=Math.abs(y),absScroll=Math.abs(sp.scrollY-ep.scrollY);
          if(Math.max(xr,yr)>15){
            var shouldScroll = (xr/2)>yr && absScroll < 5;
            ce(e,(shouldScroll?(x<0?'swl':'swr'):(y<0?'swu':'swd')))
          }
        };
        nm=true
      },
      touchcancel:function(e){nm=false}
    };
    for(var a in touch){d.addEventListener(a,touch[a],false);}
    })(document);
    var h=function(e){console.log(e.type,e)};
    document.body.addEventListener('swl',handleSwipeLeft,false);
    document.body.addEventListener('swr',handleSwipeRight,false);
  },50)
}


function handleSwipeLeft(e){
  if (!document.getElementById("on-page-nav-controls")){
    return;
  }
  if (swipeState == "middle"){
    swipeState = "right"
    slideSidebar("right","intoView");
  }
  else{
    swipeState = "middle"
    slideSidebar("left","outOfView");
  }
}
function handleSwipeRight(e){
  if (!document.getElementById("on-page-nav-controls")){
    return;
  }
  if (swipeState == "middle"){
    swipeState = "left"
    slideSidebar("left","intoView");
  }
  else{
    swipeState = "middle"
    slideSidebar("right","outOfView");
  }
}
