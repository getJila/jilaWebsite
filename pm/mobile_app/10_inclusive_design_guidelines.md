# Jila Mobile App — Inclusive Design Guidelines (Low-Literacy & Cross-Border Users)

> **Status:** Draft (proposed addendum to core UX guidelines)
> 
> **Last updated:** 2025-12-20

## Purpose
Ensure the Jila app’s design is accessible, intuitive, and trustworthy for users with mixed literacy levels and diverse cultural backgrounds. These guidelines distill research-backed recommendations into actionable design practices so that low-literacy users across African markets can use Jila effectively [1]. Each section below includes the recommendation, brief rationale from research, and how it integrates into existing product documentation.

## Typography and Language
- **Required:** Use clear, legible sans-serif fonts at a generous size (≈16px for body text) with sufficient spacing.
  - **Rationale:** Larger, simple text improves readability for users with limited literacy and lets them scan content without strain [2]. (Add to `09_language_and_accessibility.md` under “UI Basics” as typography guidance.)
- **Required:** Write all in-app copy in plain language (short sentences, common words) and avoid jargon or technical terms.
  - **Rationale:** Low-literacy users comprehend simple phrasing more easily, reducing confusion [3]. This also aligns with our existing vocabulary control (no synonyms for key terms) and should be appended to that section [3].
- **Required:** Provide Portuguese as the default language and prepare for easy localization to other languages.
  - **Rationale:** Cross-border African users may speak different languages; externalizing strings (already required [4]) and planning for translation ensures inclusivity. This extends the Localization rules in `09_language_and_accessibility.md`.
- **Optional:** Avoid culturally specific references, idioms, or icons in text.
  - **Rationale:** References that are obvious in one culture can confuse others. Focus on globally understood terms and symbols [5] to keep the app universally clear. (This note can be added as a caution in copy guidelines.)

## Color and Contrast
- **Required:** Adhere to high-contrast color schemes.
  - **Body text** must meet WCAG 2.1 **AAA (≥ 7:1)** for outdoor readability (canonical: UX-P-001 / UX-D-046).
  - **Other UI** must meet WCAG 2.1 **AA minimum**, and prefer AAA for critical alerts/primary CTAs where feasible.
  - **Rationale:** Strong contrast is critical for legibility in low-light or outdoor conditions and for users with limited reading proficiency [6]. This is already a baseline accessibility requirement and must be enforced in visual design specs.
- **Required:** Use color cues that follow common conventions (e.g. red for danger/low, green for safe/OK) paired with icons or labels.
  - **Rationale:** Consistent color associations help quick understanding without reading [7], but color alone must not convey meaning [8] (to aid color-blind users and low-literacy users who might miss subtle cues). For example, a low-water warning should show a red icon and the word “low”. (Update Accessibility section in `09_language_and_accessibility.md` to reinforce color + icon rule [9].)
- **Optional:** Provide a visual theme toggle for extreme conditions (e.g. “high contrast” mode or dark mode).
  - **Rationale:** While not essential for initial launch, offering a high-contrast mode could further assist users with vision or literacy challenges. This can be noted as a future consideration in the design system documentation.

## Illustration and Iconography Use
- **Required:** Use universally recognizable icons or illustrations alongside text for key actions and concepts.
  - **Rationale:** Visual symbols (e.g. a 📦 for orders, a 🚰 for water source) can be understood without reading [7]. Paired with labels, they reinforce meaning and assist users who struggle with text. (This can be added as a new “Iconography” guideline section in `jila_application_ux_guidelines.md`.)
- **Required (canonical style):** Follow the DECIDED mobile illustration language (“Blueprints of Life”) when designing instructional sequences and “how it works” education.
  - **Canonical reference:** `docs/ux/jila_design_guide.md` (Illustration Strategy — “Blueprints of Life”, UX-D-032)
- **Required:** Ensure illustrations and icons are culturally appropriate and tested with local users.
  - **Rationale:** Imagery should reflect the user’s world – for example, using a familiar style of water container or truck. Avoid imagery that could be offensive or confusing in African contexts. (Include this note in the iconography guidelines as a required research/UX testing step.)
