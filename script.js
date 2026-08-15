// ============================================================
// SCRIPT.JS — Portfolio Thomas Canisares-Morère
// ============================================================

// ── Année dans le footer ──────────────────────────────────
const yearEl = document.getElementById('year');
if (yearEl) yearEl.textContent = new Date().getFullYear();

// ── Menu burger (mobile) ──────────────────────────────────
const menuToggle = document.querySelector('.menu-toggle');
const navUl = document.querySelector('nav ul');

if (menuToggle && navUl) {
  menuToggle.addEventListener('click', () => {
    navUl.classList.toggle('hidden');
    menuToggle.textContent = navUl.classList.contains('hidden') ? '☰' : '✖';
  });
}

// ── Dark mode toggle ─────────────────────────────────────
const darkModeToggle = document.getElementById('dark-mode-toggle');

if (darkModeToggle) {
  const updateIcon = () => {
    darkModeToggle.textContent = document.documentElement.classList.contains('dark') ? '☀️' : '🌙';
  };

  darkModeToggle.addEventListener('click', () => {
    document.documentElement.classList.toggle('dark');
    const isDark = document.documentElement.classList.contains('dark');
    localStorage.setItem('darkMode', isDark ? 'enabled' : 'disabled');
    updateIcon();
  });

  updateIcon();
}

// ── Scroll Reveal (IntersectionObserver) ────────────────
const revealElements = document.querySelectorAll('.reveal, .reveal-left, .reveal-right');

if (revealElements.length > 0) {
  const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('revealed');
        revealObserver.unobserve(entry.target); // trigger only once
      }
    });
  }, {
    threshold: 0.12,
    rootMargin: '0px 0px -40px 0px'
  });

  revealElements.forEach(el => revealObserver.observe(el));
}

// ── Animated counter for stat numbers ────────────────────
function animateCounter(el, target, duration = 1200) {
  const start = performance.now();
  const isDecimal = String(target).includes('.');
  el.textContent = '0';

  function update(timestamp) {
    const elapsed = timestamp - start;
    const progress = Math.min(elapsed / duration, 1);
    // Ease-out cubic
    const eased = 1 - Math.pow(1 - progress, 3);
    const current = Math.round(eased * target);
    el.textContent = isDecimal ? (eased * target).toFixed(1) : current;
    if (progress < 1) requestAnimationFrame(update);
    else el.textContent = target;
  }

  requestAnimationFrame(update);
}

// Trigger counters when stat cards appear
const statNumbers = document.querySelectorAll('.stat-number[data-target]');
if (statNumbers.length > 0) {
  const counterObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const target = parseFloat(entry.target.dataset.target);
        animateCounter(entry.target, target);
        counterObserver.unobserve(entry.target);
      }
    });
  }, { threshold: 0.5 });

  statNumbers.forEach(el => counterObserver.observe(el));
}

// ── Sticky header shadow on scroll ───────────────────────
const header = document.querySelector('header');
if (header) {
  window.addEventListener('scroll', () => {
    if (window.scrollY > 16) {
      header.classList.add('scrolled');
      header.style.boxShadow = '0 4px 24px rgba(14, 165, 233, 0.15)';
    } else {
      header.classList.remove('scrolled');
      header.style.boxShadow = '';
    }
  }, { passive: true });
}

// ── Active nav link detection ─────────────────────────────
const currentPage = window.location.pathname.split('/').pop() || 'index.html';
document.querySelectorAll('nav a').forEach(link => {
  const href = link.getAttribute('href');
  if (href === currentPage || (currentPage === '' && href === 'index.html')) {
    link.classList.add('nav-active');
    link.classList.remove('hover:bg-primary', 'hover:text-white', 'transition');
  }
});