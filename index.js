"use strict";

document.body.classList.remove('no-js');
document.body.classList.add('has-js');

var form = document.forms[0];

// add the form needed for tools that use POST
form.insertAdjacentHTML('afterend', '<form target="_blank" style="display:none" action="" method="post"><input></form>');

function setTool(button) {
  var u = button.getAttribute('value');
  var tmp = u.split('|x|');
  form.setAttribute('data-post', tmp.length > 1);
  if (tmp.length > 1) {
    document.forms[1].setAttribute('action', tmp[1]);
    document.forms[1].elements[0].setAttribute('name', tmp[0]);
  }
  else {
    form.setAttribute('data-s', u);
  }
  form.setAttribute('data-section', button.parentNode.parentNode.previousElementSibling.textContent);
  form.setAttribute('data-tool', button.textContent);
}

// initialize
setTool(form.elements[1]);
form.setAttribute('data-submitvia', 'button');

// run the search
form.addEventListener('submit', function(e) {
  var q = form.elements[0].value.trim();
  ga('send', 'event',
    form.getAttribute('data-section'),
    (q.length ? 'search' : 'noquery') + '-' + form.getAttribute('data-submitvia'),
    form.getAttribute('data-tool')
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
form.getElementsByTagName('ul')[0].addEventListener('click', function(e){
  var tag = e.target.tagName.toLowerCase();
  var ptag = e.target.parentNode.tagName.toLowerCase();
  // click on a button to search
  if (tag === 'button') {
    setTool(e.target);
  }
  else if (ptag === 'button') {
    setTool(e.target.parentNode);
  }
  // click on a section name
  else if (tag === 'a' && ptag === 'h3') {
    var sections = form.getElementsByTagName('ul')[0].getElementsByTagName('ul');
    if (window.getComputedStyle(sections[0]).display === 'none' || window.getComputedStyle(sections[1]).display === 'none') {
      // i.e. if showing mobile view
      var div = e.target.parentNode.parentNode;
      if (div.classList.contains('active')) {
        div.classList.remove('active');
        ga('send', 'event', e.target.textContent, 'collapse');
      }
      else {
        var active = form.getElementsByClassName('active');
        if (active.length > 0) {
          active[0].classList.remove('active');
        }
        div.classList.add('active');
        ga('send', 'event', e.target.textContent, 'expand');
      }
      e.preventDefault();
    }
    else {
      // i.e. not showing mobile view
      // clicking the section name to see details about the section
      ga('send', 'event', e.target.textContent, 'details-name');
    }
  }
  // clicking on a 'details' link (mobile only)
  else if (tag === 'a') {
    ga('send', 'event', e.target.parentNode.previousElementSibling.preventDefault.textContent, 'details-details');
  }

});

// enable tracking of form submissions via the enter key or button
form.elements[0].addEventListener('keydown', function(e){
  if (e.keyCode === 13) {
    form.setAttribute('data-submitvia', 'enter');
  }
});


// analytics for external links, the mailto: link, and in-page links that aren't to search tool sections

function trackLink(link, section) {
  link.addEventListener('click', function(e){
    var l = e.target.textContent + '||' + e.target.getAttribute('href');
    if (link.getAttribute('href')[0] === 'h') {
      // delay visiting until logged, unless it is taking too long
      e.preventDefault();
      function go(){
        location.href = e.target.getAttribute('href');
      }
      setTimeout(go, 1000);
      ga('send', 'event', section, 'link', l, {hitCallback: go });
    }
    else {
      ga('send', 'event', section, 'in-page link', l);
    }
  });
}

var sections  = document.getElementById('details').getElementsByTagName('section');
for (var i=0; i<sections.length; i++) {
  var name = i == 0 ? 'overview' : sections[i].getElementsByTagName('h3')[0].textContent;
  var links = sections[i].getElementsByTagName('a');
  for (var j=0; j<links.length; j++) {
    trackLink(links[j], name);
  }
}
var footer_links = document.getElementsByTagName('footer')[0].getElementsByTagName('a');
trackLink(footer_links[footer_links.length-1], 'footer');
trackLink(document.getElementById('about'), 'header');