- **Optional:** Use storyboards or pictorial sequences to explain complex flows (especially during onboarding or help screens).
  - **Rationale:** A series of images can guide users through a process without heavy text, as research shows purely visual instructions can replace text-heavy explanations [10]. For instance, depicting “How to add a reservoir” in 3 pictures. (This could be an addendum to onboarding guidelines, marked as a recommended enhancement for user education.)
- **Optional:** Replace text-heavy error messages with icons/visual cues plus minimal text.
  - **Rationale:** Instead of a long error dialog, a warning ⚠️ icon with a short phrase (“No connection”) is easier to grasp for low-literacy users [11]. This aligns with using icons and color to show problems rather than paragraphs of text [11]. (Integrate this into the error state design standards in UX guidelines.)

## Voice and Audio Assistance
- **Optional:** Incorporate audio cues and voice guidance for critical tasks and onboarding.
  - **Rationale:** Many low-literacy users are more comfortable listening than reading [12]. Providing spoken instructions (in Portuguese or local dialects) or a brief voice-over during first use can dramatically improve understanding. For example, a voice prompt can welcome the user and explain main menu options. (This would be a new subsection in accessibility or onboarding docs, as an optional assistive feature.)
- **Optional:** Provide multilingual audio prompts or read-aloud features for key content.
  - **Rationale:** Cross-border users may prefer content in their local language. If resources allow, a “listen” button on informational text (e.g. a safety tip or a how-to) that plays an audio clip in the user’s language can bridge literacy gaps [13]. This is not required for v1 but could be noted in the product backlog for future accessibility improvements.
- **Optional:** Use simple confirmation sounds to reinforce user actions.
  - **Rationale:** A subtle audio confirmation (e.g. a “ding” when an order is placed or a success chime when data is saved) can reassure users who might not read the on-screen confirmation. This idea can be included in the Notifications & Feedback section of the UX guidelines as a nice-to-have for better feedback.
- **Note:** The above audio/voice recommendations are not in current core docs; they could be added as an “Audio Accessibility (v2)” addendum to `09_language_and_accessibility.md` or in a future UX spec focused on multimodal support.

## Interaction Patterns
- **Required:** Keep navigation shallow and straightforward – minimize menus and deep hierarchies.
  - **Rationale:** Low-literacy and novice users struggle with complex, layered navigation structures [14]. It’s better to use a simple bottom navigation or single-level menu with clear icons+labels for main sections. (This principle aligns with making the IA simple; it should be reflected in `04_information_architecture.md` and the UX guidelines as a core nav rule.)
- **Required:** Design one clear primary action per screen (avoid overwhelming the user with too many choices at once).
  - **Rationale:** Focus helps users complete tasks without confusion. Research and field tests show simple, intuitive screens that don’t require reading instructions are most effective [15]. For example, the “Add Reservoir” screen should have a single prominent button to save, and not much else. (Add this rule to the UX guidelines “Screen Design” section, as a required simplicity criterion.)
- **Required:** Use familiar interaction patterns and obvious affordances.
  - **Rationale:** Users with limited tech exposure won’t intuitively know uncommon gestures or hidden features. Buttons should look like buttons, swipe actions should have visible prompts, etc. Ensuring intuitive design means the app can be used without prior training [15]. (This can be noted in UX guidelines as a general principle: “No hidden gestures – always hint or show controls.”)
- **Optional:** Provide guidance for any non-standard interactions.
  - **Rationale:** If the app uses a gesture (e.g. pull-to-refresh) or a special feature, include a one-time tooltip or illustration to teach it. This prevents user frustration due to lack of knowledge. (Include as an optional guideline in UX docs, under a “User Education” section.)

## Layout and Visual Hierarchy
- **Required:** Use a clean, uncluttered layout with generous whitespace and large touch targets (≈48dp).
  - **Rationale:** Tappable elements must be easy to hit for all users [16], and a sparse layout prevents overwhelming low-literacy users. A 48dp target size is the minimum for accessibility [16] and is already our baseline; designers should treat it as a hard requirement.
- **Required:** Emphasize key information with clear visual hierarchy (big icons/text for critical data).
  - **Rationale:** Users should instantly recognize important status information (like water level status, battery, network). For example, the “low water” indicator should be bold and prominent so it’s understandable at a glance [17]. Making critical indicators obvious builds trust and usability, as noted in our UI invariants [17]. (This reinforces existing practice; ensure our design mockups always highlight critical info per this rule.)
