# Split Fair — Visibility & Paid Acquisition Playbook

_Last updated: 2026-06-06. Owner: Nico. App: iOS live (id6761033612). Android: waitlist._

This doc covers (1) the "Split Fare" homophone problem, (2) on-page SEO + ASO, (3) the paid
campaigns to launch (Apple Search Ads, Google App, Google Search), and (4) the organic funnel
across the accounts you already have (TikTok, IG, Nextdoor, Reddit).

---

## 0. The honest truth about "Split Fare"

There are **two different searchers** typing "split fare," and they want opposite things:

1. **Your people (homophone).** They heard "Split Fair" by word of mouth or saw a video, and
   type "split fare" because the words sound identical. High intent — they want *your* app.
2. **Ride/transit splitters.** "Split fare" is also a real concept: splitting an Uber/taxi/
   flight/train fare with friends. These people do **not** want a rent app.

So the play is **not** "rank for generic split fare." That pulls in rideshare intent and burns
ad budget. The play is:

- **Capture homophone + intent combos:** `split fare app`, `split fare rent`, `split fare
  roommate`, `splitfare rent calculator`. These are unambiguously your people.
- **Add negative keywords** so you never pay for `uber / taxi / lyft / flight / train / transit /
  ride / metro / airfare` fare-splitting searches.
- **Tell search engines the two spellings are the same app** via on-page text + structured data
  `alternateName` (done — see §1).

This is already wired into the site. The rest of this doc operationalizes it.

---

## 1. On-page SEO — DONE (shipped in this change)

Implemented on `docs/index.html` and `docs/get/index.html`:

- **Title + meta** now include "Split Fare" as the recognized alt spelling.
- **`<meta keywords>`** added (low value to Google, but harmless and helps some engines/ASO crawlers).
- **JSON-LD `alternateName`: ["Split Fare", "SplitFair", ...]** — tells Google these are the same entity.
- **JSON-LD `FAQPage`** with a "Is Split Fair the same as Split Fare?" Q&A — eligible for rich
  results and AI Overviews, and gives a real on-page text match for the homophone.
- **Visible FAQ block** answering the Split Fare question (real body text, not just metadata).
- **Competitive comparison table** ("Why Split Fair, not the others") framed on capability + free.
- **`og-card.png` (1200×630)** social card so links you drop on Reddit/Nextdoor/iMessage render
  a branded preview instead of a bare URL. Card text bakes in "also searched as Split Fare."
- **`robots.txt` + `sitemap.xml`** so Google crawls and indexes both pages.

### Next SEO actions (need your accounts — ~30 min)
1. **Google Search Console** — add `split-fair.github.io`, submit `sitemap.xml`, request indexing
   of `/` and `/get/`. This is how you confirm Google sees the "Split Fare" content.
2. **Bing Webmaster Tools** — same (Bing powers DuckDuckGo + some ChatGPT search).
3. **Strongly consider buying/pointing `split-fair.app`** (you already use hello@split-fair.app).
   A custom domain on the GitHub Pages site lifts trust, ad Quality Score, and brand-match. If you
   own it, point it at Pages and update canonicals. (Flag me to do the DNS + CNAME + canonical swap.)

---

## 2. ASO (App Store Optimization) — the #1 lever for an iOS-only app

Most of your installs will come from **App Store search**, not Google. Tune the listing:

- **Keyword field (100 chars, no spaces after commas):**
  `splitfare,rent split,roommate,fair rent,rent calculator,split rent,room rent,bill split,roomies`
  — note `splitfare` (one word) is included; Apple does fuzzy matching on the homophone, and the
  one-word form fits where "split fare" with a space wastes a char Apple already indexes from title.
- **Title (30 chars):** `Split Fair: Rent Splitter` (brand + top keyword).
- **Subtitle (30 chars):** `Fair rent by room · Split Fare` — putting the homophone in the
  subtitle is the single highest-impact ASO move for the misspelling.
- **Ratings velocity:** the in-app review prompt (v1.1.9) is live — keep it. Reviews are the
  biggest ranking factor after keywords.

---

## 3. Paid campaigns — launch order by ROI

### 3a. Apple Search Ads (ASA) — DO THIS FIRST (highest ROI, iOS-only app)
Ads appear at the top of App Store search. Highest intent install channel that exists for iOS.

- **Start with a Basic campaign? No — use Advanced** (keyword-level control).
- **Ad groups + keywords (exact + broad):**
  - *Brand:* `split fair`, `split fare`, `splitfair`, `split fair app`
  - *Category:* `rent splitter`, `split rent`, `roommate rent`, `fair rent`, `rent calculator`,
    `room rent calculator`
  - *Competitor:* `splitwise`, `tricount`, `spliddit` (cheap installs from comparison shoppers)
- **Negatives:** `uber, taxi, lyft, flight, airfare, train, transit, metro, ride share`
- **Budget:** start **$15–25/day**, CPA cap ~$1.50–3.00. Brand keywords convert >50% and cost cents.
- **Why first:** branded ASA defends against competitors bidding on "Split Fair," and captures the
  homophone right where the intent-to-install is highest.

