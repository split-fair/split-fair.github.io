# Split Fair — Stitch Design Brief (FINAL)

---

## #1 PRIORITY — READ THIS FIRST

**Every screen that lists a character illustration MUST show that illustration rendered visibly inside the screen frame. Do not treat illustrations as external file specs — draw them directly into the UI mockup.**

**Art style for ALL illustrations: Big Hero 6 animated film. Flat vector. Warm rounded characters. Expressive faces. Diverse skin tones. NOT photorealistic. NOT generic Material Design clip art.**

---

## Brand Tokens

| Token | Hex | Use |
|-------|-----|-----|
| Primary green | `#1D9E75` | Buttons, active states, primary accents |
| Primary dark | `#0F6E56` | Gradient deep end, pressed states |
| Primary light | `#E1F5EE` | Selected chip backgrounds |
| Amber | `#EF9F27` | Natural light, warm accents |
| Blue | `#378ADD` | Sqft fields, slide 2 |
| Purple | `#7F77DD` | Room count, slide 3 |
| Surface | `#FFFFFF` | Cards, sheets |
| Background | `#F8F9FA` | Page bg |
| Border | `#E8EAED` | Card outlines |
| Text dark | `#1A1D23` | Headlines |
| Text body | `#6B7280` | Body copy |
| Text hint | `#9CA3AF` | Captions, hints |
| Error red | `#EF4444` | Delete, destructive |
| Font | Inter | Everything |

**App name:** Split Fair · **Tagline:** Fair rent for every room
**Tone:** Clean, modern, slightly witty. "Smart friend who's good at math."

---

## Characters (Lock these — same look across every screen)

These four characters recur throughout the app. Their design must be identical every time they appear.