- **Optional:** Design for primarily vertical scrolling and clearly indicate when content overflows off-screen.
  - **Rationale:** Novice users may not realize they can scroll. While we can’t avoid scrolling on small devices, we should use visible cues (like partial cut-off of the next item or an explicit “scroll” hint on first use) to signal there is more content. (This note can be added as a tip in the UX guidelines under layout considerations.)
- **Optional:** Accommodate right-to-left (RTL) layouts and other localization needs in design.
  - **Rationale:** As Jila expands cross-border, some languages (if added, e.g. Arabic or Hebrew) would require mirroring the UI. It’s optional for now (since current focus is Portuguese), but designing with flexibility for RTL and different string lengths is forward-looking. (Could be mentioned in `09_language_and_accessibility.md` as a future localization consideration.)

## Onboarding & First-Time Use
- **Required:** Minimize onboarding friction – allow users to access core value quickly, with as few steps as possible.
  - **Rationale:** Lengthy or complicated sign-up processes can deter low-literacy users. Our Journey 1 testing highlighted that “too much text or forced setup before value” is a key failure mode [18]. Therefore, registration should be simple (e.g. phone number OTP only), and the user should see initial water status or features within minutes [19]. (This principle should be integrated as an onboarding rule in the UX guidelines or onboarding design spec.)
- **Required:** For “Find water nearby” use-case, allow a no-login preview mode (Marketplace discovery with Community default; map/list discovery without forced auth).
  - **Rationale:** Research and our personas indicate we shouldn’t gate critical discovery features behind account creation [20] [21]. For example, Joana should be able to open the app and immediately see the water points map without signing up. This reduces barriers for first-time users worried about sharing info. This is already reflected in journey 5 and should be explicit in the onboarding design: no login required for read-only browsing [21].
- **Optional:** Provide a brief tutorial with visuals on first launch.
  - **Rationale:** A quick, skippable tutorial (light on text, heavy on images or even a short video) can orient low-literacy users. For instance, highlighting “This is your tank’s days of water left” with an arrow pointing to the UI can help users understand the dashboard. While not strictly required (the UI should be self-explanatory), it’s a helpful addition for user education. (Could be included as an addendum in the onboarding spec or UX guidelines as a recommended practice.)
- **Optional:** Let users choose their preferred language at first launch (if multiple languages are available).
  - **Rationale:** Though Jila is Portuguese-first now, in a cross-border scenario offering an immediate language choice ensures users aren’t lost if they stumble into a foreign language. This is a consideration for scaling to other regions. (Note this in the localization plan or onboarding flow as an optional step when new locales are added.)

## Offline Mode UX
- **Required:** Clearly indicate when the app is offline and when data was last synced.
  - **Rationale:** Users must understand if they are seeing possibly outdated information. A simple offline icon or banner and a timestamp like “Last updated 2 hours ago” prevents confusion and builds trust [22] [23]. Research in our context emphasizes that stale data being not obvious is a critical failure to avoid [23]. (These indicators should be specified in `07_offline_mode_and_sync_spec.md` and reflected in UI designs.)
- **Required:** Ensure that any user action taken offline provides feedback and is saved for sync (never silently drop input).
  - **Rationale:** The app should acknowledge inputs immediately (e.g. “Saved offline ✅”) and later sync. Our product mandate is that user-entered data is never lost [24]. For example, if Maria logs a reading offline, the interface might show a pending state (with an icon or message) until it’s uploaded [25]. This feedback loop is crucial for user confidence. (This requirement is already noted in specs [25]; designers must incorporate “sync pending” states in the UI.)
- **Optional:** Offer a manual “Retry Sync” or refresh button when offline data is waiting.
  - **Rationale:** While the app should auto-sync on reconnect, giving users a sense of control can increase trust. An optional “Refresh” button lets a user retry syncing data if they’re back online, which can reassure those who might otherwise keep checking. (This could be included as an enhancement in the offline spec documentation, though not a launch blocker.)

## Trust Signals and Transparency
- **Required:** Surface data freshness and confidence wherever applicable.
  - **Rationale:** Trust is paramount for our users who may be skeptical of new apps [26]. Always display when a piece of data was last updated and its source/confidence. For example, show “Sensor updated today at 07:00 (High confidence)” on the reservoir status. This practice was explicitly identified as non-negotiable in our design guardrails [27] – it assures users the information is up-to-date or warns them if it’s not. (This should be added as a core principle in the UX guidelines under a new “Trust & Transparency” section.)
