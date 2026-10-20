from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from utils.auth import login_required
from utils.validators import is_valid_rating
from database.db import query_all, query_one, execute, execute_returning_id
from services.sentiment_service import analyze_sentiment
from services.wordcloud_service import generate_wordcloud_base64

review_bp = Blueprint('review', __name__)

@review_bp.route('/review/<int:movie_id>', methods=['GET', 'POST'])
@login_required
def submit_review(movie_id):
    """Allows authenticated users to submit a movie rating and textual review with real-time sentiment analysis."""
    movie = query_one("""
        SELECT movie_id, title, poster, genre, language, rating 
        FROM MOVIES 
        WHERE movie_id = :mid
    """, {'mid': movie_id})

    if not movie:
        flash("Movie not found.", "danger")
        return redirect(url_for('movie.index'))

    user_id = session.get('user_id')

    # Check if user already reviewed this movie
    existing_review = query_one("""
        SELECT review_id, rating, review_text, sentiment_label, confidence_score 
        FROM REVIEWS 
        WHERE user_id = :user_id AND movie_id = :mid
    """, {'user_id': user_id, 'mid': movie_id})

    if request.method == 'POST':
        rating_val = request.form.get('rating')
        review_text = request.form.get('review_text', '').strip()

        # Validation
        if not is_valid_rating(rating_val):
            flash("Please provide a valid rating between 1.0 and 5.0 stars.", "danger")
            return render_template('review.html', movie=movie, existing_review=existing_review)

        if not review_text or len(review_text) < 5:
            flash("Please write a meaningful review of at least 5 characters.", "danger")
            return render_template('review.html', movie=movie, existing_review=existing_review)

        rating = float(rating_val)

        # Execute genuine ML Sentiment Analysis (TF-IDF + Logistic Regression)
        sentiment_label, confidence_score = analyze_sentiment(review_text)

        try:
            if existing_review:
                # Update existing review
                update_sql = """
                    UPDATE REVIEWS 
                    SET rating = :rating, review_text = :review_text,
                        sentiment_label = :sentiment_label, confidence_score = :confidence_score,
                        review_date = CURRENT_TIMESTAMP
                    WHERE review_id = :rid
                """
                execute(update_sql, {
                    'rating': rating,
                    'review_text': review_text,
                    'sentiment_label': sentiment_label,
                    'confidence_score': confidence_score,
                    'rid': existing_review['review_id']
                })
                flash(f"Your review was updated! ML Classified: {sentiment_label.upper()} ({confidence_score:.1f}% confidence)", "success")
            else:
                # Insert new review
                insert_sql = """
                    INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score)
                    VALUES (:user_id, :movie_id, :rating, :review_text, :sentiment_label, :confidence_score)
                """
                execute(insert_sql, {
                    'user_id': user_id,
                    'movie_id': movie_id,
                    'rating': rating,
                    'review_text': review_text,
                    'sentiment_label': sentiment_label,
                    'confidence_score': confidence_score
                })
                flash(f"Thank you for your feedback! ML Classified: {sentiment_label.upper()} ({confidence_score:.1f}% confidence)", "success")

            # Update movie average rating in MOVIES table
            avg_row = query_one("SELECT AVG(rating) as avg_r FROM REVIEWS WHERE movie_id = :mid", {'mid': movie_id})
            if avg_row and avg_row['avg_r']:
                new_avg = round(float(avg_row['avg_r']), 1)
                execute("UPDATE MOVIES SET rating = :rating WHERE movie_id = :mid", {'rating': new_avg, 'mid': movie_id})

            return redirect(url_for('review.sentiment_analysis', movie_id=movie_id))

        except Exception as e:
            flash(f"Error submitting review: {str(e)}", "danger")
            return render_template('review.html', movie=movie, existing_review=existing_review)

    return render_template('review.html', movie=movie, existing_review=existing_review)

@review_bp.route('/sentiment/<int:movie_id>')
def sentiment_analysis(movie_id):
    """Detailed sentiment analytics page featuring dynamic word cloud and sentiment breakdown."""
    movie = query_one("""
        SELECT movie_id, title, poster, genre, language, rating, duration,
               TO_CHAR(release_date, 'DD Mon YYYY') as release_date_str
        FROM MOVIES 
        WHERE movie_id = :mid
    """, {'mid': movie_id})

    if not movie:
        flash("Movie not found.", "danger")
        return redirect(url_for('movie.index'))

    # Fetch all reviews for this movie
    reviews_sql = """
        SELECT r.review_id, r.rating, r.review_text, r.sentiment_label, r.confidence_score,
               TO_CHAR(r.review_date, 'DD Mon YYYY, HH:MI AM') as review_date_str,
               u.name as reviewer_name
        FROM REVIEWS r
        JOIN USERS u ON r.user_id = u.user_id
        WHERE r.movie_id = :mid
        ORDER BY r.review_date DESC
    """
    reviews = query_all(reviews_sql, {'mid': movie_id})

    # Sentiment distribution
    sentiment_counts = {'Positive': 0, 'Negative': 0, 'Neutral': 0}
    total_reviews = len(reviews)

    for r in reviews:
        lbl = r['sentiment_label']
        if lbl in sentiment_counts:
            sentiment_counts[lbl] += 1

    # Percentages
    positive_pct = round((sentiment_counts['Positive'] / total_reviews * 100), 1) if total_reviews > 0 else 0.0
    negative_pct = round((sentiment_counts['Negative'] / total_reviews * 100), 1) if total_reviews > 0 else 0.0
    neutral_pct = round((sentiment_counts['Neutral'] / total_reviews * 100), 1) if total_reviews > 0 else 0.0

    # Dynamic Word Cloud Generation (treated as runtime visualization, not a table)
    wordcloud_b64 = generate_wordcloud_base64(reviews)

    return render_template(
        'sentiment.html',
        movie=movie,
        reviews=reviews,
        total_reviews=total_reviews,
        sentiment_counts=sentiment_counts,
        positive_pct=positive_pct,
        negative_pct=negative_pct,
        neutral_pct=neutral_pct,
        wordcloud_b64=wordcloud_b64
    )
