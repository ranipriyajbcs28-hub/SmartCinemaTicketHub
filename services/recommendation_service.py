import logging
import numpy as np
import pandas as pd
from database.db import query_all

logger = logging.getLogger(__name__)

def get_ratings_dataframe():
    """Fetches user ratings from the REVIEWS table."""
    sql = """
        SELECT user_id, movie_id, rating 
        FROM REVIEWS 
        WHERE rating IS NOT NULL
    """
    rows = query_all(sql)
    if not rows:
        return pd.DataFrame(columns=['user_id', 'movie_id', 'rating'])
    return pd.DataFrame(rows)

def train_svd_recommendations(k_components=2):
    """
    Builds a user-item rating matrix from REVIEWS, normalizes ratings to a [0, 1] preference scale,
    applies Singular Value Decomposition (SVD), evaluates genuine RMSE, and returns reconstructed matrix.
    """
    df = get_ratings_dataframe()
    if df.empty or len(df) < 4:
        return {
            'status': 'insufficient_data',
            'message': 'Insufficient ratings to perform SVD (minimum 4 ratings required).',
            'rmse': None,
            'matrix': None,
            'user_ids': [],
            'movie_ids': []
        }

    # Normalize ratings (scale 1.0 - 5.0 to 0.0 - 1.0 preference scores)
    df['pref_score'] = (df['rating'] - 1.0) / 4.0

    # Pivot into user-item matrix
    user_item_matrix = df.pivot_table(
        index='user_id',
        columns='movie_id',
        values='pref_score'
    ).fillna(0.0)

    user_ids = list(user_item_matrix.index)
    movie_ids = list(user_item_matrix.columns)
    R = user_item_matrix.to_numpy()

    # Determine practical k for SVD
    n_users, n_items = R.shape
    k = min(k_components, min(n_users, n_items) - 1)
    if k < 1:
        k = 1

    try:
        # Full SVD decomposition
        U, S, Vt = np.linalg.svd(R, full_matrices=False)
        
        # Truncate to top k singular values
        U_k = U[:, :k]
        S_k = np.diag(S[:k])
        Vt_k = Vt[:k, :]
        
        # Reconstruct predicted preference matrix
        R_hat = np.dot(np.dot(U_k, S_k), Vt_k)
        
        # Clip reconstructed preference scores to [0.0, 1.0]
        R_hat = np.clip(R_hat, 0.0, 1.0)

        # Calculate genuine RMSE on observed ratings
        observed_mask = (R > 0)
        if np.sum(observed_mask) > 0:
            observed_actual = R[observed_mask]
            observed_predicted = R_hat[observed_mask]
            rmse = float(np.sqrt(np.mean((observed_actual - observed_predicted) ** 2)))
        else:
            rmse = None

        logger.info("SVD model fitted with k=%d. Measured preference RMSE: %.4f", k, rmse if rmse is not None else 0.0)

        return {
            'status': 'success',
            'rmse': round(rmse, 4) if rmse is not None else None,
            'k': k,
            'n_users': n_users,
            'n_items': n_items,
            'total_ratings': len(df),
            'reconstructed_matrix': R_hat,
            'user_ids': user_ids,
            'movie_ids': movie_ids,
            'user_item_df': user_item_matrix
        }
    except Exception as e:
        logger.error("SVD calculation error: %s", e)
        return {
            'status': 'error',
            'message': str(e),
            'rmse': None,
            'matrix': None,
            'user_ids': [],
            'movie_ids': []
        }

def get_recommendations_for_user(user_id, top_n=4):
    """
    Returns SVD-based movie recommendations for a specific user.
    If user has no history or SVD data is sparse, falls back to highest rated movies.
    """
    svd_result = train_svd_recommendations()

    # Fallback to general top rated movies if SVD cannot run
    if svd_result['status'] != 'success' or user_id not in svd_result['user_ids']:
        fallback_sql = """
            SELECT m.movie_id, m.title, m.genre, m.language, m.poster, m.rating,
                   NVL(ROUND(AVG(r.rating), 1), m.rating) as avg_rating,
                   COUNT(r.review_id) as review_count
            FROM MOVIES m
            LEFT JOIN REVIEWS r ON m.movie_id = r.movie_id
            WHERE m.release_date <= SYSDATE
            GROUP BY m.movie_id, m.title, m.genre, m.language, m.poster, m.rating
            ORDER BY avg_rating DESC
            FETCH FIRST :limit ROWS ONLY
        """
        top_movies = query_all(fallback_sql, {'limit': top_n})
        return {
            'recommendations': top_movies,
            'algorithm': 'Top Rated (Fallback)',
            'rmse': svd_result.get('rmse'),
            'status': svd_result['status']
        }

    user_idx = svd_result['user_ids'].index(user_id)
    predicted_scores = svd_result['reconstructed_matrix'][user_idx]
    user_item_df = svd_result['user_item_df']

    # Find candidate movies not yet reviewed by this user
    candidates = []
    for col_idx, movie_id in enumerate(svd_result['movie_ids']):
        already_rated = user_item_df.iloc[user_idx, col_idx] > 0
        score = predicted_scores[col_idx]
        candidates.append((movie_id, score, already_rated))

    # Sort candidates by predicted score (unrated first, then highest score)
    unrated_candidates = [c for c in candidates if not c[2]]
    unrated_candidates.sort(key=lambda x: x[1], reverse=True)

    if not unrated_candidates:
        # User has rated everything, return highest predicted scores overall
        candidates.sort(key=lambda x: x[1], reverse=True)
        chosen = candidates[:top_n]
    else:
        chosen = unrated_candidates[:top_n]

    if not chosen:
        chosen = candidates[:top_n]

    movie_ids = [c[0] for c in chosen]
    score_map = {c[0]: round(float(c[1]) * 5.0, 1) for c in chosen} # convert 0-1 score back to 5.0 star scale

    # Fetch full movie details for chosen IDs
    rec_movies = []
    if movie_ids:
        placeholders = ', '.join([f':m{i}' for i in range(len(movie_ids))])
        params = {f'm{i}': mid for i, mid in enumerate(movie_ids)}
        movie_sql = f"""
            SELECT movie_id, title, genre, language, poster, rating
            FROM MOVIES
            WHERE movie_id IN ({placeholders})
        """
        fetched = query_all(movie_sql, params)
        for m in fetched:
            m['predicted_rating'] = score_map.get(m['movie_id'], m['rating'])
            rec_movies.append(m)
        # Preserve sort order by predicted score
        rec_movies.sort(key=lambda x: x.get('predicted_rating', 0), reverse=True)

    return {
        'recommendations': rec_movies,
        'algorithm': 'Singular Value Decomposition (SVD)',
        'rmse': svd_result['rmse'],
        'k_components': svd_result['k'],
        'status': 'success'
    }
