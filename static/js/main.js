// SMART CINEMA TICKET HUB — Main Client Script

document.addEventListener('DOMContentLoaded', () => {
    // 1. Auto-dismiss flash alerts after 6 seconds
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        setTimeout(() => {
            alert.style.opacity = '0';
            alert.style.transform = 'translateY(-10px)';
            alert.style.transition = 'all 0.4s ease';
            setTimeout(() => alert.remove(), 400);
        }, 6000);
    });

    // 2. Alert close buttons
    document.querySelectorAll('.alert-close').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const alert = e.target.closest('.alert');
            if (alert) alert.remove();
        });
    });

    // 3. Quick Demo Login Fillers (Great for College Viva Demonstration)
    const adminFillBtn = document.getElementById('demoAdminBtn');
    if (adminFillBtn) {
        adminFillBtn.addEventListener('click', () => {
            const emailInput = document.getElementById('email');
            const passwordInput = document.getElementById('password');
            if (emailInput && passwordInput) {
                emailInput.value = 'admin@cinema.com';
                passwordInput.value = 'Admin@123';
            }
        });
    }

    const customerFillBtn = document.getElementById('demoCustomerBtn');
    if (customerFillBtn) {
        customerFillBtn.addEventListener('click', () => {
            const emailInput = document.getElementById('email');
            const passwordInput = document.getElementById('password');
            if (emailInput && passwordInput) {
                emailInput.value = 'rani@cinema.com';
                passwordInput.value = 'Password@123';
            }
        });
    }
});
