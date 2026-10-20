from functools import wraps
from flask import session, redirect, url_for, flash, request

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash("Please log in to access this page.", "warning")
            return redirect(url_for('auth.login', next=request.url))
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash("Administrator login required.", "warning")
            return redirect(url_for('auth.login', next=request.url))
        if session.get('role') != 'ADMIN':
            flash("Access denied. Administrator privileges required.", "danger")
            return redirect(url_for('movie.index'))
        return f(*args, **kwargs)
    return decorated_function

def get_current_user():
    if 'user_id' in session:
        return {
            'user_id': session.get('user_id'),
            'name': session.get('name'),
            'email': session.get('email'),
            'role': session.get('role')
        }
    return None

def login_user(user_dict):
    session['user_id'] = user_dict['user_id']
    session['name'] = user_dict['name']
    session['email'] = user_dict['email']
    session['role'] = user_dict.get('role', 'USER')

def logout_user():
    session.pop('user_id', None)
    session.pop('name', None)
    session.pop('email', None)
    session.pop('role', None)
