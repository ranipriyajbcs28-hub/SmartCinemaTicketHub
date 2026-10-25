# Smart Cinema Ticket Hub 🎬

A modern, full-stack Cinema Ticket Booking application with automated Movie Sentiment Analysis, Content & Collaborative Recommendations, and dual-mode database support (MongoDB Atlas + Offline Local SQL engine).

## ✨ Key Features
- **Modern White Theme**: Sleek, clean, responsive UI with high-contrast typography and subtle glassmorphism cards.
- **Dual-Engine Persistence**: Works seamlessly with MongoDB Atlas in cloud and automatically falls back to offline SQLite engine if internet/cluster is disconnected.
- **Sentiment & Review NLP**: Customer review polarity scoring and WordCloud generator.
- **AI-Powered Recommendations**: Hybrid recommendation engine using TF-IDF and SVD.
- **Real-Time Seat Booking**: Interactive seat map with reservation locking and PDF/SVG ticket confirmations.
- **Role-Based Access Control**: Guest, Registered User, and Cinema Administrator portals.

## 🚀 Running Locally
1. Install dependencies:
   `ash
   pip install -r requirements.txt
   `
2. Run the application:
   `ash
   python app.py
   `
   Or double-click 
un_project.bat (Cloud MongoDB mode) or 
un_offline.bat (100% Offline mode).
3. Access at: http://127.0.0.1:5000

## ☁️ Deployment
- **Render**: Configured with 
ender.yaml and Procfile.
- **Vercel**: Configured with ercel.json and @vercel/python.
