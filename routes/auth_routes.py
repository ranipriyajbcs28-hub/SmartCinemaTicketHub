from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from werkzeug.security import generate_password_hash, check_password_hash
from database.db import query_one, execute, execute_returning_id
from utils.validators import is_valid_email, is_valid_password, is_valid_phone
from utils.auth import login_user, logout_user, login_required, get_current_user

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['GET', 'POST'])
def register():
    if 'user_id' in session:
        return redirect(url_for('movie.index'))

    if request.method == 'POST':
        name = request.form.get('name', '').strip()
        email = request.form.get('email', '').strip().lower()
        password = request.form.get('password', '')
        confirm_password = request.form.get('confirm_password', '')
        phone = request.form.get('phone', '').strip()

        # Validation
        if not name or len(name) < 2:
            flash("Please enter a valid full name.", "danger")
            return render_template('register.html', name=name, email=email, phone=phone)

        if not is_valid_email(email):
            flash("Please enter a valid email address.", "danger")
            return render_template('register.html', name=name, email=email, phone=phone)

        if not is_valid_password(password):
            flash("Password must be at least 6 characters long.", "danger")
            return render_template('register.html', name=name, email=email, phone=phone)

        if password != confirm_password:
            flash("Passwords do not match.", "danger")
            return render_template('register.html', name=name, email=email, phone=phone)

        if not is_valid_phone(phone):
            flash("Please enter a valid phone number.", "danger")
            return render_template('register.html', name=name, email=email, phone=phone)

        # Check if email is already registered
        existing_user = query_one("SELECT user_id FROM USERS WHERE email = :email", {'email': email})
        if existing_user:
            flash("An account with this email already exists. Please log in.", "warning")
            return redirect(url_for('auth.login'))

        # Hash password and insert into USERS table (role defaults to USER)
        hashed_pw = generate_password_hash(password)
        try:
            sql = """
                INSERT INTO USERS (name, email, password, phone, role)
                VALUES (:name, :email, :password, :phone, 'USER')
                RETURNING user_id INTO :out_id
            """
            user_id = execute_returning_id(sql, params={
                'name': name,
                'email': email,
                'password': hashed_pw,
                'phone': phone
            })

            # Auto-login upon successful registration
            login_user({
                'user_id': user_id,
                'name': name,
                'email': email,
                'role': 'USER'
            })

            flash(f"Welcome to Smart Cinema Ticket Hub, {name}! Your account was created successfully.", "success")
            return redirect(url_for('movie.index'))
        except Exception as e:
            flash(f"Registration failed due to a database error: {str(e)}", "danger")
            return render_template('register.html', name=name, email=email, phone=phone)

    return render_template('register.html')

@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    if 'user_id' in session:
        return redirect(url_for('movie.index'))

    next_url = request.args.get('next')

    if request.method == 'POST':
        email = request.form.get('email', '').strip().lower()
        password = request.form.get('password', '')

        if not email or not password:
            flash("Please enter both email and password.", "danger")
            return render_template('login.html', email=email)

        user = query_one("""
            SELECT user_id, name, email, password, phone, role 
            FROM USERS 
            WHERE email = :email
        """, {'email': email})

        if not user or not check_password_hash(user['password'], password):
            flash("Invalid email or password. Please try again.", "danger")
            return render_template('login.html', email=email)

        # Login successful
        login_user(user)
        flash(f"Welcome back, {user['name']}!", "success")

        if user['role'] == 'ADMIN':
            return redirect(next_url or url_for('admin.dashboard'))
        return redirect(next_url or url_for('movie.index'))

    return render_template('login.html')

@auth_bp.route('/logout')
def logout():
    logout_user()
    flash("You have been successfully logged out.", "info")
    return redirect(url_for('movie.index'))

@auth_bp.route('/profile', methods=['GET', 'POST'])
@login_required
def profile():
    user_id = session.get('user_id')
    user = query_one("SELECT user_id, name, email, phone, role FROM USERS WHERE user_id = :user_id", {'user_id': user_id})

    if not user:
        flash("User profile not found.", "danger")
        return redirect(url_for('movie.index'))

    if request.method == 'POST':
        name = request.form.get('name', '').strip()
        phone = request.form.get('phone', '').strip()
        new_password = request.form.get('new_password', '')
        confirm_password = request.form.get('confirm_password', '')

        if not name or len(name) < 2:
            flash("Please enter a valid name.", "danger")
            return render_template('profile.html', user=user)

        if not is_valid_phone(phone):
            flash("Please enter a valid phone number.", "danger")
            return render_template('profile.html', user=user)

        if new_password:
            if not is_valid_password(new_password):
                flash("New password must be at least 6 characters long.", "danger")
                return render_template('profile.html', user=user)
            if new_password != confirm_password:
                flash("New passwords do not match.", "danger")
                return render_template('profile.html', user=user)
            
            hashed_pw = generate_password_hash(new_password)
            execute("""
                UPDATE USERS 
                SET name = :name, phone = :phone, password = :password 
                WHERE user_id = :user_id
            """, {'name': name, 'phone': phone, 'password': hashed_pw, 'user_id': user_id})
        else:
            execute("""
                UPDATE USERS 
                SET name = :name, phone = :phone 
                WHERE user_id = :user_id
            """, {'name': name, 'phone': phone, 'user_id': user_id})

        session['name'] = name
        flash("Your profile was updated successfully!", "success")
        return redirect(url_for('auth.profile'))

    return render_template('profile.html', user=user)

@auth_bp.route('/forgot-password', methods=['GET', 'POST'])
def forgot_password():
    """
    Local College Project Demo Password Recovery:
    Validates user email and registered phone number, then allows resetting password locally.
    """
    if request.method == 'POST':
        email = request.form.get('email', '').strip().lower()
        phone = request.form.get('phone', '').strip()
        new_password = request.form.get('new_password', '')
        confirm_password = request.form.get('confirm_password', '')

        user = query_one("SELECT user_id, name, phone FROM USERS WHERE email = :email", {'email': email})
        if not user:
            flash("No account registered with this email address.", "danger")
            return render_template('forgot_password.html', email=email)

        # In demo mode, verify phone matches or provide verification
        if phone and user.get('phone') and phone != user.get('phone'):
            flash("Phone number does not match account records.", "danger")
            return render_template('forgot_password.html', email=email)

        if not is_valid_password(new_password):
            flash("New password must be at least 6 characters long.", "danger")
            return render_template('forgot_password.html', email=email)

        if new_password != confirm_password:
            flash("Passwords do not match.", "danger")
            return render_template('forgot_password.html', email=email)

        hashed_pw = generate_password_hash(new_password)
        execute("UPDATE USERS SET password = :password WHERE user_id = :user_id", {
            'password': hashed_pw,
            'user_id': user['user_id']
        })

        flash("Password reset successfully! You may now log in with your new password.", "success")
        return redirect(url_for('auth.login'))

    return render_template('forgot_password.html')
