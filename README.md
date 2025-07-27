# MovieExplorer
Movie App build in IOS (Swift) User can search, add movie to favourites.
Movie Explorer is a Swift-based iOS application that allows users to discover trending, popular, and top-rated movies using a beautiful interface with seamless navigation and performance. The app includes features like favorites management, local notifications, onboarding tips, custom alerts, network handling, and more.

📱 Features
🔍 Movie Browsing
Browse trending, popular, and top-rated movies.
Detail screen with extended information like title, overview, release date, and poster.
Navigation powered via UINavigationController.

❤️ Favorites
Users can mark/unmark a movie as favorite.
Favorite tab to view saved movies.
Favorite button toggles with red tint when selected.

📡 Network Handling
Uses URLSession for API calls.
Centralized NetworkManager with generics for decoding responses.
Custom NetworkError enum for clear error handling.
Internet connectivity check using Alamofire's NetworkReachabilityManager.

🚨 Custom Alert & Loader
Unified UIViewController extension to present in-built UIAlertController for errors.
Custom loader view displayed during API calls and hidden after completion.

🔔 Local Notification
Sends local notification (e.g., "Check your favorites!").
Redirects to the Favorites tab when the user taps the notification.

🧠 First-Time Feature Tips
UserDefaultsManager to track onboarding steps.
On the first visit to a detail screen, a tip label is shown for 5 seconds.
Includes a shake animation (CAKeyframeAnimation) to draw attention.
Favorite button auto-updates with red tint as a visual demo.

🧰 Code Architecture
Clean MVC pattern with modular separation.
Diffable Data Source used with UICollectionView for efficient UI updates.
Constants used for managing tokens, keys, and reuse identifiers.

<p float="left">
  <img src="https://github.com/user-attachments/assets/a45270f5-1c1c-4b02-80d0-8ec41d986d84" width="160" style="margin-right:10px;" />
  <img src="https://github.com/user-attachments/assets/30ffa743-1e52-40d7-a8ae-284d5ac11ac8" width="160" style="margin-right:10px;" />
  <img src="https://github.com/user-attachments/assets/2a1015f4-ec74-43b0-9a75-d6896f3eeac5" width="160" style="margin-right:10px;" />
  <img src="https://github.com/user-attachments/assets/00de0c74-f009-486b-bb08-47231a7240b0" width="160" style="margin-right:10px;" />
  <img src="https://github.com/user-attachments/assets/b610e22f-1dc1-4152-a940-805b31bf434b" width="160" style="margin-right:10px;" />
    <img src="https://github.com/user-attachments/assets/73626581-03c4-4338-8589-620b004e7e72" width="160" style="margin-right:10px;" />
</p>
 Dark Theme
<p float="left">
<img width="160" style="margin-right:10px;" src="https://github.com/user-attachments/assets/37a9cfd1-2c10-4a69-b095-8d339a5da003" />
<img width="160" style="margin-right:10px;" src="https://github.com/user-attachments/assets/0b5cd2e0-4ea6-4349-9345-235327665364" />
<img width="160" style="margin-right:10px;" src="https://github.com/user-attachments/assets/c9f5dcba-ac92-48ce-9fd3-219a923923af" />
<img width="160" style="margin-right:10px;" src="https://github.com/user-attachments/assets/583a7398-deb6-408d-91e3-45ec24a76cba" />
<img width="160" style="margin-right:10px;" src="https://github.com/user-attachments/assets/4e218772-b5a8-4677-a08f-8bbce56c4a11" />
</p>


