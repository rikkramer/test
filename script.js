// Form elements
const loginForm = document.getElementById('loginForm');
const usernameInput = document.getElementById('username');
const passwordInput = document.getElementById('password');
const rememberMeCheckbox = document.getElementById('rememberMe');
const loginButton = loginForm.querySelector('.login-button');
const buttonText = loginButton.querySelector('.button-text');
const loadingSpinner = loginButton.querySelector('.loading-spinner');
const messageDiv = document.getElementById('message');

// Error elements
const usernameError = document.getElementById('usernameError');
const passwordError = document.getElementById('passwordError');

// Validation functions
function validateUsername(username) {
    if (!username || username.trim() === '') {
        return 'Gebruikersnaam is verplicht';
    }
    if (username.length < 3) {
        return 'Gebruikersnaam moet minimaal 3 karakters bevatten';
    }
    return null;
}

function validatePassword(password) {
    if (!password || password.trim() === '') {
        return 'Wachtwoord is verplicht';
    }
    if (password.length < 6) {
        return 'Wachtwoord moet minimaal 6 karakters bevatten';
    }
    return null;
}

// Display error messages
function showError(inputElement, errorElement, errorMessage) {
    inputElement.classList.add('error');
    errorElement.textContent = errorMessage;
}

function clearError(inputElement, errorElement) {
    inputElement.classList.remove('error');
    errorElement.textContent = '';
}

// Show message (success or error)
function showMessage(message, type = 'success') {
    messageDiv.textContent = message;
    messageDiv.className = `message ${type}`;

    // Auto-hide after 5 seconds
    setTimeout(() => {
        messageDiv.className = 'message';
        messageDiv.textContent = '';
    }, 5000);
}

// Show loading state
function setLoadingState(isLoading) {
    if (isLoading) {
        loginButton.disabled = true;
        buttonText.textContent = 'Inloggen...';
        loadingSpinner.style.display = 'inline-block';
    } else {
        loginButton.disabled = false;
        buttonText.textContent = 'Inloggen';
        loadingSpinner.style.display = 'none';
    }
}

// Real-time validation
usernameInput.addEventListener('blur', () => {
    const error = validateUsername(usernameInput.value);
    if (error) {
        showError(usernameInput, usernameError, error);
    } else {
        clearError(usernameInput, usernameError);
    }
});

usernameInput.addEventListener('input', () => {
    if (usernameInput.classList.contains('error')) {
        const error = validateUsername(usernameInput.value);
        if (!error) {
            clearError(usernameInput, usernameError);
        }
    }
});

passwordInput.addEventListener('blur', () => {
    const error = validatePassword(passwordInput.value);
    if (error) {
        showError(passwordInput, passwordError, error);
    } else {
        clearError(passwordInput, passwordError);
    }
});

passwordInput.addEventListener('input', () => {
    if (passwordInput.classList.contains('error')) {
        const error = validatePassword(passwordInput.value);
        if (!error) {
            clearError(passwordInput, passwordError);
        }
    }
});

// Mock login function (replace with actual API call)
async function loginUser(username, password, rememberMe) {
    // Simulate API call
    return new Promise((resolve, reject) => {
        setTimeout(() => {
            // Mock authentication logic
            // In production, replace this with actual API call
            if (username === 'demo' && password === 'demo123') {
                resolve({
                    success: true,
                    message: 'Login succesvol!',
                    user: {
                        username: username,
                        token: 'mock-jwt-token-' + Date.now()
                    }
                });
            } else {
                reject({
                    success: false,
                    message: 'Ongeldige gebruikersnaam of wachtwoord'
                });
            }
        }, 1500);
    });
}

// Handle form submission
loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    // Clear previous messages
    messageDiv.className = 'message';
    messageDiv.textContent = '';

    // Get form values
    const username = usernameInput.value.trim();
    const password = passwordInput.value.trim();
    const rememberMe = rememberMeCheckbox.checked;

    // Validate inputs
    let hasError = false;

    const usernameValidationError = validateUsername(username);
    if (usernameValidationError) {
        showError(usernameInput, usernameError, usernameValidationError);
        hasError = true;
    } else {
        clearError(usernameInput, usernameError);
    }

    const passwordValidationError = validatePassword(password);
    if (passwordValidationError) {
        showError(passwordInput, passwordError, passwordValidationError);
        hasError = true;
    } else {
        clearError(passwordInput, passwordError);
    }

    // Stop if validation fails
    if (hasError) {
        return;
    }

    // Show loading state
    setLoadingState(true);

    try {
        // Attempt login
        const response = await loginUser(username, password, rememberMe);

        // Handle successful login
        if (response.success) {
            showMessage(response.message, 'success');

            // Store token (in production, use secure storage)
            if (rememberMe) {
                localStorage.setItem('authToken', response.user.token);
                localStorage.setItem('username', response.user.username);
            } else {
                sessionStorage.setItem('authToken', response.user.token);
                sessionStorage.setItem('username', response.user.username);
            }

            // Redirect to dashboard or home page after 1.5 seconds
            setTimeout(() => {
                console.log('Redirecting to dashboard...');
                // window.location.href = '/dashboard.html';
                // For demo purposes, just show a message
                showMessage('Je bent ingelogd! (Demo modus - geen redirect)', 'success');
            }, 1500);
        }
    } catch (error) {
        // Handle login error
        showMessage(error.message, 'error');
        passwordInput.value = ''; // Clear password on error
        passwordInput.focus();
    } finally {
        // Reset loading state
        setLoadingState(false);
    }
});

// Check if user is already logged in
window.addEventListener('DOMContentLoaded', () => {
    const token = localStorage.getItem('authToken') || sessionStorage.getItem('authToken');
    const username = localStorage.getItem('username') || sessionStorage.getItem('username');

    if (token && username) {
        console.log(`Gebruiker ${username} is al ingelogd`);
        // In production, redirect to dashboard
        // window.location.href = '/dashboard.html';
    }
});

// Demo credentials info (remove in production)
console.log('%c Demo Login Credentials', 'color: #4F46E5; font-size: 16px; font-weight: bold;');
console.log('%c Username: demo', 'color: #059669; font-size: 14px;');
console.log('%c Password: demo123', 'color: #059669; font-size: 14px;');
