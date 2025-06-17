// Please see documentation at https://learn.microsoft.com/aspnet/core/client-side/bundling-and-minification
// for details on configuring this project to bundle and minify static web assets.

// ========================================
// Modern Todo MVC - Enhanced JavaScript
// ========================================

// Wait for DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
    initializeTodoApp();
});

// Main initialization function
function initializeTodoApp() {
    // Initialize all components
    initializeAnimations();
    initializeFormEnhancements();
    initializeInteractiveElements();
    initializeAccessibility();
    initializeProgressiveEnhancement();
    
    console.log('🚀 Todo MVC Enhanced - Loaded successfully!');
}

// ========================================
// Animation System
// ========================================

function initializeAnimations() {
    // Add entrance animations to cards
    const cards = document.querySelectorAll('.todo-form-card, .todo-list-card');
    cards.forEach((card, index) => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        
        setTimeout(() => {
            card.style.transition = 'all 0.6s ease-out';
            card.style.opacity = '1';
            card.style.transform = 'translateY(0)';
        }, index * 200);
    });

    // Add stagger animation to form groups
    const formGroups = document.querySelectorAll('.todo-form-group');
    formGroups.forEach((group, index) => {
        group.style.opacity = '0';
        group.style.transform = 'translateX(-20px)';
        
        setTimeout(() => {
            group.style.transition = 'all 0.4s ease-out';
            group.style.opacity = '1';
            group.style.transform = 'translateX(0)';
        }, 300 + (index * 100));
    });

    // Add hover animations to interactive elements
    addHoverAnimations();
}

function addHoverAnimations() {
    // Enhanced button hover effects
    const buttons = document.querySelectorAll('.todo-submit-btn, .btn-primary, .btn-danger');
    buttons.forEach(button => {
        button.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-2px) scale(1.02)';
        });
        
        button.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0) scale(1)';
        });
    });

    // Enhanced link hover effects
    const links = document.querySelectorAll('.todo-link');
    links.forEach(link => {
        link.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-1px)';
            this.style.boxShadow = '0 8px 15px -3px rgba(102, 126, 234, 0.3)';
        });
        
        link.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
            this.style.boxShadow = 'none';
        });
    });
}

// ========================================
// Form Enhancement System
// ========================================

function initializeFormEnhancements() {
    // Enhanced input focus effects
    const inputs = document.querySelectorAll('.todo-input');
    inputs.forEach(input => {
        // Add floating label effect
        addFloatingLabelEffect(input);
        
        // Add input validation styling
        addInputValidation(input);
        
        // Add character counter for text inputs
        if (input.type === 'text') {
            addCharacterCounter(input);
        }
    });

    // Enhanced checkbox interactions
    const checkboxes = document.querySelectorAll('.todo-checkbox');
    checkboxes.forEach(checkbox => {
        addCheckboxEnhancements(checkbox);
    });

    // Form submission enhancements
    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
        addFormSubmissionEnhancements(form);
    });
}

function addFloatingLabelEffect(input) {
    const label = input.previousElementSibling;
    if (!label || !label.classList.contains('todo-label')) return;

    // Create floating label effect
    input.addEventListener('focus', function() {
        label.style.transform = 'translateY(-8px) scale(0.85)';
        label.style.color = '#667eea';
    });

    input.addEventListener('blur', function() {
        if (!this.value) {
            label.style.transform = 'translateY(0) scale(1)';
            label.style.color = '#374151';
        }
    });

    // Check if input has value on load
    if (input.value) {
        label.style.transform = 'translateY(-8px) scale(0.85)';
        label.style.color = '#667eea';
    }
}

function addInputValidation(input) {
    input.addEventListener('input', function() {
        // Remove previous validation classes
        this.classList.remove('input-valid', 'input-invalid');
        
        // Add validation styling based on content
        if (this.value.length > 0) {
            if (this.checkValidity()) {
                this.classList.add('input-valid');
                this.style.borderColor = '#10b981';
                this.style.boxShadow = '0 0 0 3px rgba(16, 185, 129, 0.1)';
            } else {
                this.classList.add('input-invalid');
                this.style.borderColor = '#ef4444';
                this.style.boxShadow = '0 0 0 3px rgba(239, 68, 68, 0.1)';
            }
        } else {
            this.style.borderColor = '#e5e7eb';
            this.style.boxShadow = 'none';
        }
    });
}

