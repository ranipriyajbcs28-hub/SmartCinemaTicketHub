import re

def is_valid_email(email):
    """Validates email format."""
    if not email or not isinstance(email, str):
        return False
    pattern = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
    return bool(re.match(pattern, email.strip()))

def is_valid_password(password, min_length=6):
    """Validates password length and presence."""
    if not password or not isinstance(password, str):
        return False
    return len(password.strip()) >= min_length

def is_valid_phone(phone):
    """Validates phone number (digits and optional +/spaces/dashes)."""
    if not phone:
        return True # Optional field
    cleaned = re.sub(r'[\s\-+()]', '', phone)
    return cleaned.isdigit() and len(cleaned) >= 7

def is_positive_number(val):
    """Checks if value is a positive number."""
    try:
        f = float(val)
        return f > 0
    except (ValueError, TypeError):
        return False

def is_valid_rating(val):
    """Checks if rating is between 1.0 and 5.0."""
    try:
        f = float(val)
        return 1.0 <= f <= 5.0
    except (ValueError, TypeError):
        return False