### 3b. Google App Campaign (Universal App Campaign) — install volume
Drives App Store installs across Google Search, YouTube, Play, Display. Mostly automated — you feed
assets, Google's AI optimizes to a target CPA.

- **Objective:** App installs → iOS → App Store.
- **Assets to supply (have these ready — many already exist in D:\ProjectAssets\SplitFair):**
  - 5 headlines (30 char), 5 descriptions (90 char) — copy bank below
  - Portrait + landscape screenshots (you have them)
  - 1–2 vertical videos (your TikTok cuts work — repurpose)
  - Logo + the og-card
- **Budget:** $10–20/day, target CPA $2–4. Let it learn for ~7 days before judging.

### 3c. Google Search campaign → landing page (web intent + future Android)
Captures people Googling the problem who aren't in the App Store yet. Sends them to
`split-fair.github.io/get` → App Store. Also the channel that will matter most when Android ships.

- **Ad groups:**
  - *Brand/homophone:* `split fair`, `split fare app`, `split fare rent`, `splitfair`
  - *Problem/how-to:* `how to split rent by room size`, `split rent unevenly`, `fair way to split
    rent with roommates`, `rent split calculator`, `who pays more rent bigger room`
  - *Competitor:* `splitwise alternative`, `splitwise for rent`
- **Match types:** phrase + exact (avoid broad early). 
- **Negative keyword list (apply at campaign level):**
  `uber, taxi, lyft, ride, rideshare, flight, airfare, airline, train, amtrak, transit, metro,
  bus, subway, toll, free [if you don't want freebie-only], job, salary` 
- **Ad copy:** Responsive Search Ads, copy bank below.
- **Budget:** $10–15/day. Expect higher CPA than ASA (extra hop to store) — but it's the only
  channel that catches pre-store web searchers and seeds Android demand.

### 3d. Paid Social — your demand engine (leverages accounts you ALREADY have)
ASA only catches people already searching. Paid social *creates* the searchers. And you don't build
ads from scratch — you promote your existing organic posts, which is cheaper and higher-trust.

- **TikTok Spark Ads (start here for social).** Boost an existing @splitfair_app post *as itself* —
  keeps the handle, likes, comments, sounds native. Objective: **App Promotion** (iOS installs) or
  **Traffic** → split-fair.github.io/get. Pick your best-performing organic video and put $5–10/day
  behind it. TikTok is where this app's audience (18–28, moving season) already is.
- **Meta Ads — Instagram + Facebook (one Ads Manager).** **Advantage+ App Campaign** optimized for
  installs, creative = your existing Reels. Bonus: retarget IG profile/website visitors and build
  lookalikes from engagers. $5–10/day.
- **Reddit Ads.** You have an account and the subs are perfect (r/roommates, city apartment subs).
  Cheap CPMs, niche intent. $3–5/day, "Get app installs" or "Drive traffic" to /get.

**Why this pairs with ASA:** social = top-of-funnel awareness (people see "Split Fair" spelled
correctly in a video → fewer "split fare" mistypes); ASA + SEO = bottom-of-funnel capture. Run both.

**Revised lean recommendation (given you have organic accounts + creative):** instead of ASA-only,
a stronger ~$15–20/day lean start is **TikTok Spark Ads $8 + ASA brand-defense $7**. The Spark ad
generates demand using a video you already have; ASA defends the name and catches the intent. Add
Meta + Reddit as budget grows.

#### >>> CHOSEN LAUNCH: TikTok Spark Ads only, ~$10/day <<<
One channel, one validated video, optimized for installs. Prove it converts, then layer ASA + Meta.

**Step by step:**
1. **Business account:** convert @splitfair_app to a TikTok Business Account (Settings → Account →
   Switch to Business), then create a **TikTok Ads Manager** account at ads.tiktok.com + add billing.
2. **Pick the video:** use your best-performing organic post (highest watch-through / saves). If
   none stand out yet, post the "It's Split FAIR, not Split Fare 😅" hook video and boost that.
3. **Authorize it as a Spark Ad:** on the organic post → ⋯ → **Ad settings / Ad authorization** →
   toggle ON → generate the video code (or authorize via Ads Manager → Assets → Spark Ads).
4. **Campaign:**
   - Objective: **Traffic** (simplest — send to the App Store link, optimize for clicks) **or**
     **App Promotion** (optimizes for installs via SKAN 4.0; needs the app added + a bit more setup).
     Start with Traffic for a clean $10/day test; switch to App Promotion once you want install-cost data.
   - Destination URL: `https://apps.apple.com/app/id6761033612` (direct) or
     `https://split-fair.github.io/get` (lets you also track the click via GA4 later).
   - Budget: **$10/day**, no end date.
5. **Targeting:** US, ages 18–34, broad interests (Lifestyle, Personal Finance, Real Estate/Renting).
   Let TikTok's algorithm optimize — don't over-narrow at $10/day.
6. **Ad:** select the Spark post, set the CTA button to **"Download"**, point to the destination URL.
7. **Run 7 days untouched.** Then read: CPC, landing-page/store taps, and (if App Promotion) cost
   per install. Kill or scale. If it works, add ASA brand-defense ($5–7/day) underneath.