function addCharacterCounter(input) {
    const maxLength = input.getAttribute('maxlength');
    if (!maxLength) return;

    // Create counter element
    const counter = document.createElement('div');
    counter.className = 'character-counter';
    counter.style.cssText = `
        font-size: 0.75rem;
        color: #6b7280;
        text-align: right;
        margin-top: 0.25rem;
        transition: color 0.3s ease;
    `;
    
    input.parentNode.appendChild(counter);

    function updateCounter() {
        const remaining = maxLength - input.value.length;
        counter.textContent = `${input.value.length}/${maxLength}`;
        
        if (remaining < 10) {
            counter.style.color = '#ef4444';
        } else if (remaining < 20) {
            counter.style.color = '#f59e0b';
        } else {
            counter.style.color = '#6b7280';
        }
    }

    input.addEventListener('input', updateCounter);
    updateCounter(); // Initial update
}

function addCheckboxEnhancements(checkbox) {
    checkbox.addEventListener('change', function() {
        const checkboxGroup = this.closest('.todo-checkbox-group');
        if (!checkboxGroup) return;

        if (this.checked) {
            checkboxGroup.style.background = 'linear-gradient(145deg, #d1fae5 0%, #a7f3d0 100%)';
            checkboxGroup.style.borderColor = '#10b981';
            
            // Add completion animation
            this.style.animation = 'checkboxPulse 0.3s ease-out';
        } else {
            checkboxGroup.style.background = 'linear-gradient(145deg, #f9fafb 0%, #f3f4f6 100%)';
            checkboxGroup.style.borderColor = '#e5e7eb';
            this.style.animation = 'none';
        }
    });
}

function addFormSubmissionEnhancements(form) {
    form.addEventListener('submit', function(e) {
        const submitButton = form.querySelector('button[type="submit"], input[type="submit"]');
        if (!submitButton) return;

        // Add loading state
        submitButton.disabled = true;
        submitButton.style.opacity = '0.7';
        submitButton.style.cursor = 'not-allowed';
        
        const originalText = submitButton.textContent || submitButton.value;
        
        if (submitButton.textContent !== undefined) {
            submitButton.textContent = '⏳ Processing...';
        } else {
            submitButton.value = 'Processing...';
        }

        // Add loading animation
        submitButton.classList.add('loading');

        // Reset button state after 3 seconds (fallback)
        setTimeout(() => {
            submitButton.disabled = false;
            submitButton.style.opacity = '1';
            submitButton.style.cursor = 'pointer';
            submitButton.classList.remove('loading');
            
            if (submitButton.textContent !== undefined) {
                submitButton.textContent = originalText;
            } else {
                submitButton.value = originalText;
            }
        }, 3000);
    });
}

// ========================================
// Interactive Elements
// ========================================

function initializeInteractiveElements() {
    // Add ripple effect to buttons
    addRippleEffect();
    
    // Add keyboard navigation enhancements
    addKeyboardNavigation();
    
    // Add touch gestures for mobile
    addTouchGestures();
    
    // Add context menu for todo items
    addContextMenu();
}

function addRippleEffect() {
    const buttons = document.querySelectorAll('.todo-submit-btn, .btn-primary, .btn-danger');
    
    buttons.forEach(button => {
        button.addEventListener('click', function(e) {
            const rect = this.getBoundingClientRect();
            const ripple = document.createElement('span');
            const size = Math.max(rect.width, rect.height);
            const x = e.clientX - rect.left - size / 2;
            const y = e.clientY - rect.top - size / 2;
            
            ripple.style.cssText = `
                position: absolute;
                width: ${size}px;
                height: ${size}px;
                left: ${x}px;
                top: ${y}px;
                background: rgba(255, 255, 255, 0.3);
                border-radius: 50%;
                transform: scale(0);
                animation: ripple 0.6s ease-out;
                pointer-events: none;
            `;
            
            this.style.position = 'relative';
            this.style.overflow = 'hidden';
            this.appendChild(ripple);
            
            setTimeout(() => {
                ripple.remove();
            }, 600);
        });
    });
}

