"use strict";

var body = document.getElementsByTagName('body')[0];
body.classList.remove('no-js');
body.classList.add('has-js');

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
}

// initialize
setTool(form.elements[1]);

// run the search
form.addEventListener('submit', function(e) {
  var q = form.elements[0].value;
  if (q.length) {
    if (form.getAttribute('data-post') === 'true') {
      document.forms[1].elements[0].setAttribute('value', q);
      document.forms[1].submit();
    }
    else {
      open(form.getAttribute('data-s').replace('{q}', encodeURIComponent(q)));
    }
  }
  e.preventDefault();
});

// click on a button to search
form.getElementsByTagName('ul')[0].addEventListener('click', function(e){
  var tag = e.target.tagName.toLowerCase();
  var ptag = e.target.parentNode.tagName.toLowerCase();
  if (tag === 'button') {
    setTool(e.target);
  }
  else if (ptag === 'button') {
    setTool(e.target.parentNode);
  }
  else if (tag === 'a' && ptag === 'h3') {
    var sections = form.getElementsByTagName('ul')[0].getElementsByTagName('ul');
    if (window.getComputedStyle(sections[0]).display === 'none' || window.getComputedStyle(sections[1]).display === 'none') {
      var div = e.target.parentNode.parentNode;
      if (div.classList.contains('active')) {
        div.classList.remove('active');
      }
      else {
        var active = form.getElementsByClassName('active');
        if (active.length > 0) {
          active[0].classList.remove('active');
        }
        div.classList.add('active');
      }
      e.preventDefault();
    }
  }

});