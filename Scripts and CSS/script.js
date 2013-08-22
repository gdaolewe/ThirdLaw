(function(){
  if(typeof window.jQuery != 'undefined') {
  message('jQuery already loaded')
  } else {
  var attempts = 15;
  (function(){
   if(typeof window.jQuery == 'undefined') {
   if(--attempts > 0) {
   window.setTimeout(arguments.callee, 250)
   } else {
   alert('jQuery failed to load');
   }
   } else {
   run();
   }
   })();
  }
  
function run() {
  titleDiv = $('.pagetitle');
  title = titleDiv.find('span').text();
  //remove google ad
  $('div[style="width:300px;float:right;"]').remove();
  var container = $('.container');
  var quoteright = $('.quoteright');
  var acaptionright = $('.acaptionright');
  var indent = $('.indent').eq(0);
  var wikitext = $('#wikitext');
  container.children().remove();
  container.prepend(titleDiv);
  container.before(quoteright);
  container.before(acaptionright);
  container.append(indent);
  container.append(wikitext);
  
  quoteright.css('width', '90%');
  acaptionright.css('width', '90%');
  
  var meta = document.createElement('meta');
  meta.name="viewport";
  meta.content="width=device-width, initial-scale = 1.0, maximum-scale=1.0, user-scalable=no";
  $('body').prepend(meta);

  /*textNodes = $('#wikitext').children().first().nextUntil('hr').addBack();
  var root = document.getElementById('wikitext');
  var end = document.getElementsByTagName('hr')[0];
  var i = 0;
  while ((node = root.childNodes[i]) != end && i < root.childNodes.length) {
    if (node.nodeType == 3)
        textNodes.push(node);
    i++;
  }
  ledeNodes = $('#wikitext').children().first().nextUntil('hr').addBack().add(textNodes);
  ledeNodes.wrapAll('<div id="lede" />');
  $('#wikitext').prepend('<div id="lede" />');
  $('#lede').prepend(indent);*/

  window.location.href = 'command://done?' + title;
  
  $('.spoiler').bind('click tap', function(event) {
    if (!$(this).hasClass('spoilerClick')) {
      event.preventDefault();
    }
      $(this).toggleClass('spoilerClick');
    });
  };
})()