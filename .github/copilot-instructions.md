# Copilot instructions — About This Hack

Short, actionable notes to help an AI coding assistant be productive in this repo.

- **Repo type & entrypoint:** macOS app (Swift + some Objective-C) located in `About This Hack/`. Open in Xcode using the `.xcodeproj` or `.xcworkspace` at repository root.

- **Quick build & inspect commands:**
  - List workspace schemes: `xcodebuild -list -workspace "About This Hack.xcworkspace"`
  - Build Debug: `xcodebuild -workspace "About This Hack.xcworkspace" -scheme "About This Hack" -configuration Debug build`
  - If unsure where the built .app is: check Xcode DerivedData or inspect `Build/Products/Debug` inside DerivedData.
  - Use `git grep "HardwareCollector\|WindowController\|ViewController" -n` to find UI/hardware related code quickly.

- **Big picture architecture:**
  - UI and app sources live in `About This Hack/` (many files named `ViewController*.swift`, `WindowController.swift`, `ViewController.swift`). The project splits view responsibilities across multiple `ViewController*` files rather than many small view classes — when changing UI behavior search all `ViewController*` files.
  - Hardware and system data are collected via a singleton `HardwareCollector` (see `About This Hack/HardwareCollector.swift`) which reads pre-generated data files (paths are defined in `InitGlobalVariables.swift`). The collector uses caching and a serial queue to avoid races (`getAllData()`); preserve this ordering when modifying collection logic.
  - There is Objective‑C interop via `About This Hack-Bridging-Header.h` (imports `ObjCSIP.h`) — changing ObjC interfaces requires updating the bridging header and rebuilding.
  - `Shell.swift` runs shell commands via `/bin/zsh` with `run(_:)` — treat all inputs as untrusted and avoid constructing commands from unsanitized user input.

- **Key files & what they show:**
  - `About This Hack/HardwareCollector.swift` — central data aggregator and cache. Look here for display, storage, and device info logic.
  - `About This Hack/ViewControllerDisplays.swift` — mapping of device/display names to `Assets.xcassets` image names (e.g., `LG4K`, `genericLCD`). Good example for making UI image changes.
  - `About This Hack/WindowController.swift` — window/tab setup and `localizeSegmentedControl()` (localization applied programmatically).
  - `Localization/LOCALIZATION.md` and `*.lproj/` — shows how strings are organized (`Localizable.strings`, `Main.strings`) and how segment titles/tooltips are localized.
  - `About This Hack-Bridging-Header.h`, `ObjCSIP.h/.m` — Objective‑C SIP helpers; be careful when modifying system-level checks.
  - `About_This_Hack.entitlements` and `Info.plist` — permissions and entitlements; update together when changing capabilities.

- **Patterns & conventions to follow:**
  - Singletons are used widely (e.g., `HardwareCollector.shared`, `HCGPU.shared`). Prefer using existing singletons for shared state rather than introducing new global state.
  - UI logic is often split across many files with shared responsibilities — search for similarly named files rather than assuming a one-file-per-view pattern.
  - Localization: some UI labels are set in Interface Builder, others are applied programmatically (`localizeSegmentedControl()`). When editing UI text, update both `*.lproj` files and the code that sets segmented labels/tooltips.
  - Avoid manual `project.pbxproj` edits unless necessary — use Xcode for file references and project settings.

- **Integration points & cautions:**
  - Shell commands (`Shell.swift`) and generated files (`CreateDataFiles.swift`) are integration surfaces — changes here affect data shown by `HardwareCollector` and can affect user machines. Prefer read-only analysis first.
  - Auto-updater / network calls are handled in `UpdateController.swift` — review before modifying update logic or endpoints.
  - Many features rely on precomputed text files (paths in `InitGlobalVariables.swift`). When adding or renaming collection outputs, update `InitGlobalVariables.swift` and any code that reads those files.

- **Small examples:**
  - To change how display icons are chosen, edit `setDisplayImage(_:for:)` in `About This Hack/ViewControllerDisplays.swift` and add a corresponding image in `About This Hack/Assets.xcassets`.
  - To add a localized segment title, add the key to `en.lproj/Localizable.strings` and update `localizeSegmentedControl()` in `WindowController.swift`.

- **When opening PRs / making changes:**
  - Keep changes small and focused; UI behaviour spans multiple files.
  - If you change data collection outputs, include a note showing how `InitGlobalVariables.swift` and `HardwareCollector.swift` were updated.

If anything here is unclear or you want more detail on a particular sub-area (build steps, update server, auto-updater, or hardware collection details), tell me which area and I'll expand or extract exact call sites and commands.
