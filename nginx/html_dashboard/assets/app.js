/**
 * Main Application Logic
 * Handles navigation highlighting and common UI interactions.
 */
(() => {
  // Highlight active menu item based on current URL
  const currentPath = location.pathname.split('/').pop() || 'index.html';
  
  document.querySelectorAll('.nav a.nav-link').forEach(link => {
    const href = link.getAttribute('href');
    // Simple check to see if the link points to the current page
    if (href.endsWith(currentPath)) {
      link.classList.add('active');
    }
  });
})();
