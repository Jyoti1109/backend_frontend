# Onboarding - Category Selection Feature

## Overview
First-time onboarding page allowing users to select news categories to personalize their feed.

## Implementation

### ChooseTopicsScreen Features
- **Header**: Title, subtitle, and skip link
- **Search Bar**: Optional search functionality for topics
- **Category Grid**: 2-column grid with selectable chips
- **Multi-select**: Up to 8 categories, minimum 1 required
- **Continue Button**: Disabled until minimum selection met
- **Preselection**: Community category preselected as popular choice

### Technical Architecture

#### Components
```
lib/features/onboarding/presentation/screens/
├── onboarding_screen.dart          # Welcome slides
└── choose_topics_screen.dart       # Category selection

lib/core/services/
├── api_service.dart               # API endpoints
└── preferences_service.dart       # Local storage
```

#### API Integration
- **GET /categories**: Fetch available categories
- **POST /user/preferences**: Save selected categories
- **Offline Support**: Queue sync when offline, use local storage

#### Local Persistence
- `PreferencesService.saveSelectedCategories()`
- `PreferencesService.setOnboardingCompleted()`
- Mock implementation ready for SharedPreferences

### User Experience Flow
1. **Welcome Slides** → Category Selection
2. **Category Selection**:
   - Load categories from API (fallback to local data)
   - Preselect "Community" category
   - Allow search and multi-select (1-8 categories)
   - Save locally + sync with server
   - Navigate to main app

### Accessibility Features
- Semantic labels on all interactive elements
- Screen reader friendly category chips
- Clear selection state indicators
- Keyboard navigation support

### Analytics Events
- `onboarding_categories_opened`: Screen viewed
- `category_selected`: Category toggled (with category_id)
- `onboarding_categories_continue`: Completed with selections
- `onboarding_categories_skipped`: User skipped selection
- `preferences_saved`: Data persisted (source: local/server)

### Visual States

#### Empty State
- No categories loaded
- Search with no results
- Loading indicator

#### Partial Selection
- Some categories selected (< 8)
- Continue button enabled (≥ 1)
- Selection counter displayed

#### Fully Selected
- Maximum 8 categories selected
- Additional selections disabled
- Visual feedback for limit reached

### Error Handling
- API failures fall back to cached/sample data
- Offline mode queues server sync
- Local storage always works as backup
- Graceful degradation for network issues

### Design System
- Uses `ThemeTokens` for consistent styling
- Dark theme with green accent (#4CAF50)
- Material Design 3 components
- Responsive grid layout

## QA Checklist

### Functionality
- [ ] Categories load from API with fallback
- [ ] Search filters categories correctly
- [ ] Multi-select works (1-8 limit enforced)
- [ ] Community category preselected
- [ ] Continue button state updates correctly
- [ ] Skip link works
- [ ] Local storage persists selections
- [ ] Server sync attempts when online

### Accessibility
- [ ] All chips have semantic labels
- [ ] Continue button has descriptive label
- [ ] Screen reader announces selection state
- [ ] Keyboard navigation works
- [ ] Focus indicators visible

### Analytics
- [ ] Screen open event fires
- [ ] Category selection events track
- [ ] Continue/skip events fire with data
- [ ] Preferences saved events track source

### Visual Design
- [ ] Grid layout responsive
- [ ] Selected state clearly visible
- [ ] Disabled state for max selections
- [ ] Loading states smooth
- [ ] Error states informative

### Edge Cases
- [ ] No network connection
- [ ] API returns empty categories
- [ ] Search with no results
- [ ] Rapid selection/deselection
- [ ] App backgrounding during save

## Future Enhancements
- SharedPreferences integration
- Category icons/images
- Recommended categories based on location
- Social category suggestions from friends
- Advanced search with filters
- Category popularity indicators