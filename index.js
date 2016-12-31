"use strict";

var body = document.getElementsByTagName('body')[0];
body.classList.remove('no-js');
body.classList.add('has-js');

var form = document.forms[0];

// add the form needed for tools that use POST
form.insertAdjacentHTML('afterend', '<form target="_blank" style="display:none" action="" method="post"><input></form>');

function setTool(button) {
  var post = button.getAttribute('data-post');
  form.setAttribute('data-post', post);
  if (post) {
    document.forms[1].setAttribute('action', button.getAttribute('value'));
    document.forms[1].elements[0].setAttribute('name', post);
  }
  else {
    form.setAttribute('data-s', button.getAttribute('value'));
  }
}

// initialize
setTool(form.elements[1]);

// run the search
form.addEventListener('submit', function(e) {
  var q = form.elements[0].value;
  if (q.length) {
    if (form.getAttribute('data-post') !== 'null') {
      document.forms[1].elements[0].setAttribute('value', q);
      document.forms[1].submit();
    }
    else {
      open(form.getAttribute('data-s').replace('{s}', encodeURIComponent(q)));
    }
  }
  e.preventDefault();
  return false;
});

// click on a button to search
form.getElementsByTagName('ul')[0].addEventListener('click', function(e){
  if (e.target.tagName.toLowerCase() === 'button') {
    setTool(e.target);
  }
  else if (e.target.parentNode.tagName.toLowerCase() === 'button') {
    setTool(e.target.parentNode);
  }
});