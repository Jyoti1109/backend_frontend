# Good News App - Mobile API Endpoints Documentation

## Overview
This document explains all API endpoints available in the Good News App system and their specific usage in mobile app development. Each endpoint includes purpose, parameters, responses, and mobile implementation guidance.

---

## Authentication Endpoints

### 1. User Registration
**Endpoint:** `POST /api/v1/register`

**What it does:** Creates new user account with email/password authentication

**Mobile App Usage:**
- **Registration Screen**: Collect user email, password, display name, phone number
- **Validation**: Implement client-side email format validation and 6+ character password requirement
- **Success Flow**: Store returned token securely, navigate to main app
- **Error Handling**: Display specific error messages for email conflicts or validation failures

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "display_name": "John Doe",
  "phone_number": "+1234567890"
}
```

**Response:**
```json
{
  "message": "User registered successfully",
  "user_id": 123,
  "token": "session_token_here"
}
```

### 2. User Login
**Endpoint:** `POST /api/v1/login`

**What it does:** Authenticates existing user and returns session token

**Mobile App Usage:**
- **Login Screen**: Email/password input form
- **Token Storage**: Save token in secure storage (Keychain/Keystore)
- **Auto-Login**: Use stored token for subsequent API calls
- **Session Management**: Handle token expiration and re-authentication

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

### 3. User Logout
**Endpoint:** `POST /api/v1/logout`

**What it does:** Invalidates current session token

**Mobile App Usage:**
- **Logout Button**: Clear stored token and redirect to login
- **Security**: Always call this endpoint when user logs out
- **Token Cleanup**: Remove token from secure storage

---

## User Profile Management

### 4. Get User Profile
**Endpoint:** `GET /api/v1/user/profile`

**What it does:** Retrieves current user's profile information

**Mobile App Usage:**
- **Profile Screen**: Display user information
- **Settings Page**: Show current profile data for editing
- **User Avatar**: Use display_name for user identification

**Response:**
```json
{
  "id": 123,
  "email": "user@example.com",
  "display_name": "John Doe",
  "phone_number": "+1234567890",
  "created_at": "2025-01-11T10:30:00"
}
```

### 5. Update User Profile
**Endpoint:** `PUT /api/v1/user/profile`

**What it does:** Updates user's display name and phone number

**Mobile App Usage:**
- **Edit Profile Screen**: Allow users to modify display name and phone
- **Form Validation**: Implement client-side validation before submission
- **Success Feedback**: Show confirmation message after successful update

---

## User Preferences & Personalization

### 6. Get User Preferences
**Endpoint:** `GET /api/v1/user/preferences`

**What it does:** Retrieves user's selected news categories

**Mobile App Usage:**
- **Onboarding Flow**: Show category selection during first-time setup
- **Settings Screen**: Display current category preferences
- **Personalized Feed**: Use preferences to customize content

**Response:**
```json
[1, 3, 5, 7]
```

### 7. Set User Preferences
**Endpoint:** `POST /api/v1/user/preferences`

**What it does:** Updates user's news category preferences

**Mobile App Usage:**
- **Category Selection**: Multi-select interface for news categories
- **Onboarding**: Set initial preferences during user setup
- **Settings Update**: Allow users to modify preferences anytime

**Request Body:**
```json
{
  "category_ids": [1, 3, 5, 7]
}
```

### 8. Get User Stats
**Endpoint:** `GET /api/v1/user/stats`

**What it does:** Retrieves user activity statistics

**Mobile App Usage:**
- **Profile Dashboard**: Show user engagement metrics
- **Gamification**: Display posts count, articles read, likes received
- **Progress Tracking**: Motivate user engagement with statistics

**Response:**
```json
{
  "posts_count": 15,
  "read_articles": 127,
  "likes_received": 45,
  "comments_received": 23
}
```

---

## News & Articles

### 9. Get Categories
**Endpoint:** `GET /api/v1/categories`

**What it does:** Retrieves all available news categories (cached for performance)

**Mobile App Usage:**
- **Category Filter**: Dropdown/picker for filtering news
- **Preference Selection**: Show available categories for user selection
- **Navigation Menu**: Category-based news browsing

**Response:**
```json
[
  {
    "id": 1,
    "name": "Technology",
    "description": "Tech news and innovations"
  }
]
```

### 10. Get Articles
**Endpoint:** `GET /api/v1/articles`

**What it does:** Retrieves news articles with optional category filtering

**Mobile App Usage:**
- **News Feed**: Main article listing with pagination
- **Category Filtering**: Filter articles by specific category
- **Infinite Scroll**: Use limit/offset for pagination
- **AI Indicators**: Show AI enhancement badges based on content field

**Parameters:**
- `limit`: Number of articles (default: 20, max: 100)
- `offset`: Pagination offset (default: 0)
- `category_id`: Filter by category (optional)

**Response:**
```json
[
  {
    "id": 123,
    "title": "Original Title",
    "rewritten_headline": "AI Enhanced Headline",
    "rewritten_summary": "Article summary",
    "content": "Display content with [AI] tag if applicable",
    "source_url": "https://source.com",
    "image_url": "https://image.com/img.jpg",
    "category_id": 1,
    "sentiment": "POSITIVE",
    "created_at": "2025-01-11T10:30:00",
    "is_ai_rewritten": 1
  }
]
```

### 11. Get Articles by Category
**Endpoint:** `GET /api/v1/categories/{category_id}/articles`

**What it does:** Retrieves articles for specific category

**Mobile App Usage:**
- **Category Pages**: Dedicated screens for each news category
- **Filtered Views**: Show only articles from selected category
- **Category Navigation**: Browse news by topic

**Parameters:**
- `limit`: Number of articles (default: 20, max: 100)
- `offset`: Pagination offset (default: 0)

### 12. Get Personalized Feed (For You)
**Endpoint:** `GET /api/v1/user/for-you`

**What it does:** Retrieves personalized articles based on user preferences

**Mobile App Usage:**
- **For You Tab**: Main personalized news feed
- **Smart Recommendations**: AI-curated content based on user interests
- **Positive Focus**: Shows positive sentiment articles from preferred categories

**Parameters:**
- `limit`: Number of articles (default: 20, max: 100)
- `offset`: Pagination offset (default: 0)

---

## Social Features - Posts

### 13. Create Post
**Endpoint:** `POST /api/v1/posts`

**What it does:** Creates new user post with optional image

**Mobile App Usage:**
- **Create Post Screen**: Text input with optional image upload
- **Image Support**: Allow users to attach images via image_url
- **Visibility Control**: Public/friends visibility options
- **Rich Content**: Support for formatted text content

**Request Body:**
```json
{
  "title": "Post Title",
  "content": "Post content here",
  "visibility": "public",
  "image_url": "/uploads/posts/image.jpg"
}
```

### 14. Get Posts
**Endpoint:** `GET /api/v1/posts`

**What it does:** Retrieves social posts with like status for current user

**Mobile App Usage:**
- **Social Feed**: Main social posts timeline
- **Like Status**: Shows if current user has liked each post
- **Engagement Metrics**: Display likes_count and comments_count
- **User Attribution**: Show post author's display_name

**Parameters:**
- `limit`: Number of posts (default: 20, max: 100)
- `offset`: Pagination offset (default: 0)
- `visibility`: Filter by visibility ('public' is default)

**Response:**
```json
[
  {
    "id": 456,
    "title": "Post Title",
    "content": "Post content",
    "user_id": 123,
    "display_name": "John Doe",
    "visibility": "public",
    "created_at": "2025-01-11T10:30:00",
    "image_url": "/uploads/posts/image.jpg",
    "likes_count": 15,
    "comments_count": 8,
    "user_has_liked": true
  }
]
```

### 15. Get Single Post
**Endpoint:** `GET /api/v1/posts/{post_id}`

**What it does:** Retrieves specific post with like status

**Mobile App Usage:**
- **Post Detail Screen**: Full post view with comments
- **Deep Linking**: Direct navigation to specific posts
- **Share Functionality**: Get post details for sharing

### 16. Update Post
**Endpoint:** `PUT /api/v1/posts/{post_id}`

**What it does:** Updates user's own post content

**Mobile App Usage:**
- **Edit Post**: Allow users to modify their own posts
- **Ownership Check**: Only post owner can edit
- **Content Validation**: Sanitize and validate updated content

### 17. Delete Post
**Endpoint:** `DELETE /api/v1/posts/{post_id}`

**What it does:** Deletes user's own post

**Mobile App Usage:**
- **Delete Option**: Long-press or menu option to delete posts
- **Confirmation Dialog**: Confirm deletion before API call
- **Ownership Validation**: Only post owner can delete

---

## Social Features - Interactions

### 18. Like Post
**Endpoint:** `POST /api/v1/posts/{post_id}/like`

**What it does:** Adds like to post and updates like count

**Mobile App Usage:**
- **Like Button**: Heart/thumbs up button on posts
- **Instant Feedback**: Update UI immediately, sync with server
- **Like Counter**: Update likes_count in real-time
- **Duplicate Prevention**: Handle already-liked posts gracefully

**Response:**
```json
{
  "message": "Post liked successfully",
  "likes_count": 16
}
```

### 19. Unlike Post
**Endpoint:** `POST /api/v1/posts/{post_id}/unlike`

**What it does:** Removes like from post and updates count

**Mobile App Usage:**
- **Unlike Button**: Toggle like status
- **UI Updates**: Remove like highlight, decrease counter
- **State Management**: Track like status across app

### 20. Add Comment
**Endpoint:** `POST /api/v1/posts/{post_id}/comments`

**What it does:** Adds comment to post and updates comment count

**Mobile App Usage:**
- **Comment Input**: Text field for adding comments
- **Real-time Updates**: Update comment count immediately
- **Comment Threading**: Build comment system with this endpoint

**Request Body:**
```json
{
  "content": "Great post! Thanks for sharing."
}
```

### 21. Get Comments
**Endpoint:** `GET /api/v1/posts/{post_id}/comments`

**What it does:** Retrieves all comments for a post

**Mobile App Usage:**
- **Comments Section**: Display comments under posts
- **Comment List**: Show author names and timestamps
- **Chronological Order**: Comments ordered by creation time

**Response:**
```json
[
  {
    "id": 789,
    "content": "Great post!",
    "created_at": "2025-01-11T10:35:00",
    "display_name": "Jane Smith"
  }
]
```

---

## Social Features - Friends & Messaging

**⚠️ IMPORTANT: Messaging endpoints are currently disabled for stability reasons**

### 22. Send Friend Request
**Endpoint:** `POST /api/v1/friends/{target_user_id}/request`

**What it does:** Sends friend request to another user

**Mobile App Usage:**
- **Add Friend Button**: Send friend requests from user profiles
- **User Discovery**: Connect with other users
- **Request Management**: Handle pending/accepted/rejected states

### 23. Get Friend Requests
**Endpoint:** `GET /api/v1/friends/requests`

**What it does:** Retrieves pending friend requests for current user

**Mobile App Usage:**
- **Notifications Tab**: Show incoming friend requests
- **Request List**: Display pending requests with user info
- **Action Buttons**: Accept/reject options for each request

### 24. Accept Friend Request
**Endpoint:** `POST /api/v1/friends/requests/{request_id}/accept`

**What it does:** Accepts friend request and creates friendship

**Mobile App Usage:**
- **Accept Button**: Confirm friend request
- **Friendship Creation**: Establish bidirectional friendship
- **Notification System**: Notify sender of acceptance

### 25. Reject Friend Request
**Endpoint:** `POST /api/v1/friends/requests/{request_id}/reject`

**What it does:** Rejects friend request

**Mobile App Usage:**
- **Reject Button**: Decline friend request
- **Clean Rejection**: Remove request without creating friendship

### 26. Get Friends List
**Endpoint:** `GET /api/v1/friends`

**What it does:** Retrieves user's accepted friends

**Mobile App Usage:**
- **Friends List**: Display all connected friends
- **Friend Profiles**: Navigate to friend profiles
- **Social Features**: Enable friend-specific functionality

### 27. Search Users
**Endpoint:** `GET /api/v1/users/search?q={query}`

**What it does:** Searches users by display name or email

**Mobile App Usage:**
- **User Search**: Find users to connect with
- **Search Bar**: Real-time search as user types
- **Friend Discovery**: Suggest users to add as friends

### 28. Block User
**Endpoint:** `POST /api/v1/friends/{target_user_id}/block`

**What it does:** Blocks user and removes all connections

**Mobile App Usage:**
- **Block Option**: Safety feature to block problematic users
- **Relationship Cleanup**: Removes friendships and requests
- **Privacy Protection**: Prevent blocked users from interacting

### 29. Get Blocked Users
**Endpoint:** `GET /api/v1/blocks`

**What it does:** Retrieves list of blocked users

**Mobile App Usage:**
- **Blocked List**: Show currently blocked users
- **Unblock Option**: Allow users to unblock if needed
- **Privacy Settings**: Part of user safety controls

---

## User Activity Tracking

### 30. Track Article Read
**Endpoint:** `POST /api/v1/user/read-article`

**What it does:** Records that user read an article

**Mobile App Usage:**
- **Reading Analytics**: Track user engagement with articles
- **Progress Tracking**: Monitor reading habits
- **Recommendation Engine**: Improve content suggestions

**Request Body:**
```json
{
  "article_id": 123
}
```

### 31. Add to Reading History
**Endpoint:** `POST /api/v1/user/history`

**What it does:** Adds article to user's reading history

**Mobile App Usage:**
- **History Tracking**: Maintain list of read articles
- **Offline Reading**: Sync reading history when online
- **User Analytics**: Track reading patterns

### 32. Get Reading History
**Endpoint:** `GET /api/v1/user/history`

**What it does:** Retrieves user's reading history

**Mobile App Usage:**
- **History Tab**: Show previously read articles
- **Quick Access**: Re-read favorite articles
- **Reading Progress**: Track user engagement

### 33. Add to Favorites
**Endpoint:** `POST /api/v1/user/favorites`

**What it does:** Adds article to user's favorites

**Mobile App Usage:**
- **Bookmark Feature**: Save articles for later reading
- **Favorite Button**: Heart/star icon on articles
- **Personal Collection**: Build user's article collection

### 34. Get Favorites
**Endpoint:** `GET /api/v1/user/favorites`

**What it does:** Retrieves user's favorite articles

**Mobile App Usage:**
- **Favorites Tab**: Show bookmarked articles
- **Quick Access**: Easy access to saved content
- **Personal Library**: User's curated article collection

### 35. Remove from Favorites
**Endpoint:** `DELETE /api/v1/user/favorites/{article_id}`

**What it does:** Removes article from favorites

**Mobile App Usage:**
- **Unfavorite Button**: Remove bookmark from articles
- **Favorites Management**: Clean up saved articles
- **Toggle Functionality**: Add/remove favorites easily

---

## Public Access (No Authentication)

### 36. Get Public News
**Endpoint:** `GET /api/v1/public/news`

**What it does:** Retrieves news articles without authentication

**Mobile App Usage:**
- **Guest Mode**: Allow non-registered users to browse news
- **App Preview**: Show content before user registration
- **Public Feed**: Demonstrate app value to potential users

**Parameters:**
- `limit`: Number of articles (default: 20, max: 100)
- `offset`: Pagination offset (default: 0)
- `category_id`: Filter by category (optional)

**Response:**
```json
{
  "articles": [
    {
      "id": 123,
      "title": "Original Title",
      "headline": "AI Enhanced Headline",
      "rewritten_summary": "Article summary",
      "content": "Display content with [AI] tag if applicable",
      "source_url": "https://source.com",
      "image_url": "https://image.com/img.jpg",
      "category_id": 1,
      "category_name": "Technology",
      "sentiment": "POSITIVE",
      "created_at": "2025-01-11T10:30:00",
      "is_ai_rewritten": 1
    }
  ],
  "categories": [
    {"id": 1, "name": "Technology"},
    {"id": 2, "name": "Health"}
  ],
  "total": 50,
  "limit": 20,
  "offset": 0
}
```

### 37. Get Public Categories
**Endpoint:** `GET /api/v1/public/categories`

**What it does:** Retrieves categories without authentication

**Mobile App Usage:**
- **Guest Browsing**: Category filtering for non-authenticated users
- **App Demo**: Show category organization to visitors

---

## Unified Social + News Feed (CRITICAL FOR INFINITE SWIPE)

### 38. Get Unified Feed
**Endpoint:** `GET /api/v1/feed`

**What it does:** Combines social posts and news articles in single feed with cursor-based pagination

**Mobile App Usage - INFINITE SWIPE SOLUTION:**
- **Main Feed**: Primary app screen combining social and news content
- **Infinite Scrolling**: Use cursor-based pagination for seamless scrolling
- **Content Mixing**: Shows both user posts and news articles
- **Prefetching**: Load next batch when 5 items remain
- **Smooth UX**: No pagination breaks, continuous content flow
- **Category Filtering**: Filter articles by specific category while maintaining unified feed

**Parameters:**
- `type`: Filter by 'post' or 'article' (optional)
- `limit`: Items per request (default: 20, max: 50)
- `cursor`: Pagination cursor from previous response
- `category_id`: Filter articles by specific category (optional - if not provided, uses user preferences)

**Response:**
```json
{
  "items": [
    {
      "type": "post",
      "id": 456,
      "title": "User Post Title",
      "content": "Post content",
      "author": "John Doe",
      "created_at": "2025-01-11T10:30:00",
      "likes_count": 15,
      "comments_count": 8
    },
    {
      "type": "article",
      "id": 123,
      "title": "News Article Title",
      "content": "Article content with [AI] tag",
      "author": "News Source",
      "created_at": "2025-01-11T10:25:00",
      "source_url": "https://source.com",
      "image_url": "https://image.com/img.jpg",
      "likes_count": 0,
      "comments_count": 0
    }
  ],
  "next_cursor": "2025-01-11T10:25:00_123",
  "has_more": true
}
```

**Mobile Implementation for Infinite Swipe:**
```javascript
// Infinite scroll implementation
let isLoading = false;
let nextCursor = null;

