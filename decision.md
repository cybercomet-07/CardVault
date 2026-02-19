# DECISIONS.md — CardVault

## 1. Why Flutter?

Flutter was chosen because:
- It allows fast cross-platform development.
- Strong UI customization capabilities.
- Good Firebase integration support.
- Suitable for rapid MVP development.

Since the assignment mandates Flutter, the focus was on clean UI structure and maintainable architecture.

---

## 2. Why Firebase Instead of Custom Backend?

Firebase was selected to:
- Avoid backend deployment complexity.
- Speed up development within 4–5 days.
- Use built-in authentication and cloud storage.
- Reduce boilerplate REST API code.

Tradeoff:
- Limited complex querying compared to SQL.
- Less backend logic control.

---

## 3. Why Firestore (NoSQL)?

Firestore provides:
- Real-time data updates.
- Easy scaling.
- Simple document-based storage.
- Smooth Flutter integration.

Data modeling was designed carefully to support:
- User-based card isolation
- Search capability
- Expandability for future features

---

## 4. Why On-Device OCR (Google ML Kit)?

Google ML Kit was chosen because:
- No external API dependency.
- Faster processing.
- No additional cost.
- Works offline.

Tradeoff:
- OCR accuracy depends on image clarity.

---

## 5. Search Design Decision

Search is implemented using:
- Keyword array storage
- Firestore query with arrayContains

Each card stores searchable tokens such as:
- Name
- Company
- Email
- Phone
- Extracted words

This allows flexible searching across multiple fields.

---

## 6. Improvements With More Time

If more time were available, improvements would include:
- Advanced NLP parsing for better OCR accuracy
- Duplicate card detection
- Better search ranking algorithm
- Cloud-based full-text search integration (Algolia)
- Card categorization and tagging
