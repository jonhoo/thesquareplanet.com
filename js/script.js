var calcTops = {};
var pages = $('#pages');
var sitelist = $('#sitelist');
var sites = $('.site', sitelist);
var sitelimits = {
  minLeft: sitelist.closest('.page').offset().left,
  maxLeft: sitelist.closest('.page').offset().left + sitelist.width()
};

$(function(){
  var i = 0;
  $('#sitelist .thumb').each(function(){
    var $this = $(this);
    calcTops[i++] = $this.offset().top - 82;
    $this.clone().insertAfter(this);
  });

  $('nav').on('click', '.item', function(e) {
    if ($(window).width() < 950) {
      return true;
    }
    var $this = $(this);
    $this.closest('.item-inline').addClass('active').siblings().removeClass('active');
    var href = $this.attr('href');
    e.preventDefault();
    pages.scrollTo(href, 150);
    if ("history" in window && "pushState" in window.history) {
      window.history.pushState({el: href}, $this.text(), href);
    }
  });
});

$(window).on('popstate', function(e) {
  var state = e.originalEvent.state;
  var to = $('.page', pages).first();
  if (state !== null) {
    to = $(state.el);
  } else if (location.href.indexOf('#') > -1) {
    nto = $(location.href.substr(location.href.indexOf('#')));
    if (nto.length) {
      to = nto;
    }
  }
  $(".item[href='#" + to.attr('id') + "']").closest('.item-inline').addClass('active').siblings().removeClass('active');
  pages.scrollTo(to, 150);
});

(function() {
  var requestAnimationFrame = window.requestAnimationFrame || window.mozRequestAnimationFrame ||
                              window.webkitRequestAnimationFrame || window.msRequestAnimationFrame;
  window.requestAnimationFrame = requestAnimationFrame;
})();
var lastTop = 0;
function step() {
  var scrollLeft = pages.scrollLeft();
  if (scrollLeft < sitelimits.minLeft || scrollLeft > sitelimits.maxLeft) {
    $('#sitelist .site.passed').removeClass('passed');
    requestAnimationFrame(step);
    return;
  }

  var scrollTop = $(window).scrollTop();
  if (lastTop === scrollTop) {
    requestAnimationFrame(step);
    return;
  }
  lastTop = scrollTop;

  var i = 0;
  var passed = 0;
  sites.each(function(){
    if (calcTops[i++] <= scrollTop) {
      $(this).addClass('passed');
      passed++;
    } else {
      $(this).removeClass('passed');
    }
  });

  requestAnimationFrame(step);
}
requestAnimationFrame(step);
