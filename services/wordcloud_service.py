import io
import base64
import logging
from pathlib import Path
from wordcloud import WordCloud, STOPWORDS
from config import Config

logger = logging.getLogger(__name__)

# Extra cinema-specific stopwords to exclude so key sentiments stand out
CUSTOM_STOPWORDS = set(STOPWORDS).union({
    'movie', 'film', 'cinema', 'watch', 'watching', 'watched', 'theatre',
    'theater', 'seen', 'see', 'one', 'will', 'make', 'much', 'even', 'scene',
    'scenes', 'character', 'characters', 'story', 'plot', 'really', 'also'
})

def generate_wordcloud_base64(reviews_list, width=800, height=400):
    """
    Combines review texts and generates a base64-encoded PNG word cloud.
    Returns None if reviews_list is empty or has no substantial words.
    """
    if not reviews_list:
        return None

    # Combine all review texts (support lowercase and uppercase dictionary keys)
    all_text = " ".join([
        (r.get('review_text') or r.get('REVIEW_TEXT') or '')
        for r in reviews_list if isinstance(r, dict)
    ])
    all_text = all_text.strip()

    if len(all_text) < 10:
        return None

    try:
        try:
            wc = WordCloud(
                width=width,
                height=height,
                background_color='#0b132b',
                colormap='autumn',
                stopwords=CUSTOM_STOPWORDS,
                max_words=100,
                min_font_size=12,
                max_font_size=80,
                random_state=42,
                collocations=False
            ).generate(all_text)
        except ValueError:
            # Fall back with standard stopwords if custom stopwords filtered all words
            wc = WordCloud(
                width=width,
                height=height,
                background_color='#0b132b',
                colormap='autumn',
                stopwords=STOPWORDS,
                max_words=100,
                min_font_size=12,
                max_font_size=80,
                random_state=42,
                collocations=False
            ).generate(all_text)

        # Save to buffer as PNG
        img_buffer = io.BytesIO()
        wc.to_image().save(img_buffer, format='PNG')
        img_buffer.seek(0)
        img_base64 = base64.b64encode(img_buffer.getvalue()).decode('utf-8')
        return f"data:image/png;base64,{img_base64}"
    except Exception as e:
        logger.error("Error generating word cloud: %s", e)
        return None

def save_wordcloud_file(movie_id, reviews_list):
    """Generates and saves the word cloud to static/generated/wordcloud_<movie_id>.png."""
    b64_data = generate_wordcloud_base64(reviews_list)
    if not b64_data:
        return None

    try:
        Config.GENERATED_FOLDER.mkdir(parents=True, exist_ok=True)
        filename = f"wordcloud_{movie_id}.png"
        filepath = Config.GENERATED_FOLDER / filename
        
        # Remove data:image/png;base64, prefix if present
        raw_b64 = b64_data.split(',', 1)[1] if ',' in b64_data else b64_data
        with open(filepath, 'wb') as f:
            f.write(base64.b64decode(raw_b64))
        return f"generated/{filename}"
    except Exception as e:
        logger.error("Error saving word cloud file: %s", e)
        return None
