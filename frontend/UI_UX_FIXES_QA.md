# UI/UX Fixes - QA Checklist

## 1. Logo Consistency ✅

### AppBar Logo
- [ ] Logo (24-28px) appears in AppBar left side on all screens
- [ ] Logo uses light version (white/green) for dark backgrounds
- [ ] Logo has semantic label "Good News logo" for accessibility
- [ ] Logo is consistent across all screens (Profile, Messages, Social, etc.)

### Empty State Watermarks
- [ ] Faint logo watermark (opacity ~0.1) appears in empty states
- [ ] Watermark visible in My Posts empty state
- [ ] Watermark visible in Messages with no chats
- [ ] Watermark doesn't interfere with empty state text readability

## 2. New Post Screen ✅

### Button States
- [x] Post button disabled until non-whitespace text entered
- [x] Enabled state: filled green (#4CAF50) background
- [x] Disabled state: muted gray background
- [x] Button text remains white in both states
- [x] Loading state shows spinner when posting

### Guidelines Section
- [x] Guidelines section is collapsible (ExpansionTile)
- [x] Guidelines don't push input too far down on small screens
- [x] Guidelines content is concise and readable
- [x] Expansion/collapse animation is smooth

### Keyboard Safety
- [ ] Sheet uses isScrollControlled for full height
- [ ] Input not hidden behind keyboard when typing
- [ ] Content scrollable when keyboard is open
- [ ] resizeToAvoidBottomInset: true works correctly

## 3. Messages & Chat ✅

### Auto-scroll Behavior
- [ ] Chat auto-scrolls only when user is at bottom
- [ ] No auto-scroll when reading old messages (user scrolled up)
- [ ] Scroll position tracking works correctly
- [ ] New message notification when not at bottom (future enhancement)

### Message Bubbles
- [ ] Outgoing bubble: solid green (#4CAF50) with white text (95% opacity)
- [ ] Incoming bubble: dark gray (#1E1E1E) with white text
- [ ] Bubble contrast meets WCAG AA standards
- [ ] Bubble shapes have proper rounded corners
- [ ] Timestamps are readable in both bubble types

### Long-press Menu
- [ ] Long-press on messages shows context menu
- [ ] Copy option available in context menu
- [ ] Copy functionality works (copies to clipboard)
- [ ] Menu dismisses properly after selection
- [ ] Menu styling matches app theme

### Input Bar
- [ ] Input bar not hidden behind keyboard
- [ ] Multi-line text input supported
- [ ] Send button properly positioned
- [ ] Enter key sends message
- [ ] Input bar has proper padding and styling

## 4. Friends Modal ✅

### Onboarding Microcopy
- [x] Clear explanation under "Add Friends" header
- [x] Text: "Grant access to your contacts to find friends on Good News. We only use phone numbers to match and never upload contacts without consent."
- [x] Explanation is concise and builds trust
- [x] Typography is readable and well-spaced

### Permission States
- [ ] Explanation screen shows before permission request
- [ ] Permission denied shows "Try Again" and "Invite via SMS"
- [ ] Permanently denied shows "Open Settings" link
- [ ] Each state has appropriate messaging and actions
- [ ] Fallback options work correctly

### CTA Button
- [ ] "Add Friends" button is full-width
- [ ] Button height is 48px
- [ ] Border radius is 12px
- [ ] Solid green (#4CAF50) background
- [ ] White text with proper contrast
- [ ] Button has semantic label for accessibility

## 5. Profile Screen Hierarchy ✅

### Section Order
- [ ] Profile Card appears first
- [ ] Stats Row appears second
- [ ] Quick Actions section appears third
- [ ] Menu List appears last
- [ ] Sections have proper spacing between them

### Quick Actions
- [ ] Three action cards: New Post, My Posts, Friends
- [ ] Cards are properly sized and aligned
- [ ] Cards have ripple feedback on tap
- [ ] Icons and labels are clear and readable
- [ ] Cards navigate to correct screens/modals

### FAB (Floating Action Button)
- [ ] FAB is 56px diameter
- [ ] FAB positioned bottom-right
- [ ] FAB has green (#4CAF50) background
- [ ] FAB opens New Post bottom sheet
- [ ] FAB has proper elevation and shadow

### Tap Targets
- [ ] All interactive elements ≥48x48 px
- [ ] Avatar tap opens Edit Profile modal
- [ ] Menu items have ripple feedback
- [ ] Quick action cards have proper touch feedback
- [ ] All buttons meet accessibility guidelines

## 6. Onboarding - Category Selection ✅

### Screen Layout
- [x] Header shows "Choose topics you care about"
- [x] Subhead: "Pick a few topics so we show news you'll love"
- [x] Logo (40px) appears at top for branding
- [x] Search bar is functional and crash-free
- [x] Grid layout is responsive and readable

### Category Selection
- [x] Multi-select chips with visual feedback and animations
- [x] Maximum 8 categories enforced
- [x] Minimum 5 categories required
- [x] "Community" preselected to reduce friction
- [x] Selection counter shows current/max selections
- [x] Categories load from API with fallback data

### Continue Button
- [x] Button disabled until minimum requirement met (5 categories)
- [x] Button shows proper enabled/disabled states
- [x] Button text and styling are consistent
- [x] Loading state during save process
- [x] Success feedback after completion

### Skip Functionality
- [x] Skip link appears in header
- [x] Skip bypasses category selection
- [x] Skip still allows app usage
- [x] Skip can be accessed later in settings

### Error Handling
- [x] Loading state with spinner
- [x] Empty state with retry button
- [x] Search empty state with helpful message
- [x] Robust search that doesn't crash
- [x] API fallback to local categories

## 7. Accessibility & QA ✅

### Semantic Labels
- [ ] All icons have semantic labels
- [ ] All buttons have descriptive labels
- [ ] Interactive elements announce their purpose
- [ ] Screen reader navigation works correctly
- [ ] Focus indicators are visible

### Contrast Checks
- [ ] All text passes WCAG AA contrast requirements
- [ ] Button text readable in all states
- [ ] Icon colors have sufficient contrast
- [ ] Disabled states still meet minimum contrast
- [ ] Dark theme maintains proper contrast ratios

### Interactive Elements
- [ ] All touch targets ≥48x48 px
- [ ] Buttons have proper minimum sizes
- [ ] Touch areas don't overlap inappropriately
- [ ] Gesture conflicts resolved (swipe vs tap)
- [ ] Loading states prevent double-taps

### Text Scale Testing
- [ ] UI tested with text scale 1.3x
- [ ] No text overflow at larger scales
- [ ] Layouts adapt to larger text sizes
- [ ] Critical information remains visible
- [ ] Navigation remains functional

## Widget Tests ✅

### New Post Button Test
- [ ] Button disabled when text empty
- [ ] Button enabled when valid text entered
- [ ] Button disabled with only whitespace
- [ ] Button state updates correctly on text change
- [ ] Test covers edge cases

### Onboarding Category Test
- [ ] Continue button disabled initially (if no preselection)
- [ ] Continue button enabled after minimum selection
- [ ] Selection counter updates correctly
- [ ] Maximum selection limit enforced
- [ ] Test covers selection/deselection scenarios

## Performance & Edge Cases

### Loading States
- [ ] All screens show appropriate loading indicators
- [ ] Loading states don't block user interaction unnecessarily
- [ ] Error states provide clear recovery options
- [ ] Offline functionality gracefully degrades
- [ ] Network timeouts handled properly

### Memory Management
- [ ] Controllers properly disposed
- [ ] Listeners removed in dispose methods
- [ ] No memory leaks in navigation
- [ ] Images loaded efficiently
- [ ] Large lists use proper pagination

### Device Compatibility
- [ ] Works on various screen sizes
- [ ] Handles different aspect ratios
- [ ] Keyboard interactions work on all devices
- [ ] Performance acceptable on lower-end devices
- [ ] Battery usage is reasonable

## Final Verification

### Screenshots Required
- [ ] Profile screen with new hierarchy
- [ ] New Post screen (disabled/enabled states)
- [ ] Messages list with logo
- [ ] Chat screen with improved bubbles
- [ ] Friends modal (all permission states)
- [ ] Onboarding category selection
- [ ] Empty states with watermarks

### Code Quality
- [ ] All imports properly organized
- [ ] Theme tokens used consistently
- [ ] No hardcoded colors or sizes
- [ ] Proper error handling implemented
- [ ] Code follows Flutter best practices
- [ ] Documentation updated accordingly