// Année dans le footer
document.getElementById('year').textContent = new Date().getFullYear();

// Menu burger
const menuToggle = document.querySelector('.menu-toggle');
const navUl = document.querySelector('nav ul');

if (menuToggle && navUl) {
    menuToggle.addEventListener('click', () => {
        navUl.classList.toggle('hidden');
        menuToggle.textContent = navUl.classList.contains('hidden') ? '☰' : '✖';
    });
}

// Dark mode toggle
const darkModeToggle = document.getElementById('dark-mode-toggle');

if (darkModeToggle) {
    darkModeToggle.addEventListener('click', () => {
        document.documentElement.classList.toggle('dark');
        if (document.documentElement.classList.contains('dark')) {
            darkModeToggle.textContent = '☀️';
            localStorage.setItem('darkMode', 'enabled');
        } else {
            darkModeToggle.textContent = '🌙';
            localStorage.setItem('darkMode', 'disabled');
        }
    });

    // Met à jour l'icône au chargement (au cas où)
    if (document.documentElement.classList.contains('dark')) {
        darkModeToggle.textContent = '☀️';
    } else {
        darkModeToggle.textContent = '🌙';
    }
}