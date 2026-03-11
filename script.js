// TechSupport Pro - Main JavaScript

// DOM Elements
const modal = document.getElementById('resultModal');
const modalTitle = document.getElementById('modalTitle');
const modalResult = document.getElementById('modalResult');
const loadingOverlay = document.getElementById('loadingOverlay');
const toast = document.getElementById('toast');
const categoryTabs = document.querySelectorAll('.category-tab');
const commandsGrids = document.querySelectorAll('.commands-grid');

// API Base URL
const API_URL = '/api';

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    initParticles();
    initCategoryTabs();
    initSmoothScroll();
    initNavHighlight();
    initCounters();
    refreshSystemInfo();
});

// Particles Animation
function initParticles() {
    const particlesContainer = document.getElementById('particles');
    if (!particlesContainer) return;
    
    const particleCount = 30;
    
    for (let i = 0; i < particleCount; i++) {
        const particle = document.createElement('div');
        particle.className = 'particle';
        particle.style.left = Math.random() * 100 + '%';
        particle.style.animationDelay = Math.random() * 8 + 's';
        particle.style.animationDuration = (6 + Math.random() * 4) + 's';
        particle.style.opacity = Math.random() * 0.5 + 0.2;
        particle.style.width = (2 + Math.random() * 4) + 'px';
        particle.style.height = particle.style.width;
        
        // Random colors
        const colors = ['#6366f1', '#8b5cf6', '#ec4899', '#0ea5e9', '#10b981'];
        particle.style.background = colors[Math.floor(Math.random() * colors.length)];
        
        particlesContainer.appendChild(particle);
    }
}

// Category Tabs
function initCategoryTabs() {
    categoryTabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const category = tab.dataset.category;
            
            // Update active tab
            categoryTabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            
            // Show corresponding grid
            commandsGrids.forEach(grid => {
                grid.classList.remove('active');
                if (grid.id === category) {
                    grid.classList.add('active');
                }
            });
        });
    });
}

// Smooth Scroll
function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                const offset = 80;
                const targetPosition = target.getBoundingClientRect().top + window.pageYOffset - offset;
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });
}

// Navigation Highlight on Scroll
function initNavHighlight() {
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-link');
    
    window.addEventListener('scroll', () => {
        let current = '';
        
        sections.forEach(section => {
            const sectionTop = section.offsetTop - 100;
            if (window.pageYOffset >= sectionTop) {
                current = section.getAttribute('id');
            }
        });
        
        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === '#' + current) {
                link.classList.add('active');
            }
        });
    });
}

// Counter Animation
function initCounters() {
    const counters = document.querySelectorAll('.stat-number[data-count]');
    
    const animateCounter = (counter) => {
        const target = parseInt(counter.dataset.count);
        const duration = 2000;
        const start = 0;
        const startTime = performance.now();
        
        const updateCounter = (currentTime) => {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);
            
            // Easing function
            const easeOutQuart = 1 - Math.pow(1 - progress, 4);
            const current = Math.floor(start + (target - start) * easeOutQuart);
            
            counter.textContent = current;
            
            if (progress < 1) {
                requestAnimationFrame(updateCounter);
            }
        };
        
        requestAnimationFrame(updateCounter);
    };
    
    // Intersection Observer for counters
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                animateCounter(entry.target);
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.5 });
    
    counters.forEach(counter => observer.observe(counter));
}

// Execute Command
async function executeCommand(command) {
    showLoading();
    
    try {
        const response = await fetch(`${API_URL}/execute`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ command })
        });
        
        const data = await response.json();
        
        hideLoading();
        
        if (data.success) {
            showModal('Результат выполнения', data.result);
            showToast('Команда выполнена успешно', 'success');
        } else {
            showModal('Ошибка', data.error || 'Неизвестная ошибка');
            showToast('Ошибка выполнения команды', 'error');
        }
    } catch (error) {
        hideLoading();
        showModal('Ошибка соединения', 'Не удалось connect к серверу. Убедитесь, что сервер запущен.');
        showToast('Ошибка соединения', 'error');
    }
}