- **Alex** — hoodie, headphones around neck, laid-back, usually thinks the split is fine (it's not)
- **Jordan** — phone/clipboard in hand, organized, slightly Type-A, the person who installed the app
- **Casey** — big personality, takes up space, always near the couch or kitchen
- **Sam** — quieter, smaller room, subtly victorious when the fair split comes out lower than expected

**Character style:** Big Hero 6-inspired flat vector. Warm diverse skin tones. Rounded shapes. Expressive faces. NOT photorealistic. NOT generic Material illustrations.

---

## App Structure (EXACTLY THIS — no additions)

```
Onboarding: 5 slides (first launch only)
Main app shell with bottom nav (3 tabs: Home · Saved · Settings)
Results screen (pushed on top when Calculate is tapped)
Room Edit bottom sheet (opens from room card on Home)
Scoring Explainer bottom sheet (info sheet)
```

**Total: 5 slides + 4 screens + 2 sheets. Nothing else.**

---

## BOTTOM NAVIGATION BAR (present on all main screens)

3 tabs, always visible at bottom:
- Tab 0: `home_rounded` icon · **Home**
- Tab 1: `bookmark_rounded` icon · **Saved**
- Tab 2: `settings_rounded` icon · **Settings**

Active tab: icon + label in `#1D9E75`. Inactive: `#9CA3AF`. White bar, 0.5px top border `#E8EAED`.
Consider a very subtle `#E1F5EE` pill (32×32px rounded) behind the active icon — iOS 17 treatment, minimal.

---

## ONBOARDING SLIDE 1 — Welcome

**[ILLUSTRATION — renders directly inside screen, fills top 55% of screen height]**
All 4 characters in a living room mid-debate. Jordan holds a phone with a balance scale icon. Casey has arm draped over the back of a couch like they own it. Alex looks unbothered. Sam stands apart looking quietly vindicated. Warm apartment: couch, plant, window light. Big Hero 6 warmth — rounded, expressive, flat vector.
*(File: `onboarding_welcome.png` 320×260px — but draw it IN the screen mockup)*

**Text below illustration:**
- Headline 26px bold `#1A1D23`: `Welcome to Split Fair`
- Body 14.5px `#6B7280` line-height 1.65:
  *Finally, an app that settles the age-old question: "Why is Chad paying the same rent as me when his room has a window AND a closet?" Spoiler: he shouldn't be.*

**Bottom chrome:**
- 5 page dots · dot 1 = elongated 24px pill `#1D9E75`, others 8px circles `#E8EAED`
- Full-width green **Next** button (56px, rounded 16px, green glow shadow)
- Top-right **Skip** text link (`#9CA3AF`, 14px)

---

## ONBOARDING SLIDE 2 — Size Matters

**[ILLUSTRATION — 88×88px circle, top center, rendered inside screen]**
Jordan standing next to a large hand-drawn apartment floor plan, holding a tape measure. Casual curious expression. Circle crop. Background: `#E3F0FC` (light blue).
*(File: `onboarding_sqft.png`)*

**Text:**
- Headline 26px bold: `Size Matters`
- Subhead 15px `#6B7280`: `Tell us about the place you're splitting.`
- Body 13.5px `#9CA3AF`: *We'll use this to figure out how much is "shared" vs how much each person actually controls. That gap is where fair rent lives.*

**Input fields (stacked):**

**Field 1 — Monthly Rent (most prominent):**
Blinking `↓ Start here` label in `#1D9E75` (12px semibold) above field. Container gently pulses in scale on repeat.
- Container: `#E1F5EE` bg, rounded 14px, `#1D9E75` border 2px
- `$` prefix: 26px bold `#1D9E75`
- Center-aligned input: 32px bold `#1D9E75`, hint `2,500`
- `/mo` suffix: 15px `#6B7280`
- Label below: *Total monthly rent* (12px `#9CA3AF`)

**Field 2 — Total Apartment Sqft:**
- Standard outlined field, rounded 12px
- Label: *Total apartment size* · Suffix: *sqft* · Hint: *1,200*
- Text: 22px bold `#1A1D23` · Focused border: `#378ADD` 2px

**Field 3 — Property Address (optional):**
- Standard outlined field
- Label: *Property address (optional)* · Hint: *123 Main St, Apt 4B*
- Prefix: `location_on_outlined` icon

**Bottom chrome:** 5 dots (dot 2 active) · **Next** button

---

## ONBOARDING SLIDE 3 — How Many Rooms?

**[ILLUSTRATION — 88×88px circle, top center, rendered inside screen]**
Top-down view: simple apartment floor plan with 3–4 bedroom doors each a different color (green, blue, amber). Graphic and stylized, not architectural. Circle crop. Background: `#F0EEFF` (soft lavender).
*(File: `onboarding_rooms.png`)*

**Text:**
- Headline 26px bold: `How Many Rooms?`
- Subhead 15px `#6B7280`: `How many bedrooms are you splitting?`
- Body 13.5px `#9CA3AF`: *Bedrooms only — we're splitting rent, not staging Cribs. Don't count bathrooms, closets, or the "flex space" your landlord called a bedroom but is clearly a repurposed pantry.*

**Stepper (centered, large):**
`−` circle button · **4** (56px bold `#1D9E75`) · `+` circle button
Sub-label: *bedrooms* (13px `#9CA3AF`). Number bounces with elastic scale on change.

**Bottom chrome:** 5 dots (dot 3 active) · **Next** button

---

## ONBOARDING SLIDE 4 — Each Room's Size

**[ILLUSTRATION — 88×88px circle, top center, rendered inside screen]**
Sam in a small cozy bedroom carefully measuring the wall with a tape measure. Slightly pleased expression — like Sam is finally getting proof. Circle crop. Background: `#FEF4E8` (warm amber light).
*(File: `onboarding_roomsize.png`)*

**Text:**
- Headline 26px bold: `Each Room's Size`
- Subhead 15px `#6B7280`: `Square footage of each bedroom (skip if unknown)`
- Body 13.5px `#9CA3AF`: *Got a tape measure? Now's the time. Skip any you're not sure about — you can fill them in later. Guessing is also fine. Chad's been guessing his whole life.*

**Input list:**
- First item — full-width pill/button (NOT a text field): `help_outline_rounded` icon + centered text *I don't know it* (15px semibold `#6B7280`). White bg, `#E8EAED` 1.5px border, 48px tall, rounded 14px. Tapping skips to next slide.
- Then N stacked text fields: *Room 1* / *Room 2* / *Room 3* · suffix `sqft`
- Each field has a 4px left accent border in its room color (Room 1: green `#1D9E75`, Room 2: blue `#378ADD`, Room 3: amber `#EF9F27`)

**Bottom chrome:** 5 dots (dot 4 active) · **Next** button

---

## ONBOARDING SLIDE 5 — Shared Spaces

**[ILLUSTRATION — 88×88px circle, top center, rendered inside screen]**
Casey and Alex on the same couch. Casey arms spread wide across the back, taking up most of it. Alex politely squeezed into one corner, smiling awkwardly. Both look friendly. Big Hero 6 expressiveness. Circle crop. Background: `#E1F5EE` (light green).
*(File: `onboarding_communal.png`)*

**Text:**
- Headline 26px bold: `Shared Spaces`
- Subhead 15px `#6B7280`: `Does everyone have equal access to the living room, kitchen, and common areas?`
- Body 13.5px `#9CA3AF`: *If someone has claimed the kitchen or living room as their personal territory, that's worth factoring in. Equal access = everyone pays the same share of communal sqft.*

**Two choice buttons (full width, stacked):**
- **Button A (selected by default):** `#E1F5EE` bg, `#1D9E75` border 2px, left icon `check_circle_rounded` green, label **Yes — split equally**, right checkmark icon. Text: 15px semibold `#0F6E56`.
- **Button B:** white bg, `#E8EAED` border 1px, left icon `tune_rounded` gray, label **No — I'll customize per room**. Text: 15px regular `#1A1D23`.

**Bottom chrome:** 5 dots (dot 5 active) · **Let's settle this** green button

---

## HOME TAB (Tab 0)

**Background:** `#F8F9FA`

**Collapsible hero app bar (expandedHeight: 180px):**

**[HEADER ILLUSTRATION — 390×180px, fills expanded app bar, fades to white at bottom via gradient]**
Top-down stylized apartment floor plan. Each bedroom door painted a different color (green, blue, amber, orange). Character silhouettes visible through doorways — one peeking out, one reading. Semi-abstract, more graphic pattern than blueprint. Warm pastel palette — must NOT compete with UI below. Bottom 60px has white gradient overlay.
*(File: `home_bg.png`)*

When scrolled, collapses to 56px white bar (title + action icons).
- Title: **Split Fair** (22px bold)
- Subtitle: **Fair rent for every room** (12px `#6B7280`)
- Right icons (in collapsed state): `bookmark_rounded` (opens Saved sheet), `refresh_rounded` (opens Reset dialog)

**Scrollable content:**
1. Section label *Total monthly rent* → white card, rounded 16px. Currency input: `$2,500.00`, large. Subtle warm cream gradient `#FFFBF0` → white behind amount.
2. Address field: *Property address (optional)*, `location_on_outlined` prefix, hint *e.g. 123 Main St, Apt 4B*, autocomplete.
3. Section label *N rooms* (info icon `(i)` right → opens scoring explainer sheet) → reorderable room tiles:
   - Each tile: white card, rounded 16px, `#E8EAED` border
   - Left: 44×44px avatar circle (room color at 12% opacity bg, tenant initial in color)
   - Tenant name (semibold) + *Room N · XXX sqft · [bathtub icon if private bath]*
   - 4px colored left border accent per room's color
   - Swipe left → red gradient delete reveal with `delete_rounded` + "Remove"
   - Long-press → reorder handle
   - Hint below: *Swipe to remove  ·  Hold & drag to reorder* (11px `#9CA3AF`)
4. `+ Add another room` — outlined full-width button, 52px, rounded 14px, `add_rounded` icon
5. **Calculate fair split** — primary green full-width button, 56px, rounded 16px, `calculate_rounded` icon. When active: shimmer animation sweeps left-to-right at 30° angle on repeat + subtle green glow shadow. Disabled (gray) when rent = 0.

---

## ROOM EDIT SHEET (bottom sheet, opens when room tile is tapped)

White, rounded top corners 24px. ~90% screen height, internally scrollable. Sticky Save button at bottom.

**Header:**
- Drag handle: 40×4px pill `#E8EAED`, centered top
- Room color dot (12px) + room name (20px bold) + tenant name (14px `#6B7280`)
- **Score badge (top right):** `XXX pts` — `#E1F5EE` bg, `#1D9E75` text, semibold pill. Updates live.

**Section: Room details** (11px uppercase `#9CA3AF` label)
- Name field · Tenant field · Sqft field (22px bold inside, suffix `sqft`)

**Section: Features** *(collapsible, default open)*
Chevron toggle on section header. When a feature is checked: row tints `#E1F5EE`, checkmark animates in with spring scale.

Feature rows with icons:
- `bathtub_rounded` · Private bathroom
- `local_parking_rounded` · Parking spot
- `deck_rounded` · Balcony / patio
- `checkroom_rounded` · Walk-in closet
- `ac_unit_rounded` · A/C unit

**Each active (checked) row shows a faint wide-format background illustration behind it (15% opacity):**
| Filename | Feature | Scene |
|----------|---------|-------|
| `feature_bath.png` | Private bathroom | Soft tiled bathroom, warm tones, muted |
| `feature_parking.png` | Parking spot | Parking line with small car |
| `feature_balcony.png` | Balcony / patio | Railing, plant, city view |
| `feature_closet.png` | Walk-in closet | Neat organized closet |
| `feature_ac.png` | A/C unit | A/C unit, cool air effect |
All 390×60px, 15% opacity as bg texture. Big Hero 6 warmth, very desaturated.

**Section: Quality scores** *(collapsible, default open)*
Sliders 1–10, each row shows: icon · label · current value badge · slider
- `wb_sunny_rounded` · Natural light — amber slider `#EF9F27`
- `do_not_disturb_on_rounded` · Quietness — green slider
- `inventory_2_rounded` · Storage space — green slider
- `layers_rounded` · Floor level — number input (not slider)

**Section: Communal space** *(collapsible, default COLLAPSED)*
When expanded:
- Total apartment sqft input (if not set): `square_foot_rounded` prefix
- Info chip: *Communal area: XXX sqft · Equal share: XXX sqft/room* (`#E1F5EE` bg)
- Checkbox: *Communal space treated equally*
  - When unchecked: reveals per-room communal slider + *Reset to equal* TextButton
  - Note: *Other rooms adjust automatically* (12px `#9CA3AF`)
- Faint background illustration behind expanded communal section (10% opacity):
  Shared living room / kitchen scene, Big Hero 6 warmth, very muted.
  *(File: `feature_communal.png` 390×120px)*

**Save button:** Full-width, green, 56px, sticky at bottom — **Save changes**

---

## RESULTS SCREEN (pushed, back arrow, bottom nav hidden)

**Background:** `#F8F9FA`
**App bar:** *Fair split* title · back arrow · share icon · PDF icon (right)

**Scroll content:**

**Card 1 — Total Header (full width gradient):**
Background: `#1D9E75` → `#0F6E56`
- *Total monthly rent* (white 80% opacity, 14px)
- `$2,500.00` (white, 38px bold — **rolling digit animation**, counts up from 0)
- *Split across N rooms* (white 80% opacity, 14px)

**[ILLUSTRATION — 390×120px, transparent bg, between Card 1 and Card 2 — rendered directly in screen]**
Jordan holds up a phone showing calculated numbers, gives thumbs up. Alex and Sam in background looking relieved. Sam has a subtle smug smile. Big Hero 6 style.
*(File: `results_celebration.png`)*

**Card 2 — Fairness Visualization:**
- 2 rooms: animated balance scale tilted toward higher payer. Pan labels: tenant name + `$XXX/mo`. Badge: *Balanced by room score*.
- 3+ rooms: donut chart, colored segments, legend with dot + name + amount + %

**Card 3 — Each person pays:**
N cards, staggered slide-in from right (60ms delay between each). Each: 4px colored left accent in room color · tenant name bold · `$XXX.XX/mo` right (bold green) · percentage badge

**Card 4 — Visual breakdown:**
Horizontal bar chart, one row per person, fills in room color, % label right.

**Card 5 — Why these numbers?**
Each row: colored dot + tenant name + *XXX pts total* + chips (*XXX sqft · +XX features · +XX quality*) + chevron. Tapping opens score breakdown sheet.

**Card 6 — Share with roommates:**
[Share] [Copy] outlined buttons side by side + full-width **Export PDF** green button (or amber + lock if locked).

**Confetti burst on arrival:** 55 particles, colors: green, amber, blue, pink, red, white.

---

## SAVED TAB (Tab 1)

**App bar:** *Saved Splits* · right label *Auto-saved on calculate* (11px `#9CA3AF`)
**Background:** `#F8F9FA`

**Empty state:**
**[ILLUSTRATION — 120×120px centered, rendered inside screen]**
Jordan standing at an empty bookshelf, shrugging, phone in hand, small smile. Big Hero 6 style.
*(File: `empty_saved.png`)*
- Caption 16px semibold: *No saved splits yet*
- Sub 13px `#9CA3AF`: *Hit "Calculate fair split" on the Home tab to auto-save your first result.*

**Result cards (one per saved calc):**
White card, rounded 16px, `#E8EAED` border.
- Header: 38×38px home icon circle (`#E1F5EE` bg, `home_rounded` `#1D9E75`) · address (14px bold) · `$XXX/mo · N rooms · MM/DD/YYYY` (12px `#6B7280`) · load icon · delete icon
- Body (below divider): wrap of colored chips per room → `[Tenant]  $XXX  (XX%)` — room color at 10% opacity bg, room color 25% border, room color semibold text 12px

---

## SETTINGS TAB (Tab 2)

**App bar:** *Settings* (18px bold)
**Background:** `#F8F9FA`

**Two grouped sections (iOS-style white rounded cards, 16px radius, `#E8EAED` border):**

Section *About* (11px uppercase `#9CA3AF` label):
- *Split Fair* tile — balance icon circle, opens version dialog
- *How scoring works* tile — opens scoring explainer sheet
Each tile: 36×36px icon circle · title · subtitle · chevron right

Section *Data*:
- *Reset everything* tile — red text + icon (icon circle: red 10% opacity bg, red icon), opens confirmation dialog. Destructive.

---

## IMAGE ASSET SUMMARY

All images go in `assets/images/`. DO NOT change filenames.

| Filename | Screen | Scene | Dimensions |
|----------|--------|-------|------------|
| `home_bg.png` | Home app bar | Top-down apartment floor plan, pastel, fades to white at bottom | 390×180px |
| `onboarding_welcome.png` | Slide 1 | All 4 characters (Alex/Jordan/Casey/Sam) in living room discussing rent | 320×260px |
| `onboarding_sqft.png` | Slide 2 icon | Jordan with tape measure + floor plan sketch | 88×88px circle |
| `onboarding_rooms.png` | Slide 3 icon | Apartment floor plan with colored bedroom doors | 88×88px circle |
| `onboarding_roomsize.png` | Slide 4 icon | Sam measuring bedroom, satisfied expression | 88×88px circle |
| `onboarding_communal.png` | Slide 5 icon | Casey sprawled on couch, Alex politely squeezed to one side | 88×88px circle |
| `results_celebration.png` | Results screen | Jordan thumbs up with phone, Alex + Sam relieved, Sam subtly smug | 390×120px transparent |
| `empty_saved.png` | Saved tab empty | Jordan at empty bookshelf, shrugging with small smile | 120×120px |
| `feature_bath.png` | Room editor | Soft bathroom illustration, muted/desaturated | 390×60px, 15% opacity bg |
| `feature_parking.png` | Room editor | Parking line with small car | 390×60px, 15% opacity bg |
| `feature_balcony.png` | Room editor | Balcony railing, plant, city view | 390×60px, 15% opacity bg |
| `feature_closet.png` | Room editor | Neat organized closet | 390×60px, 15% opacity bg |
| `feature_ac.png` | Room editor | A/C unit, cool air effect | 390×60px, 15% opacity bg |
| `feature_communal.png` | Room editor communal | Shared living room / kitchen scene | 390×120px, very muted |

---

## DO NOT

- Add a 4th tab to the bottom nav
- Show communal space on the Home screen — it lives ONLY in the Room Edit Sheet
- Add dark mode
- Add any screen not listed above (no dashboards, insights, map views, profiles)
- Make characters photorealistic
- Skip character illustrations inside onboarding screens — they MUST be visible IN the mockup
- Add social login, profile screens, or account settings
- Add charts beyond the scale/donut on results screen
- Change any copy — all text is exact and final