async function loadMoreContent() {
  if (isLoading) return;
  isLoading = true;
  
  const url = `/api/v1/feed?limit=20${nextCursor ? `&cursor=${nextCursor}` : ''}`;
  const response = await fetch(url, {
    headers: { 'Authorization': `Bearer ${userToken}` }
  });
  
  const data = await response.json();
  
  // Append new items to feed
  appendItemsToFeed(data.items);
  
  // Update cursor for next request
  nextCursor = data.next_cursor;
  isLoading = false;
  
  // Prefetch next batch if near end
  if (getRemainingItems() <= 5 && data.has_more) {
    loadMoreContent();
  }
}
```

---

## File Upload

### 39. Upload Post Image
**Endpoint:** `POST /api/v1/posts/upload`

**What it does:** Uploads image for posts

**Mobile App Usage:**
- **Image Picker**: Camera/gallery integration
- **Post Creation**: Attach images to posts
- **File Validation**: Check file types and sizes
- **Progress Indicator**: Show upload progress

**Request:** Multipart form data with 'image' field

**Response:**
```json
{
  "message": "Image uploaded successfully",
  "image_url": "/uploads/posts/unique_filename.jpg"
}
```

---

## Notifications

### 40. Get Notifications
**Endpoint:** `GET /api/v1/notifications`

**What it does:** Retrieves user notifications

**Mobile App Usage:**
- **Notifications Tab**: Show friend requests, likes, comments
- **Push Notifications**: Integrate with mobile push services
- **Badge Counts**: Show unread notification counts

### 41. Mark Notification Read
**Endpoint:** `POST /api/v1/notifications/{notification_id}/read`

**What it does:** Marks specific notification as read

**Mobile App Usage:**
- **Read Status**: Update notification appearance when read
- **Notification Management**: Track read/unread status

### 42. Mark All Notifications Read
**Endpoint:** `POST /api/v1/notifications/read-all`

**What it does:** Marks all notifications as read

**Mobile App Usage:**
- **Clear All**: Bulk action to clear notification badges
- **Notification Cleanup**: Reset unread counts

---

## System Endpoints

### 43. Health Check
**Endpoint:** `GET /api/v1/health`

**What it does:** Checks API system health

**Mobile App Usage:**
- **Connectivity Check**: Verify API availability
- **Error Handling**: Detect system outages
- **App Diagnostics**: System status monitoring

### 44. Contact Form
**Endpoint:** `POST /api/v1/contact`

**What it does:** Submits contact/feedback form

**Mobile App Usage:**
- **Feedback Screen**: User feedback and support requests
- **Contact Form**: General inquiries and suggestions
- **User Engagement**: Collect user input and interests

---

## Additional System Endpoints

### 46. Root Page
**Endpoint:** `GET /`

**What it does:** Serves main landing page (index.html)

**Mobile App Usage:**
- **Web Fallback**: Fallback for web browser access
- **Landing Page**: Main website entry point

### 47. News Page
**Endpoint:** `GET /news`

**What it does:** Serves public news feed page (news.html)

**Mobile App Usage:**
- **Web Interface**: Browser-based news reading
- **Public Access**: No authentication required

### 48. File Upload Access
**Endpoint:** `GET /uploads/<path:filename>`

**What it does:** Serves uploaded files (images, etc.)

**Mobile App Usage:**
- **Image Display**: Access uploaded post images
- **File Serving**: Static file access for media content

### 49. Basic Health Check
**Endpoint:** `GET /health`

**What it does:** Basic API health status (different from /api/v1/health)

**Mobile App Usage:**
- **Simple Health Check**: Basic connectivity test
- **Load Balancer**: Health check for infrastructure

---

## Admin Endpoints (Restricted)

### 50. Admin Dashboard
**Endpoint:** `GET /api/v1/admin/dashboard`

**What it does:** Retrieves admin statistics (requires admin token)

**Mobile App Usage:**
- **Admin Panel**: Administrative interface (if needed)
- **System Monitoring**: Track user and content metrics

---

## Disabled Endpoints (Currently Unavailable)

### ❌ Messaging System (Temporarily Disabled)
**Endpoints:**
- `GET /api/v1/conversations`
- `GET /api/v1/conversations/{other_user_id}/messages`
- `POST /api/v1/conversations/{other_user_id}/messages`

**Status:** All return 503 error "Messaging feature temporarily disabled for stability"

**Mobile App Impact:**
- **No Direct Messaging**: Users cannot send private messages
- **Error Handling**: Apps should handle 503 responses gracefully
- **Alternative**: Use public posts or friend requests for communication

---

## Key Mobile App Implementation Notes

### Authentication Flow
1. Use `/api/v1/register` or `/api/v1/login` to get session token
2. Store token securely in device keychain/keystore
3. Include token in all authenticated requests: `Authorization: Bearer {token}`
4. Handle token expiration and re-authentication

### Infinite Swipe Implementation
- **Primary Endpoint**: `/api/v1/feed` with cursor pagination
- **Prefetching Strategy**: Load next batch when 5 items remain
- **Error Handling**: Graceful fallback for network issues
- **State Management**: Track cursor and loading states

### Performance Optimization
- **Caching**: Categories endpoint cached for 1 hour
- **Pagination**: Use appropriate limits (20-50 items)
- **Image Loading**: Lazy load images with placeholders
- **Background Sync**: Sync user actions when connectivity restored

### Content Types
- **Posts**: User-generated social content
- **Articles**: AI-enhanced news content with sentiment analysis
- **Mixed Feed**: Combined social and news content for unified experience

### Error Handling
- **Network Errors**: Retry logic with exponential backoff
- **Authentication Errors**: Redirect to login screen
- **Validation Errors**: Show specific error messages to users
- **Server Errors**: Graceful degradation with offline capabilities

This comprehensive endpoint documentation provides everything needed for mobile app development with the Good News App API system.