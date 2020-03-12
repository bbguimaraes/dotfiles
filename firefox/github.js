// ==UserScript==
// @name     github
// @version  1
// @grant    none
// @include  /https://github\.com/notifications.*/
// ==/UserScript==
let b = document.createElement("button");
b.innerHTML = "open";
b.className = "btn";
b.addEventListener("click", _ => 
  document
    .querySelectorAll(".notification-list-item-link")
    .forEach(x => window.open(x.href)));
document
  .querySelector(".js-check-all-container .BtnGroup")
  .appendChild(b);