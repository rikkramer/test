/**
 * Countdown Timer App voor iPhone
 * Een moderne, touch-vriendelijke timer applicatie
 */

class CountdownTimer {
    constructor() {
        // State
        this.totalSeconds = 0;
        this.remainingSeconds = 0;
        this.isRunning = false;
        this.isPaused = false;
        this.intervalId = null;
        this.audioContext = null;

        // DOM Elements
        this.appContainer = document.querySelector('.app-container');
        this.timerDisplay = document.getElementById('timerTime');
        this.progressCircle = document.getElementById('progressCircle');
        this.minutesInput = document.getElementById('minutesInput');
        this.secondsInput = document.getElementById('secondsInput');
        this.startBtn = document.getElementById('startBtn');
        this.startBtnIcon = document.getElementById('startBtnIcon');
        this.startBtnText = document.getElementById('startBtnText');
        this.resetBtn = document.getElementById('resetBtn');
        this.presetBtns = document.querySelectorAll('.preset-btn');
        this.alarmModal = document.getElementById('alarmModal');
        this.dismissAlarmBtn = document.getElementById('dismissAlarmBtn');

        // Circle properties
        this.circumference = 2 * Math.PI * 90; // r = 90
        this.progressCircle.style.strokeDasharray = this.circumference;

        // Initialize
        this.init();
    }

