"use strict";

function setTool(button) {
  var u = button.getAttribute('value');
  var tmp = u.split('|x|');
  form.setAttribute('data-post', tmp.length > 1);
  if (tmp.length > 1) {
    document.forms[1].setAttribute('action', tmp[1]);
    var params = tmp[0].split('&');
    var params_html = '';
    params.forEach(function(p){
      p = p.split('=');
      params_html += '<input type="hidden" name="' + p[0] + '" value="' + p[1] + '">';
    });
    document.forms[1].innerHTML = params_html;
  }
  else {
    form.setAttribute('data-s', u);
  }
  form.setAttribute('data-section', button.parentNode.parentNode.previousElementSibling.textContent);
  form.setAttribute('data-tool', button.textContent);
  form.elements[1].children[0].innerHTML = ' ' + button.innerHTML;
  var active = form.getElementsByClassName('activeb');
  if (active.length > 0) {
    active[0].classList.remove('activeb');
  }
  button.classList.add('activeb');
}

function trackLink(link, section) {
  link.addEventListener('click', function(e){
    var l = link.textContent + '||' + link.getAttribute('href');
    function go(){
      location.href = link.getAttribute('href');
    }
    if (link.getAttribute('href')[0] === 'h' && !e.metaKey) {
      // delay visiting until logged, unless it is taking too long
      e.preventDefault();
      setTimeout(go, 1000);
      ga('send', 'event', section, 'link', l, {hitCallback: go });
    }
    else {
      ga('send', 'event', section, 'in-page link', l);
    }
  });
}


// if a browser supports classList, then it almost certainly supports all other methods used here
// IE 9 does not support it
// treat browsers which do not as if they don't have javascript at all
if (typeof document.body.classList === 'object') {

  document.body.classList.remove('no-js');
  document.body.classList.add('has-js');

  var form = document.forms[0];

  // add the form needed for tools that use POST
  form.insertAdjacentHTML('afterend', '<form target="_blank" style="display:none" action="" method="post"></form>');

  // initialize
  setTool(form.elements[3]); // first search tool button
  form.setAttribute('data-submitvia', 'button');

  // this replaces non-javascript text, i.e. 'Search using:'
  form.getElementsByTagName('h2')[1].innerHTML = 'Change search tool';

  // run the search
  form.addEventListener('submit', function(e) {
    var q = form.elements[0].value.trim();
    ga('send', 'event',
      form.getAttribute('data-section'),
      (q.length ? 'search' : 'noquery') + '-' + form.getAttribute('data-submitvia'),
      form.getAttribute('data-tool'),
      q.length
    );
    form.setAttribute('data-submitvia', 'button'); // reset
    if (q.length) {
      if (form.getAttribute('data-post') === 'true') {
        document.forms[1].elements[0].setAttribute('value', q);
        document.forms[1].submit();
      }
      else {
        open(form.getAttribute('data-s').replace('{q}', encodeURIComponent(q)));
      }
    }
    else {
      form.elements[0].focus();
    }
    e.preventDefault();
  });

  // event handling for all actions in the form buttons area
  document.getElementById('tools').addEventListener('click', function(e){
    var tag = e.target.tagName.toLowerCase();
    var parent = e.target.parentNode;
    // click on a button to search
    if (tag === 'button' && e.target.getAttribute('value')) {
      setTool(e.target);
    }
    else if (e.target.parentNode.tagName.toLowerCase() === 'button') {
      setTool(e.target.parentNode);
    }
    // click on a section name
    else if (tag === 'a' && parent.tagName.toLowerCase() === 'h3') {
      // check for mobile by looking for a moble style
      if (getComputedStyle(e.target, ':before').content === 'none') {
        // not mobile
        ga('send', 'event', e.target.textContent, 'details', 'name');
      }
      else {
        // mobile
        e.preventDefault();
        var div = parent.parentNode;
        if (div.classList.contains('active')) {
          div.classList.remove('active');
          ga('send', 'event', parent.textContent, 'collapse');
        }
        else {
          div.classList.add('active');
          div.getElementsByTagName('button')[0].focus();
          ga('send', 'event', parent.textContent, 'expand');
        }
      }
    }
    // clicking on a 'About these' link
    else if (tag === 'a') {
      ga('send', 'event', e.target.previousElementSibling.previousElementSibling.textContent, 'details', 'details');
    }

  });

  // clear button
  form.elements[2].addEventListener('click', function(){
    form.elements[0].value = '';
    form.elements[0].focus();
    ga('send', 'event', 'page', 'clear');
  });

  // enable tracking of form submissions via the enter key, main button, or tool button (default)
  form.elements[0].addEventListener('keydown', function(e){
    if (e.keyCode === 13) {
      form.setAttribute('data-submitvia', 'enter');
    }
  });
  form.elements[1].addEventListener('click', function(){
    if (form.getAttribute('data-submitvia') === 'button') {
      // the 'click' is also triggered by the enter key, hence the if statement
      form.setAttribute('data-submitvia', 'mainbutton');
    }
  });

  // after jumping to an anchor, fix the scroll position to account for the sticky search bar
  var inpage = form.querySelectorAll('a[href^="#"]');
  var inp = document.getElementById('inp');
  for (var i=0; i<inpage.length; i++) {
    if (inpage[i].getAttribute('href') !== '#search') {
      inpage[i].addEventListener('click', function(e){
        if (getComputedStyle(e.target, ':before').content === 'none') {
          setTimeout(function(){
            window.scrollTo(0, inp.offsetTop - inp.offsetHeight - 10);
          }, 10);
        }
      });
    }
  }

  // analytics for links other than the 'About these'

  // header links
  var header_links = document.getElementsByTagName('header')[0].getElementsByTagName('a');
  for (var i=0; i<header_links.length; i++) {
    trackLink(header_links[i], 'header');
  }
  // links in the detail section
  var sections  = document.getElementById('details').getElementsByTagName('section');
  for (var i=0; i<sections.length; i++) {
    var links = sections[i].getElementsByTagName('a');
    for (var j=0; j<links.length; j++) {
      trackLink(links[j], sections[i].getElementsByTagName('h3')[0].textContent);
    }
  }
  var details = document.getElementById('details');
  // footer links
  var footer_links = document.getElementsByTagName('footer')[0].getElementsByTagName('a');
  for (var i=0; i<footer_links.length; i++) {
    trackLink(footer_links[i], 'footer');
  }

  // add the 'back to top' link
  inp.insertAdjacentHTML('beforeend', '<a href="#search"><span>↑</span> back to top</a>');
  var btt = document.querySelector('a[href="#search"]');
  trackLink(btt, 'page');
  // hide it until scrolled enough
  window.addEventListener('scroll', function() {
    btt.style.display = window.scrollY > (details.offsetTop+200) ? 'block' : 'none';
  });

}