function addKeyboardNavigation() {
    // Enhanced keyboard navigation
    document.addEventListener('keydown', function(e) {
        // Escape key to close modals or cancel actions
        if (e.key === 'Escape') {
            const backLinks = document.querySelectorAll('a[href*="Index"]');
            if (backLinks.length > 0) {
                backLinks[0].focus();
            }
        }
        
        // Enter key to submit forms when focused on inputs
        if (e.key === 'Enter' && e.target.classList.contains('todo-input')) {
            const form = e.target.closest('form');
            if (form) {
                const submitButton = form.querySelector('button[type="submit"], input[type="submit"]');
                if (submitButton) {
                    submitButton.click();
                }
            }
        }
    });
}

function addTouchGestures() {
    // Add touch feedback for mobile devices
    const interactiveElements = document.querySelectorAll('.todo-submit-btn, .todo-link, .todo-checkbox-group');
    
    interactiveElements.forEach(element => {
        element.addEventListener('touchstart', function() {
            this.style.transform = 'scale(0.98)';
            this.style.transition = 'transform 0.1s ease';
        });
        
        element.addEventListener('touchend', function() {
            this.style.transform = 'scale(1)';
        });
        
        element.addEventListener('touchcancel', function() {
            this.style.transform = 'scale(1)';
        });
    });
}

function addContextMenu() {
    // Add right-click context menu for todo items
    const todoItems = document.querySelectorAll('.todo-item');
    
    todoItems.forEach(item => {
        item.addEventListener('contextmenu', function(e) {
            e.preventDefault();
            showContextMenu(e.clientX, e.clientY, item);
        });
    });
}

function showContextMenu(x, y, item) {
    // Remove existing context menu
    const existingMenu = document.querySelector('.context-menu');
    if (existingMenu) {
        existingMenu.remove();
    }
    
    // Create context menu
    const menu = document.createElement('div');
    menu.className = 'context-menu';
    menu.style.cssText = `
        position: fixed;
        top: ${y}px;
        left: ${x}px;
        background: white;
        border-radius: 0.5rem;
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
        border: 1px solid #e5e7eb;
        z-index: 1000;
        min-width: 150px;
        overflow: hidden;
    `;
    
    const menuItems = [
        { text: '✏️ Edit', action: () => console.log('Edit item') },
        { text: '🗑️ Delete', action: () => console.log('Delete item') },
        { text: '📋 Copy', action: () => console.log('Copy item') }
    ];
    
    menuItems.forEach(menuItem => {
        const menuButton = document.createElement('button');
        menuButton.textContent = menuItem.text;
        menuButton.style.cssText = `
            width: 100%;
            padding: 0.75rem 1rem;
            border: none;
            background: white;
            text-align: left;
            cursor: pointer;
            transition: background 0.2s ease;
        `;
        
        menuButton.addEventListener('mouseenter', function() {
            this.style.background = '#f3f4f6';
        });
        
        menuButton.addEventListener('mouseleave', function() {
            this.style.background = 'white';
        });
        
        menuButton.addEventListener('click', function() {
            menuItem.action();
            menu.remove();
        });
        
        menu.appendChild(menuButton);
    });
    
    document.body.appendChild(menu);
    
    // Remove menu when clicking outside
    setTimeout(() => {
        document.addEventListener('click', function removeMenu() {
            menu.remove();
            document.removeEventListener('click', removeMenu);
        });
    }, 0);
}

// ========================================
// Accessibility Enhancements
// ========================================

function initializeAccessibility() {
    // Add ARIA labels and descriptions
    addAriaLabels();
    
    // Add focus management
    addFocusManagement();
    
    // Add screen reader announcements
    addScreenReaderAnnouncements();
}

function addAriaLabels() {
    // Add ARIA labels to form elements
    const inputs = document.querySelectorAll('.todo-input');
    inputs.forEach(input => {
        const label = input.previousElementSibling;
        if (label && label.classList.contains('todo-label')) {
            const labelId = 'label-' + Math.random().toString(36).substr(2, 9);
            label.id = labelId;
            input.setAttribute('aria-labelledby', labelId);
        }
    });
    
    // Add ARIA labels to buttons
    const buttons = document.querySelectorAll('.todo-submit-btn');
    buttons.forEach(button => {
        if (!button.getAttribute('aria-label')) {
            button.setAttribute('aria-label', 'Submit todo form');
        }
    });
}