    init() {
        // Event listeners
        this.startBtn.addEventListener('click', () => this.toggleTimer());
        this.resetBtn.addEventListener('click', () => this.reset());
        this.dismissAlarmBtn.addEventListener('click', () => this.dismissAlarm());

        // Preset buttons
        this.presetBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                const minutes = parseInt(btn.dataset.minutes, 10);
                this.setPreset(minutes);
            });
        });

        // Input validation
        this.minutesInput.addEventListener('input', () => this.validateInput(this.minutesInput, 0, 99));
        this.secondsInput.addEventListener('input', () => this.validateInput(this.secondsInput, 0, 59));

        // Focus handling for better mobile UX
        [this.minutesInput, this.secondsInput].forEach(input => {
            input.addEventListener('focus', () => input.select());
        });

        // Initialize display
        this.updateDisplayFromInputs();

        // Prevent zoom on double tap
        document.addEventListener('touchend', (e) => {
            const now = Date.now();
            if (this.lastTouchEnd && now - this.lastTouchEnd < 300) {
                e.preventDefault();
            }
            this.lastTouchEnd = now;
        }, { passive: false });

        // Handle visibility change (when app goes to background)
        document.addEventListener('visibilitychange', () => {
            if (!document.hidden && this.isRunning && !this.isPaused) {
                // Sync timer when coming back to foreground
                this.syncTimer();
            }
        });

        // Store start time for background sync
        this.startTime = null;
    }

    validateInput(input, min, max) {
        let value = parseInt(input.value, 10);
        if (isNaN(value) || value < min) {
            value = min;
        } else if (value > max) {
            value = max;
        }
        input.value = value;
        this.updateDisplayFromInputs();
    }

    setPreset(minutes) {
        this.minutesInput.value = minutes;
        this.secondsInput.value = 0;
        this.updateDisplayFromInputs();

        // Visual feedback
        this.presetBtns.forEach(btn => {
            btn.style.transform = btn.dataset.minutes == minutes ? 'scale(1.1)' : '';
            setTimeout(() => btn.style.transform = '', 200);
        });
    }

    updateDisplayFromInputs() {
        const minutes = parseInt(this.minutesInput.value, 10) || 0;
        const seconds = parseInt(this.secondsInput.value, 10) || 0;
        this.totalSeconds = minutes * 60 + seconds;
        this.remainingSeconds = this.totalSeconds;
        this.updateDisplay();
    }

    updateDisplay() {
        const minutes = Math.floor(this.remainingSeconds / 60);
        const seconds = this.remainingSeconds % 60;
        this.timerDisplay.textContent =
            `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;

        // Update progress ring
        const progress = this.totalSeconds > 0
            ? (this.totalSeconds - this.remainingSeconds) / this.totalSeconds
            : 0;
        const offset = this.circumference * (1 - progress);
        this.progressCircle.style.strokeDashoffset = offset;
    }

    toggleTimer() {
        if (!this.isRunning) {
            this.start();
        } else if (this.isPaused) {
            this.resume();
        } else {
            this.pause();
        }
    }

    start() {
        // Get time from inputs
        this.updateDisplayFromInputs();

        if (this.totalSeconds <= 0) {
            this.shake(this.minutesInput);
            this.shake(this.secondsInput);
            return;
        }

        this.isRunning = true;
        this.isPaused = false;
        this.startTime = Date.now();
        this.initialRemaining = this.remainingSeconds;

        this.appContainer.classList.add('running');
        this.appContainer.classList.remove('paused', 'finished');

        this.updateButtonState('pause');
        this.resetBtn.disabled = false;

        this.tick();
    }

    pause() {
        this.isPaused = true;
        this.appContainer.classList.add('paused');
        this.updateButtonState('resume');

        if (this.intervalId) {
            clearTimeout(this.intervalId);
            this.intervalId = null;
        }
    }

    resume() {
        this.isPaused = false;
        this.startTime = Date.now();
        this.initialRemaining = this.remainingSeconds;

        this.appContainer.classList.remove('paused');
        this.updateButtonState('pause');

        this.tick();
    }

    reset() {
        this.isRunning = false;
        this.isPaused = false;

        if (this.intervalId) {
            clearTimeout(this.intervalId);
            this.intervalId = null;
        }

        this.appContainer.classList.remove('running', 'paused', 'finished');

        this.updateDisplayFromInputs();
        this.updateButtonState('start');
        this.resetBtn.disabled = true;
    }

    tick() {
        if (!this.isRunning || this.isPaused) return;

        // Calculate remaining time based on elapsed time (more accurate)
        const elapsed = Math.floor((Date.now() - this.startTime) / 1000);
        this.remainingSeconds = Math.max(0, this.initialRemaining - elapsed);

        this.updateDisplay();

        if (this.remainingSeconds <= 0) {
            this.finish();
            return;
        }

        // Schedule next tick
        this.intervalId = setTimeout(() => this.tick(), 100);
    }

    syncTimer() {
        if (!this.isRunning || this.isPaused) return;

        const elapsed = Math.floor((Date.now() - this.startTime) / 1000);
        this.remainingSeconds = Math.max(0, this.initialRemaining - elapsed);

        if (this.remainingSeconds <= 0) {
            this.finish();
        } else {
            this.updateDisplay();
            this.tick();
        }
    }

    finish() {
        this.isRunning = false;
        this.isPaused = false;
        this.remainingSeconds = 0;

        if (this.intervalId) {
            clearTimeout(this.intervalId);
            this.intervalId = null;
        }

        this.appContainer.classList.remove('running', 'paused');
        this.appContainer.classList.add('finished');

        this.updateDisplay();
        this.updateButtonState('start');

        // Show alarm
        this.showAlarm();
        this.playAlarmSound();
        this.vibrate();
    }

    showAlarm() {
        this.alarmModal.classList.add('active');
    }

    dismissAlarm() {
        this.alarmModal.classList.remove('active');
        this.stopAlarmSound();
        this.reset();
    }

    playAlarmSound() {
        try {
            // Create audio context on user interaction
            if (!this.audioContext) {
                this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            }

            // Resume if suspended (needed for iOS)
            if (this.audioContext.state === 'suspended') {
                this.audioContext.resume();
            }

            this.playBeepSequence();
        } catch (e) {
            console.log('Audio not supported:', e);
        }
    }

    playBeepSequence() {
        if (!this.audioContext) return;

        const playBeep = (time, frequency, duration) => {
            const oscillator = this.audioContext.createOscillator();
            const gainNode = this.audioContext.createGain();

            oscillator.connect(gainNode);
            gainNode.connect(this.audioContext.destination);

            oscillator.frequency.value = frequency;
            oscillator.type = 'sine';

            gainNode.gain.setValueAtTime(0.3, time);
            gainNode.gain.exponentialRampToValueAtTime(0.01, time + duration);

            oscillator.start(time);
            oscillator.stop(time + duration);
        };

        const now = this.audioContext.currentTime;

        // Play a pleasant alarm pattern
        for (let i = 0; i < 3; i++) {
            playBeep(now + i * 0.6, 880, 0.15);
            playBeep(now + i * 0.6 + 0.2, 1100, 0.15);
        }

        // Repeat after a pause if modal is still open
        this.alarmInterval = setTimeout(() => {
            if (this.alarmModal.classList.contains('active')) {
                this.playBeepSequence();
            }
        }, 2500);
    }

    stopAlarmSound() {
        if (this.alarmInterval) {
            clearTimeout(this.alarmInterval);
            this.alarmInterval = null;
        }
    }

    vibrate() {
        if ('vibrate' in navigator) {
            // Vibration pattern: vibrate, pause, vibrate, pause, vibrate
            navigator.vibrate([200, 100, 200, 100, 200]);
        }
    }

    updateButtonState(state) {
        const states = {
            start: { icon: '▶', text: 'Start' },
            pause: { icon: '⏸', text: 'Pauze' },
            resume: { icon: '▶', text: 'Hervat' }
        };

        const { icon, text } = states[state];
        this.startBtnIcon.textContent = icon;
        this.startBtnText.textContent = text;
    }

    shake(element) {
        element.style.animation = 'none';
        element.offsetHeight; // Trigger reflow
        element.style.animation = 'shake 0.5s ease';

        setTimeout(() => {
            element.style.animation = '';
        }, 500);
    }
}

// Add shake animation dynamically
const style = document.createElement('style');
style.textContent = `
    @keyframes shake {
        0%, 100% { transform: translateX(0); }
        20%, 60% { transform: translateX(-5px); }
        40%, 80% { transform: translateX(5px); }
    }
`;
document.head.appendChild(style);

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.timer = new CountdownTimer();
});

// Register service worker for PWA support (optional)
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        // Service worker registration would go here for full PWA support
        // navigator.serviceWorker.register('/sw.js');
    });
}
