## Languages support

Language support has been added in a simple and easy way to maintain or add new languages.

### Localization Infrastructure

- 3 languages: English (base), Spanish, French
- 2 files per language: Localizable.strings (app strings), Main.strings (storyboard UI strings)
- Items localized: tooltips, segmented controls (tabs titles and tooltips), menu items, error messages.

### UI Implementation

- 4 tabs: Overview, Displays, Storage, Support
- Fixed window layout with segmented control navigation (tabs)
- Hover tooltips for expanded information.

### New files

Created en.lproj, es.lproj and fr.lproj directories with:

- Localizable.strings - application UI strings
- Main.strings - storyboard interface elements
- Project configuration: Updated project.pbxproj to register English, Spanish and French as supported languages
- Added storage.available localization key to
	- en.lproj/Localizable.strings ("Available")
	- es.lproj/Localizable.strings ("Disponible")
	- fr.lproj/Localizable.strings ("Disponible")
- Replaced hardcoded "Available" with `NSLocalizedString("storage.available", comment: "Available storage label")` in the HardwareCollector.swift file.

### Localize tabs titles and tooltips

Tab segment titles and tooltips remained hardcoded in English regardless of macOS language setting. NSSegmentedControl doesn't auto-localize labels set in Interface Builder.

- WindowController.swift: Added `localizeSegmentedControl()` method called from `windowDidLoad()`. Programmatically applies localized strings via `setLabel(_:forSegment:)` and `setToolTip(_:forSegment:)`

```swift
private func localizeSegmentedControl() {
    guard let segmentedControl = segmentedControl else { return }
    
    let titles = [
        NSLocalizedString("segment.title.overview", comment: "Overview segment title"),
        NSLocalizedString("segment.title.displays", comment: "Displays segment title"),
        // ...
    ]
    
    for index in 0..<segmentedControl.segmentCount {
        segmentedControl.setLabel(titles[index], forSegment: index)
        segmentedControl.setToolTip(tooltips[index], forSegment: index)
    }
}
```

### Screenshots

![English](Images/English.png)

![Spanish](Images/Spanish.png)

![French](Images/French.png)