function addFocusManagement() {
    // Add visible focus indicators
    const focusableElements = document.querySelectorAll('input, button, a, [tabindex]');
    
    focusableElements.forEach(element => {
        element.addEventListener('focus', function() {
            this.style.outline = '2px solid #667eea';
            this.style.outlineOffset = '2px';
        });
        
        element.addEventListener('blur', function() {
            this.style.outline = 'none';
        });
    });
}

function addScreenReaderAnnouncements() {
    // Create live region for announcements
    const liveRegion = document.createElement('div');
    liveRegion.setAttribute('aria-live', 'polite');
    liveRegion.setAttribute('aria-atomic', 'true');
    liveRegion.style.cssText = `
        position: absolute;
        left: -10000px;
        width: 1px;
        height: 1px;
        overflow: hidden;
    `;
    document.body.appendChild(liveRegion);
    
    // Function to announce messages
    window.announceToScreenReader = function(message) {
        liveRegion.textContent = message;
        setTimeout(() => {
            liveRegion.textContent = '';
        }, 1000);
    };
}

// ========================================
// Progressive Enhancement
// ========================================

function initializeProgressiveEnhancement() {
    // Add enhanced features for modern browsers
    if ('IntersectionObserver' in window) {
        addScrollAnimations();
    }
    
    if ('serviceWorker' in navigator) {
        registerServiceWorker();
    }
    
    // Add theme detection
    addThemeDetection();
    
    // Add performance monitoring
    addPerformanceMonitoring();
}

function addScrollAnimations() {
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    });
    
    const animatedElements = document.querySelectorAll('.todo-form-card, .todo-list-card');
    animatedElements.forEach(element => {
        observer.observe(element);
    });
}

function registerServiceWorker() {
    // Register service worker for offline functionality
    navigator.serviceWorker.register('/sw.js')
        .then(registration => {
            console.log('SW registered:', registration);
        })
        .catch(error => {
            console.log('SW registration failed:', error);
        });
}

function addThemeDetection() {
    // Detect user's preferred color scheme
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)');
    
    function handleThemeChange(e) {
        if (e.matches) {
            document.body.classList.add('dark-theme');
        } else {
            document.body.classList.remove('dark-theme');
        }
    }
    
    prefersDark.addListener(handleThemeChange);
    handleThemeChange(prefersDark);
}

function addPerformanceMonitoring() {
    // Monitor performance metrics
    if ('performance' in window) {
        window.addEventListener('load', () => {
            setTimeout(() => {
                const perfData = performance.getEntriesByType('navigation')[0];
                console.log('Page Load Performance:', {
                    loadTime: perfData.loadEventEnd - perfData.loadEventStart,
                    domContentLoaded: perfData.domContentLoadedEventEnd - perfData.domContentLoadedEventStart,
                    totalTime: perfData.loadEventEnd - perfData.fetchStart
                });
            }, 0);
        });
    }
}

// ========================================
// CSS Animations (injected via JavaScript)
// ========================================

// Add keyframe animations
const style = document.createElement('style');
style.textContent = `
    @keyframes ripple {
        to {
            transform: scale(2);
            opacity: 0;
        }
    }
    
    @keyframes checkboxPulse {
        0% { transform: scale(1); }
        50% { transform: scale(1.1); }
        100% { transform: scale(1); }
    }
    
    @keyframes fadeInUp {
        from {
            opacity: 0;
            transform: translateY(20px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }
    
    .input-valid {
        border-color: #10b981 !important;
        box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1) !important;
    }
    
    .input-invalid {
        border-color: #ef4444 !important;
        box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.1) !important;
    }
`;
document.head.appendChild(style);

// ========================================
// Enhanced Interactive Features
// ========================================

function enhanceTodoList() {
    // Add celebration animation for task completion
    document.querySelectorAll('form[action*="ToggleComplete"]').forEach(form => {
        form.addEventListener('submit', function(e) {
            if (!this.querySelector('.todo-checkbox').classList.contains('checked')) {
                // Task is being completed - add celebration
                createCelebration(this);
            }
        });
    });

    // Add smooth delete animation
    document.querySelectorAll('form[action*="Delete"]').forEach(form => {
        form.addEventListener('submit', function(e) {
            e.preventDefault();
            const todoItem = this.closest('.todo-item');
            
            // Add delete animation
            todoItem.style.animation = 'todoItemSlideOut 0.4s ease-in forwards';
            
            setTimeout(() => {
                this.submit();
            }, 400);
        });
    });
}

