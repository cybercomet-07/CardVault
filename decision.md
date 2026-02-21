# DECISIONS.md — CardVault

## Context

CardVault is a Flutter-based visiting card manager built for mobile + web.  
Primary goals were:
- fast product delivery,
- clean UX for card capture/upload + management,
- secure user-level isolation,
- low-cost operation on free tiers where possible.

---

## 1) Why Flutter

Flutter was selected for:
- single codebase across Android/iOS/Web,
- fast UI iteration (important for interview timeline),
- strong plugin ecosystem (`firebase_auth`, `cloud_firestore`, `image_picker`, ML Kit),
- maintainable component-based UI (`PageScaffold`, reusable buttons/cards).

**Tradeoff**
- platform-specific behavior needs conditional handling (e.g., camera behavior on web vs mobile, web OCR interop).

---

## 2) Why Firebase for app backend concerns (Auth + Firestore)

Used Firebase for:
- Authentication (email/password),
- Firestore as managed document DB,
- quick setup without maintaining custom auth/database infrastructure.

**Tradeoff**
- advanced server-side processing and custom OCR pipelines are harder without deploying extra backend services.

---

## 3) Why Cloudinary for image storage instead of Firebase Storage

Image hosting was moved to Cloudinary due to billing/plan constraints around Firebase Storage in this project context.

Benefits:
- direct URL-based image hosting,
- simple unsigned upload preset flow,
- reliable image delivery for card preview/details.

**Tradeoff**
- adds one external dependency and credential/preset management.

---

## 4) OCR strategy decision

Current OCR approach:
- **Mobile (Android/iOS):** Google ML Kit on-device OCR.
- **Web:** Tesseract.js via JS interop.
- Shared post-processing parser in Dart (`card_text_parser.dart`) to infer structured fields.

Why:
- no mandatory paid OCR API,
- works offline/on-device for mobile,
- web-compatible fallback for browser usage.

**Tradeoff**
- OCR quality depends on image quality, layout, blur, perspective, and lighting.
- exact extraction cannot be guaranteed for every card image.

---

## 5) Search decision

Search is implemented with simple local/query-friendly token strategy on card fields (name/company/phone/email/address and related keywords), optimized for fast app-level filtering and Firestore usage patterns.

Why:
- predictable behavior,
- low complexity,
- fits project scope and timeline.

---

## 6) UI/UX decisions

Key decisions:
- dashboard-first workflow for active cards and vault images,
- lightweight profile management in Settings,
- persistent theme toggle (Dark/Light),
- shared visual scaffolding with glass/card motif and optional 3D background integration.

Why:
- improves perceived product polish quickly,
- keeps navigation simple and demo-friendly.

---

## 7) Security and ownership model

Every card record is tied to authenticated user identity (`userId`/UID), and reads/writes are scoped per user in app logic and intended Firestore rules.

Why:
- prevents cross-user access,
- supports multi-user deployment safely.

---

## 8) Not chosen (and why)

- Full custom backend from day one: rejected due to timeline and deployment overhead.
- Paid enterprise OCR SDK initially: rejected due to cost constraints.
- Firebase Storage-only approach: rejected for this project’s billing constraints.

---

## 9) If more time were available

1. Add server-side OCR pipeline (PaddleOCR/Cloud Vision) with confidence scoring.
2. Add automatic perspective correction + quality scoring before OCR.
3. Add retry/quality hints UI (“Retake card”, “Too blurry”).
4. Improve ranking-based search and duplicate card detection.
5. Add CI checks + conventional commit enforcement.
6. Add end-to-end tests (capture/upload -> extraction -> saved card verification).

---

## Final note

The stack was chosen to balance delivery speed, real usability, and cost constraints while keeping architecture extensible for stronger OCR and backend capabilities later.