- **Required:** Provide clear confirmation and next-step feedback after user actions.
  - **Rationale:** Users need to know when an action is successful. For instance, after placing an order, show a confirmation screen or message (“Order placed!”) with an order reference, so the user isn’t left guessing [28]. Ambiguity here undermines trust. Research and our journey tests highlight that an “unclear next state after order” is a failure mode to avoid [28]. Thus every major action (form submission, etc.) should result in a visible confirmation or result state. (This is a design rule to note in our UX guidelines under form and workflow design.)
- **Required:** Be transparent about uncertainty and avoid false promises.
  - **Rationale:** If a value is an estimate (e.g., “5 days remaining” for water), label it approximate and explain any uncertainty (perhaps via an info icon). This honesty is crucial: our guidelines say “never imply false precision; explain uncertainty” [27]. Likewise, avoid any UI copy that guarantees things we can’t be sure of. Maintaining realistic messaging will foster user trust in the long run. (Include this in the “Trust & Transparency” section of guidelines, referencing that we always display confidence levels.)
- **Required:** Uphold ethical design – no dark patterns, no hidden costs or misdirection.
  - **Rationale:** Low-literacy users are especially vulnerable to misleading designs. We must never trick the user (for example, no confusing CTAs that actually enroll them in something unintended, no “urgent” banners that aren’t real). Our internal principle is “ethical by default: no dark patterns, no fake urgency” [29]. This needs to be explicitly communicated to all designers and PMs. (Perhaps add a brief Ethics reminder in the UX guidelines or reference the existing note in feature requirements [30] as a design constraint.)
- **Optional:** Highlight verified or secure elements with badges or labels.
  - **Rationale:** As the platform grows (e.g., verifying sellers or devices), visual trust marks (like a checkmark “Verified seller” badge) can help users know what/who is trustworthy at a glance. This is not a v1 requirement, but a forward-looking suggestion to enhance trust in marketplace interactions. (Could be noted for future UX work in the marketplace design documentation.)
- **Optional:** Communicate data usage or costs when relevant.
  - **Rationale:** Some users worry about data charges or app costs. Being transparent (e.g., showing “using X MB” when downloading an update or explaining that SMS alerts may cost carrier fees if any) can build trust that we respect their resources. This is more of a customer service consideration and can be documented in an FAQ, but mentioning it in the design guide ensures the UI doesn’t hide such info.

## Consistency with Existing Documentation
This inclusive design guide is intended to complement `09_localization_and_accessibility.md` (for language and accessibility basics) and the broader `jila_application_ux_guidelines.md`. Wherever possible, we’ve indicated where each guideline might live: many “visual and interaction” points fit into the UX guidelines, while language and basic accessibility points extend the 09 document. The tone and format here mirror our core specs – concise bullet points under clear headers, with required standards versus nice-to-haves clearly marked (P0 vs P1 where applicable).

By integrating these research-validated recommendations, the product/design team can ensure Jila’s user experience is inclusive and effective for its target audience. Designers and PMs should treat all **Required** items as non-negotiable for the MVP, and plan for **Optional** items as enhancements when time permits. These additions will be low-drift references that evolve as we gather real user feedback, just like our other core UX documents.

## Citations
- [1] [20] [26] `01_user_personas_and_jtbd.md`
- [2] [3] [5] [7] [10] [11] [13] [15] *Inclusive Design for Users with Language and Literacy Needs - DESIGN TECH GUIDE* ([Link](https://www.designtechguide.com/analysis/inclusive-design-for-users-with-language-and-literacy-needs))
- [4] [6] [8] [9] [16] [17] `09_localization_and_accessibility.md`
- [12] *Designing for the Other Half: UX for Low-Literacy and Rural Users* ([Link](https://medium.com/design-bootcamp/designing-for-the-other-half-ux-for-low-literacy-and-rural-users-9af7804753cd))
- [14] *UIs for Low-Literate Users - Microsoft Research* ([Link](https://www.microsoft.com/en-us/research/project/uis-low-literate-users/))
- [18] [19] [21] [22] [23] [24] [25] [27] [28] [29] [31] `02_user_journey_maps.md`
- [30] `03_feature_requirements_document.md`