**Blocked on you:** TikTok Business + Ads Manager account & billing; choosing/authorizing the video.
Everything else (copy, targeting, destination) is specified above.

### Conversion tracking (do before spending)
- ASA: built-in (App Store install attribution).
- Google App campaign: link **App Store Connect** + use Google's iOS install measurement (SKAdNetwork).
- Google Search → landing page: add a **GA4** tag to `docs/index.html` + `docs/get/`, fire an event
  on App Store button click ("download_click"), import as a Google Ads conversion. (Flag me — I can
  add the GA4 + click event in 10 min once you give the Measurement ID.)

### Suggested total starting budget
**CHOSEN START: Lean ~$15/day, Apple Search Ads only.** Run §3a (ASA Advanced) on brand + homophone
+ category keywords with the rideshare negatives. This is the highest-ROI dollar for an iOS-only app
and is worth running permanently just to defend the "Split Fair / Split Fare" name. Once you have ~2
weeks of ASA CPA data and it's converting, layer in the Google App campaign (§3b), then Google
Search (§3c). Don't launch all three at once at this budget — ASA first, prove it, then expand.

_(Original recommendation for reference: ~$35–60/day split ASA $20 / Google App $15 / Google Search
$10 for faster multi-channel learning. Scale to this once ASA proves out.)_

---

## 4. Copy bank (paste-ready)

**Google Search RSA — Headlines (≤30 char):**
- Split Fair – Fair Rent App
- Looking for "Split Fare"?
- Split Rent by Room Value
- Stop Splitting Rent 50/50
- Free Roommate Rent Splitter
- The Math Roommates Agree To
- Private Bath? Pay Fair Share
- No Subscription. No Account.
- Fair Rent in 60 Seconds
- Bigger Room = Bigger Share

**Google Search RSA — Descriptions (≤90 char):**
- Score each room by size, bath, light & more. Split rent by what it's actually worth. Free.
- Searched "Split Fare"? Same app. Split Fair settles the rent fight with math, not feelings.
- Free on the App Store. No subscription, no account. Share the breakdown with your roommates.
- Equal splits aren't fair when rooms aren't equal. Get the number everyone agrees on.

**App campaign headlines (≤30):** Fair Rent for Every Room · Split Rent, Not Friendships ·
Free Rent Split Calculator · Searched "Split Fare"? It's Us · No One Argues With Math

**App campaign descriptions (≤90):** Split rent by room value — size, bath, light, parking. Free,
no account. · The fair-rent app your group chat needs. Free on the App Store.

---

## 5. Organic funnel — your existing accounts (TikTok, IG, Nextdoor, Reddit)

Every channel points to **one link: `split-fair.github.io/get`** (now has a branded share card).

- **TikTok / IG (@splitfair_app):** keep the POV/satisfying-reveal format from MARKETING.md. Add a
  pinned video literally titled *"It's Split FAIR, not Split Fare 😅"* — turns the misspelling into
  a hook and trains the algorithm + viewers on the name. Bio link → /get.
- **Reddit:** highest-intent free channel for this app. Be a helpful participant, not a spammer.
  Target subs: r/roommates, r/NYCapartments (+ other city subs), r/personalfinance (careful, strict),
  r/AmItheAsshole-style threads about unfair rent (comment with the method, link only when asked).
  Post format: "Built a free calculator that splits rent by room value — no signup, here's the math."
  Reddit posts also rank in Google — a good r/roommates thread can capture "split fare" searchers.
- **Nextdoor:** local angle. "Free tool for splitting rent fairly with housemates" in housing/recommendations.
  Lower volume, but zero competition and high trust.
- **Cross-link for SEO:** put `split-fair.github.io` in every bio. Inbound links + branded anchor
  text ("Split Fair") teach Google the canonical spelling and lift the homophone capture.

---

## 6. 30-day sequence

| Days | Action |
|---|---|
| 1–2 | Verify site in Google + Bing Search Console, submit sitemap. Set up ASA Advanced, brand + category ad groups. Add GA4 + download_click event. |
| 3–5 | Launch ASA ($20/day). Build Google App campaign assets, launch ($15/day). |
| 6–10 | Launch Google Search ($10/day) with negatives. Post the "Split Fair not Split Fare" pinned video on TikTok/IG. Seed 2–3 helpful Reddit comments. |
| 11–20 | Let campaigns learn. Don't touch daily. Watch CPA by channel. |
| 21–30 | Cut/scale by CPA. Double down on the winner. Decide on `split-fair.app` custom domain. Plan Android Search-campaign expansion. |

---

## 7. Things only you can do (blockers for me)
- [ ] Google Ads + Apple Search Ads account access / billing
- [ ] Google Search Console + Bing Webmaster verification
- [ ] GA4 Measurement ID (so I can wire conversion tracking into the site)
- [ ] Decision: buy/point `split-fair.app` custom domain?
- [ ] Decision: confirm daily budget (proposed ~$35–60/day, ASA-weighted)
