# 📱 iOS Learning App (SwiftUI + SwiftData)

A modern, playful iOS To-Do & Activity Tracker application built with **SwiftUI**, **SwiftData**, and **MVVM Architecture** featuring a bold **Neo-Brutalist / Cartoonish Pop** design aesthetic.

---

## ✨ Features

- **🎨 Neo-Brutalist / Cartoonish UI**: Bold outlines, hard offset shadows, vibrant pastel palettes, and bouncy tactile buttons.
- **📑 Activity & Task Manager**: Create, list, and delete activities and tasks with customizable reminders and priorities.
- **🍔 Custom Drawer Sidebar**: Slide-in navigation drawer with user profile badges, menu counters, and pure Apple SF Symbols vector icons.
- **💾 Local Persistence (SwiftData)**: Modern native database storage with `@Model` and `@Query` reactive updates.
- **🧭 Clean Architecture**: Structured folder hierarchy following the **MVVM** pattern for readability and maintainability.

---

## 📂 Project Structure

```text
learning/
├── App/
│   └── learningApp.swift           # Application entry point (@main & ModelContainer)
├── Models/
│   └── Item.swift                  # SwiftData schema definition (@Model)
├── Views/
│   ├── ContentView.swift           # Main activity list screen with Hamburger navigation
│   ├── AddActivity.swift           # To-Do creation form modal sheet
│   └── SidebarView.swift           # Custom cartoon-styled slide-in navigation drawer
├── ViewModels/                     # Business logic and state management
├── Services/                       # Service layer (API & Data managers)
└── Resources/
    └── Assets.xcassets             # Colors, Icons, and Media Assets
```

---

## 🛠️ Tech Stack & Requirements

| Component | Specification |
| :--- | :--- |
| **Language** | Swift |
| **UI Framework** | SwiftUI |
| **Database** | SwiftData |
| **Design System** | Neo-Brutalist / Pop-Cartoon Vector |
| **IDE** | Xcode |
| **Platform** | iOS / iPadOS / macOS |

---

## 🚀 Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/USERNAME/learning-ios.git
   cd learning-ios
   ```

2. **Open in Xcode:**
   ```bash
   open learning.xcodeproj
   ```

3. **Build & Run:**
   - Select your target simulator (e.g., `iPhone 17 Pro`).
   - Press `Cmd + R` to compile and run.

---

## 👨‍💻 Author

- **Herlambang**
