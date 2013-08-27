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
  title = titleDiv.find('span').eq(0).text();
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
  $(document.body).prepend('<script async src="http://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script><!— app banner ad —> <ins class="adsbygoogle" style="display:inline-block;width:320px;height:50px" data-ad-client="ca-pub-6610802604051523" data-ad-slot="5436588855"></ins> <script> (adsbygoogle = window.adsbygoogle || []).push({}); </script>');
  var meta = document.createElement('meta');
  meta.name="viewport";
  meta.content="width=device-width, initial-scale = 1.0, maximum-scale=1.0, user-scalable=no";
  $(document.body).prepend(meta);
  window.location.href = 'command://done?' + title;
  
  $('.spoiler').bind('click tap', function(event) {
    if (!$(this).hasClass('spoilerClick')) {
      event.preventDefault();
    }
      $(this).toggleClass('spoilerClick');
      alert($(this).attr('class'));
  });
  };
})()