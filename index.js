"use strict";

var body = document.getElementsByTagName('body')[0];
body.classList.remove('no-js');
body.classList.add('has-js');

var form = document.forms[0];

form.addEventListener('submit', function(e) {
  var q = form.elements[0].value;
  if (q.length) {
    location.href = form.getAttribute('data-s').replace('{s}', q);
  }
  e.preventDefault();
  return false;
});
form.setAttribute('data-s', form.querySelectorAll('ul button')[0].getAttribute('value')); // default

form.getElementsByTagName('ul')[0].addEventListener('click', function(e){
  if (e.target.tagName.toLowerCase() === 'button') {
    form.setAttribute('data-s', e.target.getAttribute('value'));
    form.elements[1].getElementsByTagName('span')[0].innerHTML = e.target.innerHTML;
  }
});