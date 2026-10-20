import logging
from datetime import datetime
from flask import Flask, render_template, session
from config import Config
from database.db import init_db_pool, check_db_health
from utils.auth import get_current_user
from utils.db_helpers import format_currency

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s'
)
logger = logging.getLogger(__name__)

def create_app():
    """Application factory for Smart Cinema Ticket Hub."""
    app = Flask(__name__)
    app.config.from_object(Config)

    # Initialize connection pool
    try:
        init_db_pool()
    except Exception as e:
        logger.error("Could not initialize Oracle DB pool on startup: %s", e)

    # Register Blueprints
    from routes.auth_routes import auth_bp
    from routes.movie_routes import movie_bp
    from routes.booking_routes import booking_bp
    from routes.review_routes import review_bp
    from routes.admin_routes import admin_bp
    from routes.report_routes import report_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(movie_bp)
    app.register_blueprint(booking_bp)
    app.register_blueprint(review_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(report_bp)

    # Direct Download Routes for the Project ZIP
    @app.route('/download-project')
    @app.route('/download-code')
    @app.route('/download-zip')
    def download_code_zip():
        from flask import send_file
        zip_path = Config.BASE_DIR / 'smart_cinema_ticket_hub.zip'
        return send_file(
            str(zip_path),
            as_attachment=True,
            download_name='smart_cinema_ticket_hub.zip',
            mimetype='application/zip'
        )

    # Context processors for global template variables
    @app.context_processor
    def inject_globals():
        return {
            'current_user': get_current_user(),
            'current_year': datetime.now().year,
            'format_currency': format_currency
        }

    # Error handlers
    @app.errorhandler(404)
    def not_found_error(error):
        return render_template('error.html', 
                               error_title="404 - Page Not Found", 
                               error_message="The cinema page or feature you were looking for does not exist."), 404

    @app.errorhandler(500)
    def internal_error(error):
        return render_template('error.html', 
                               error_title="500 - Internal Server Error", 
                               error_message="An unexpected server error occurred. Please try again shortly."), 500

    @app.errorhandler(Exception)
    def handle_unexpected_exception(error):
        logger.error("Unhandled exception: %s", error, exc_info=True)
        # Check if database related
        if "oracledb" in str(type(error)).lower() or "ora-" in str(error).lower():
            return render_template('error.html', 
                                   error_title="Database Connection Notice", 
                                   error_message="Unable to communicate with the Oracle Database. Please ensure Oracle listener and service are running."), 503
        return render_template('error.html', 
                               error_title="Service Notice", 
                               error_message="An error occurred while processing your cinema request."), 500

    return app

app = create_app()

if __name__ == '__main__':
    print("\n" + "="*60)
    print(" SMART CINEMA TICKET HUB — Starting Local Server")
    print("="*60)
    is_db_up, db_msg = check_db_health()
    print(f" * Oracle Database Status: {db_msg}")
    print(" * Application running at: http://127.0.0.1:5000")
    print("="*60 + "\n")
    app.run(host='127.0.0.1', port=5000, debug=True)