// Refresh System Info
async function refreshSystemInfo() {
    try {
        const response = await fetch(`${API_URL}/system-info`);
        const data = await response.json();
        
        if (data.success) {
            // Update CPU
            document.getElementById('cpuInfo').textContent = data.cpu || 'Неизвестно';
            animateBar('cpuBar', 30 + Math.random() * 40);
            
            // Update RAM
            document.getElementById('ramInfo').textContent = data.ram || 'Неизвестно';
            animateBar('ramBar', calculateRamPercentage(data.ram));
            
            // Update Disk
            document.getElementById('diskInfo').textContent = data.disk || 'Неизвестно';
            animateBar('diskBar', calculateDiskPercentage(data.disk));
            
            // Update OS
            document.getElementById('osInfo').textContent = data.os || 'Неизвестно';
        }
    } catch (error) {
        console.error('Failed to fetch system info:', error);
        document.getElementById('cpuInfo').textContent = 'Ошибка загрузки';
        document.getElementById('ramInfo').textContent = 'Ошибка загрузки';
        document.getElementById('diskInfo').textContent = 'Ошибка загрузки';
        document.getElementById('osInfo').textContent = 'Ошибка загрузки';
    }
}

// Calculate RAM percentage from string like "8.5 GB / 16 GB"
function calculateRamPercentage(ramString) {
    if (!ramString) return 50;
    const match = ramString.match(/([\d.]+)\s*GB\s*\/\s*([\d.]+)\s*GB/);
    if (match) {
        const used = parseFloat(match[1]);
        const total = parseFloat(match[2]);
        return (used / total) * 100;
    }
    return 50;
}

// Calculate Disk percentage from string like "100 GB / 500 GB"
function calculateDiskPercentage(diskString) {
    if (!diskString) return 60;
    const match = diskString.match(/([\d.]+)\s*GB\s*\/\s*([\d.]+)\s*GB/);
    if (match) {
        const free = parseFloat(match[1]);
        const total = parseFloat(match[2]);
        return ((total - free) / total) * 100;
    }
    return 60;
}

// Animate progress bar
function animateBar(barId, percentage) {
    const bar = document.getElementById(barId);
    if (bar) {
        bar.style.width = '0%';
        setTimeout(() => {
            bar.style.width = percentage + '%';
        }, 100);
    }
}

// Show Modal
function showModal(title, content) {
    modalTitle.textContent = title;
    modalResult.textContent = content;
    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
}

// Close Modal
function closeModal() {
    modal.classList.remove('active');
    document.body.style.overflow = '';
}

// Copy Result
function copyResult() {
    const text = modalResult.textContent;
    navigator.clipboard.writeText(text).then(() => {
        showToast('Скопировано в буфер обмена', 'success');
    }).catch(() => {
        showToast('Ошибка копирования', 'error');
    });
}

// Show Loading
function showLoading() {
    loadingOverlay.classList.add('active');
}

// Hide Loading
function hideLoading() {
    loadingOverlay.classList.remove('active');
}

// Show Toast
function showToast(message, type = 'success') {
    toast.querySelector('.toast-message').textContent = message;
    toast.className = `toast ${type}`;
    toast.classList.add('active');
    
    setTimeout(() => {
        toast.classList.remove('active');
    }, 3000);
}

// Close modal on outside click
modal.addEventListener('click', (e) => {
    if (e.target === modal) {
        closeModal();
    }
});

// Close modal on Escape key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && modal.classList.contains('active')) {
        closeModal();
    }
});

// Header scroll effect
let lastScroll = 0;
const header = document.querySelector('.header');

window.addEventListener('scroll', () => {
    const currentScroll = window.pageYOffset;
    
    if (currentScroll > 100) {
        header.style.background = 'rgba(10, 10, 15, 0.95)';
    } else {
        header.style.background = 'rgba(10, 10, 15, 0.8)';
    }
    
    lastScroll = currentScroll;
});

// Add reveal animation on scroll
const revealElements = document.querySelectorAll('.feature-card, .step-card, .system-card, .command-card, .quick-action-card');

const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, { threshold: 0.1 });

revealElements.forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(20px)';
    el.style.transition = 'all 0.6s ease';
    revealObserver.observe(el);
});

// Console welcome message
console.log('%c TechSupport Pro ', 'background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; font-size: 20px; padding: 10px 20px; border-radius: 8px; font-weight: bold;');
console.log('%c Локальное приложение для технической поддержки Windows ', 'color: #94a3b8; font-size: 12px;');