function createCelebration(element) {
    const colors = ['#667eea', '#764ba2', '#f093fb', '#f5576c', '#4facfe'];
    const rect = element.getBoundingClientRect();
    
    for (let i = 0; i < 12; i++) {
        const particle = document.createElement('div');
        particle.style.cssText = `
            position: fixed;
            width: 6px;
            height: 6px;
            background: ${colors[Math.floor(Math.random() * colors.length)]};
            border-radius: 50%;
            pointer-events: none;
            left: ${rect.left + rect.width / 2}px;
            top: ${rect.top + rect.height / 2}px;
            z-index: 1000;
            animation: celebrate 0.8s ease-out forwards;
            animation-delay: ${Math.random() * 0.3}s;
        `;
        
        const angle = (360 / 12) * i;
        const velocity = 100 + Math.random() * 50;
        
        particle.style.setProperty('--angle', `${angle}deg`);
        particle.style.setProperty('--velocity', `${velocity}px`);
        
        document.body.appendChild(particle);
        
        setTimeout(() => particle.remove(), 1100);
    }
}

// Add floating animation to auth cards
function enhanceAuthPage() {
    const authCard = document.querySelector('.auth-card');
    if (authCard) {
        let mouseX = 0, mouseY = 0;
        let cardX = 0, cardY = 0;
        
        document.addEventListener('mousemove', (e) => {
            mouseX = e.clientX / window.innerWidth - 0.5;
            mouseY = e.clientY / window.innerHeight - 0.5;
        });
        
        function animateCard() {
            cardX += (mouseX * 10 - cardX) * 0.1;
            cardY += (mouseY * 10 - cardY) * 0.1;
            
            authCard.style.transform = `translateX(${cardX}px) translateY(${cardY}px) rotateY(${cardX * 0.5}deg) rotateX(${-cardY * 0.5}deg)`;
            
            requestAnimationFrame(animateCard);
        }
        
        animateCard();
    }
}

// Add typing animation for placeholders
function addTypingAnimation() {
    document.querySelectorAll('.auth-input, .todo-input').forEach(input => {
        const originalPlaceholder = input.placeholder;
        if (originalPlaceholder) {
            let isTyping = false;
            
            input.addEventListener('focus', function() {
                if (!isTyping && !this.value) {
                    isTyping = true;
                    this.placeholder = '';
                    typeText(this, originalPlaceholder, 0);
                }
            });
            
            input.addEventListener('blur', function() {
                if (isTyping) {
                    isTyping = false;
                    this.placeholder = originalPlaceholder;
                }
            });
        }
    });
}

function typeText(element, text, index) {
    if (index < text.length && element === document.activeElement) {
        element.placeholder += text.charAt(index);
        setTimeout(() => typeText(element, text, index + 1), 50);
    }
}

// Initialize enhanced features
setTimeout(() => {
    enhanceTodoList();
    enhanceAuthPage();
    addTypingAnimation();
}, 100);

// Add additional CSS keyframes
const enhancedStyle = document.createElement('style');
enhancedStyle.textContent = `
    @keyframes celebrate {
        0% { 
            transform: translateX(0) translateY(0) scale(1);
            opacity: 1;
        }
        100% { 
            transform: translateX(calc(cos(var(--angle)) * var(--velocity))) 
                      translateY(calc(sin(var(--angle)) * var(--velocity))) 
                      scale(0);
            opacity: 0;
        }
    }
    
    @keyframes todoItemSlideOut {
        to {
            transform: translateX(100%) scale(0.8);
            opacity: 0;
        }
    }
    
    .todo-item {
        backface-visibility: hidden;
        transform-style: preserve-3d;
    }
    
    .auth-card {
        transform-style: preserve-3d;
        perspective: 1000px;
    }
`;
document.head.appendChild(enhancedStyle);

// Export functions for global use
window.TodoMVC = {
    announceToScreenReader: window.announceToScreenReader,
    addRippleEffect,
    addHoverAnimations,
    initializeAnimations,
    enhanceTodoList,
    enhanceAuthPage,
    createCelebration
};
