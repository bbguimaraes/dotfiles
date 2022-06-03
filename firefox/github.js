// ==UserScript==
// @name     github_notifications
// @version  1
// @grant    none
// @include  /https://github\.com/notifications.*/
// ==/UserScript==
let f_o = function() {
  let l = document.querySelectorAll(".notification-unread .notification-list-item-link");
  if(!l.length)
    return;
  Array.prototype.slice.call(l, -20)
    .forEach(x => window.open(x.href));
  window.location.reload();
};
let f_n = function() {
  window.open(
    document
      .querySelector(".paginate-container a[aria-label='Next']")
      .href);
};
let f_r = function() {
  window.open(window.location.origin + "/notifications?query=reason%3Areview-requested");
};
let f_p = function() {
  window.open(window.location.origin + "/notifications?query=reason%3Aparticipating");
};
window.addEventListener("keydown", e => {
  if(!e.shiftKey || e.ctrlKey)
    return;
  let f = ({
    /*n*/78: f_n,
    /*o*/79: f_o,
    /*p*/80: f_p,
    /*r*/82: f_r,
  })[e.keyCode];
  if(f)
    f();
});
let b = document.createElement("button");
b.innerHTML = "open";
b.className = "btn";
b.addEventListener("click", f_o);
let c = document.querySelector(".js-check-all-container > :first-child > .BtnGroup");
if(c !== null)
  c.appendChild(b);
else {
  c = document.querySelector(".js-check-all-container > :first-child");
  c.insertBefore(b, c.children[1]);
}
