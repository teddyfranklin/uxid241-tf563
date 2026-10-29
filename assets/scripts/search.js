/*
 * search.js
 * ---------
 * Makes the search bar and category buttons update the results in real time.
 *
 * Every time the user types or picks a category, this file asks search.php
 * for the matching cards (in the background, without reloading the page)
 * and puts them into the #results box.
 */

// The <form> holding the search bar and the category radio buttons.
const form = document.getElementById('search-form');

// The box that holds the "X results" line and the cards.
const results = document.getElementById('results');

// Address of search.php. It comes from the form's data-search-url attribute
// so index.php decides the path and this file never has to change.
const searchUrl = form.dataset.searchUrl;

// Used to wait until the user pauses typing before searching (see below).
let typingTimer;

// Counts searches, so an old, slow answer can't replace a newer one.
let latestSearch = 0;

// Asks search.php for new results and shows them.
async function updateResults() {
    const thisSearch = ++latestSearch;

    // Turn the form's current values into "q=...&category=..."
    const query = new URLSearchParams(new FormData(form)).toString();

    // Fetch the cards from search.php.
    const response = await fetch(searchUrl + '?' + query);
    const html = await response.text();

    // If the user searched again while we were waiting, skip this old answer.
    if (thisSearch !== latestSearch) {
        return;
    }

    // Replace the old cards with the new ones.
    results.innerHTML = html;

    // Also update the address bar, so refreshing the page keeps the same search.
    history.replaceState(null, '', '?' + query);
}

// Typing in the search bar: wait 200ms after the last key press,
// so we don't send a request for every single letter.
form.addEventListener('input', function () {
    clearTimeout(typingTimer);
    typingTimer = setTimeout(updateResults, 200);
});

// Pressing Enter would normally reload the page. We already update
// in real time, so stop the reload and just search right away.
form.addEventListener('submit', function (event) {
    event.preventDefault();
    updateResults();
});
