# Feedback System Implementation Guide

## Overview

The feedback system is now fully integrated end-to-end:
- ✅ Flutter frontend UI (feedback_screen.dart)
- ✅ Flask backend API (/api/submit_feedback)
- ✅ PostgreSQL database (feedback table)
- ✅ Authentication integration (Bearer token)

## Files Added/Modified

### Backend

1. **backend/app/models/feedback.py** (NEW)
   - Feedback model with SQLAlchemy ORM
   - Methods: create(), find_by_id(), find_by_user_id(), get_all()
   - Fields: id, user_id, user_name, user_email, rating, category, feedback_message, created_at

2. **backend/app/routes/feedback.py** (NEW)
   - POST /api/submit_feedback - Submit feedback (requires auth)
   - GET /api/feedback/<id> - Get specific feedback (requires auth)
   - GET /api/feedback - Get user's feedback history (requires auth)
   - GET /api/admin/feedback - Get all feedback (requires auth)

3. **backend/app/__init__.py** (MODIFIED)
   - Added: from app.routes.feedback import feedback_bp
   - Added: app.register_blueprint(feedback_bp, url_prefix='/api')

4. **backend/app/models/__init__.py** (MODIFIED)
   - Added: from app.models.feedback import Feedback
   - Added: 'Feedback' to __all__

5. **backend/create_feedback_table.py** (NEW)
   - Migration script to create feedback table

### Frontend

6. **lib/screens/feedback_screen.dart** (MODIFIED)
   - Added imports: http, dart:convert, api_config, auth_service
   - Modified: _submitFeedback() now makes POST request to backend
   - Features: 
     - Token-based authentication
     - Async request handling
     - Error handling with user feedback
     - Auto-navigation on success
     - Loading states

## Setup Instructions

### Step 1: Create Feedback Table in Database

Run this command in your backend directory:

```bash
python create_feedback_table.py
```

Expected output:
```
🔄 Creating feedback table...
✅ Feedback table created successfully!
✅ Table columns: id, user_id, user_name, user_email, rating, category, feedback_message, created_at

📋 Table schema:
   - id: INTEGER NOT NULL
   - user_id: INTEGER NOT NULL
   - user_name: VARCHAR(255) NOT NULL
   - user_email: VARCHAR(120) NOT NULL
   - rating: INTEGER NOT NULL
   - category: VARCHAR(50) NOT NULL
   - feedback_message: TEXT NOT NULL
   - created_at: DATETIME NOT NULL
```

### Step 2: Deploy Backend Changes to Render

1. Commit the new files:
```bash
git add backend/app/models/feedback.py
git add backend/app/routes/feedback.py
git add backend/create_feedback_table.py
git add backend/app/models/__init__.py
git add backend/app/__init__.py
git commit -m "Add feedback system backend"
git push
```

2. Render will automatically deploy the changes

3. The feedback table will be created automatically when the app starts (via db.create_all() in the app factory)

### Step 3: Test the Feedback API

Use curl or Postman to test:

```bash
# 1. Login to get token
curl -X POST https://your-render-url.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'

# Get the token from response

# 2. Submit feedback
curl -X POST https://your-render-url.onrender.com/api/submit_feedback \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "rating": 5,
    "category": "Bug Report",
    "feedback_message": "Great app! Works smoothly."
  }'

# Expected response:
# {
#   "message": "Thank you for your feedback!",
#   "feedback": {
#     "id": 1,
#     "user_id": 123,
#     "user_name": "Dr. John Doe",
#     "user_email": "john@example.com",
#     "rating": 5,
#     "category": "Bug Report",
#     "feedback_message": "Great app! Works smoothly.",
#     "created_at": "2024-05-13T10:30:00"
#   }
# }
```

### Step 4: Verify in Flutter

1. Open the app and navigate to Settings → Feedback
2. Fill out the form:
   - Select a rating (emoji)
   - Choose a category from dropdown
   - Type your feedback message
   - Tap "Send Feedback"
3. Expected result:
   - "Thank you for your feedback!" snackbar
   - Form clears
   - Screen navigates back to Settings after 800ms

### Step 5: Verify in Database

Check your PostgreSQL database:

```sql
-- View feedback table
SELECT * FROM feedback;

-- Count feedback entries
SELECT COUNT(*) FROM feedback;

-- Get feedback by user
SELECT * FROM feedback WHERE user_id = 123;

-- Get feedback by category
SELECT * FROM feedback WHERE category = 'Bug Report';

-- Get recent feedback
SELECT * FROM feedback ORDER BY created_at DESC LIMIT 10;
```

## API Endpoints

### 1. Submit Feedback (Main Endpoint)

**POST** `/api/submit_feedback`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "rating": 5,
  "category": "Bug Report",
  "feedback_message": "The app crashes when..."
}
```

**Response (200):**
```json
{
  "message": "Thank you for your feedback!",
  "feedback": {
    "id": 1,
    "user_id": 123,
    "user_name": "Dr. John Doe",
    "user_email": "john@example.com",
    "rating": 5,
    "category": "Bug Report",
    "feedback_message": "The app crashes when...",
    "created_at": "2024-05-13T10:30:00"
  }
}
```

**Error Responses:**
- 400: Invalid input (missing fields, invalid rating)
- 401: Unauthorized (invalid token)
- 500: Server error

### 2. Get User's Feedback

**GET** `/api/feedback`

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "feedbacks": [
    {
      "id": 1,
      "user_id": 123,
      "user_name": "Dr. John Doe",
      "user_email": "john@example.com",
      "rating": 5,
      "category": "Bug Report",
      "feedback_message": "The app crashes when...",
      "created_at": "2024-05-13T10:30:00"
    }
  ],
  "count": 1
}
```

### 3. Get All Feedback (Admin)

**GET** `/api/admin/feedback`

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "feedbacks": [...],
  "count": 25
}
```

## Verification Checklist

- [ ] Feedback table exists in PostgreSQL
- [ ] Backend deployed to Render
- [ ] POST /api/submit_feedback endpoint responds with 200
- [ ] Token validation works (401 without token)
- [ ] Feedback data is saved to database
- [ ] Flutter app shows success message
- [ ] Can retrieve feedback via GET endpoints
- [ ] Render logs show POST /submit_feedback 200

## Database Schema

```sql
CREATE TABLE feedback (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  user_name VARCHAR(255) NOT NULL,
  user_email VARCHAR(120) NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  category VARCHAR(50) NOT NULL,
  feedback_message TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for common queries
CREATE INDEX idx_feedback_user_id ON feedback(user_id);
CREATE INDEX idx_feedback_category ON feedback(category);
CREATE INDEX idx_feedback_created_at ON feedback(created_at DESC);
```

## Troubleshooting

### "Thank you for your feedback!" but no data in database

1. Check backend logs on Render
2. Verify token is valid (check Authorization header)
3. Verify rating is between 1-5
4. Verify feedback_message is not empty

### "Authentication required" error

1. Ensure user is logged in
2. Token may have expired - logout and login again
3. Check if token is being passed correctly in Authorization header

### Feedback table not found

1. Run `python create_feedback_table.py`
2. Or restart Render app to trigger `db.create_all()`

### 500 Server Error

1. Check Render logs for detailed error
2. Verify database connection is working
3. Verify feedback model is imported correctly

## Next Steps

1. Add admin dashboard to view all feedback
2. Add email notifications when feedback is received
3. Add feedback analytics (ratings distribution, top issues)
4. Add ability to mark feedback as resolved
5. Add export feedback to CSV

