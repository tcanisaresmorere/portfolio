// Année dans le footer
document.getElementById('year').textContent = new Date().getFullYear();

// Menu burger
const menuToggle = document.querySelector('.menu-toggle');
const navUl = document.querySelector('.nav ul');

menuToggle.addEventListener('click', () => {
    navUl.classList.toggle('show');
});

// Dark mode toggle
const darkModeToggle = document.getElementById('dark-mode-toggle');
const body = document.body;

darkModeToggle.addEventListener('click', () => {
    body.classList.toggle('dark-mode');
    if (body.classList.contains('dark-mode')) {
        darkModeToggle.textContent = '☀️'; // Switch to light icon
    } else {
        darkModeToggle.textContent = '🌙'; // Back to dark icon
    }
});