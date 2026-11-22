# Chandak Press 360 — Build 1

यह Build 1 का सुरक्षित सुधार चरण है: Firebase Authentication + Firestore, role-based screens, agent order submission, admin product/media/rate setup, formula-based amount preview, order status, payments और ledger views. इस branch में नए Agent orders की रकम Admin approval से पहले provisional रहती है।

## 1. Firebase config
आपके दिए हुए Firebase Web App config को `src/firebase-config.js` में पहले से सेट कर दिया गया है। यह public client config है; Service Account private key कभी browser में न डालें। `.firebaserc` में आपका project `chandak-offset-press360` सेट है।

## 2. Firebase Authentication
Authentication → Sign-in method में Email/Password चालू करें। Authentication → Users में Admin, Staff और Agent के login accounts बनाएँ।

## 3. पहला Admin
पहले Admin account से एक बार sign-in करने से पहले Firestore Console में `users` collection बनाएँ:
- Document ID: उस Admin का Firebase Authentication UID
- Fields: `name` (string), `role` (string: `admin`), `active` (boolean: `true`)

इसके बाद Admin login कर सकता है। Admin app के Users पेज से अन्य UID के role profiles जोड़ सकता है। Auth user account अलग से Firebase Console में बनाना होगा।

## 4. Firestore rules
Firestore → Rules में `firestore.rules` की सामग्री डालकर Publish करें। Publish से पहले अपने project में test करें।

## 5. Firebase Hosting deploy
यह ES module आधारित static website है। इसे local `file://` से न खोलें। Firebase Hosting पर deploy करने के लिए कंप्यूटर में Node.js और Firebase CLI चाहिए:

```bash
npm install -g firebase-tools
firebase login
# इस folder के अंदर terminal खोलें
firebase use chandak-offset-press360
firebase deploy --only hosting,firestore:rules
```

`firebase.json` और `.firebaserc` पहले से शामिल हैं। Deploy के बाद Firebase Console → Hosting में मिली website URL खोलें। Firebase Console → Authentication → Settings → Authorized domains में Hosting domain मौजूद है, यह भी जाँचें।

## 6. Product formulas
Admin Product पेज में custom field label और key जोड़ता है। Formula में `qty`, `rate` और custom keys इस्तेमाल होते हैं। مثال:
- `width*height*qty*rate`
- `qty*rate`
- `(width+height)*2*qty*rate`

केवल `+ - * / ( )` और numeric variables स्वीकार होते हैं। `eval()` इस्तेमाल नहीं किया गया है। Unit label free text है।

## 7. Final payment model: Agent Wallet

पुराना per-order manual payment clearance अंतिम workflow नहीं है। तय किया गया अंतिम मॉडल:
- हर Agent का अपना prepaid Wallet होगा।
- Admin हर Agent के लिए 0–10% discount तय करेगा; discount उसके नए orders पर अपने आप लागू होगा।
- Agent UPI QR या Bank Transfer से recharge request करेगा। Admin वास्तविक बैंक/UPI receipt verify करने के बाद ही wallet credit करेगा।
- Order amount authoritative rate master से trusted backend पर calculate होगा; browser से भेजी गई amount पर भरोसा नहीं होगा।
- Discount के बाद payable amount Wallet से atomically debit होगा और उसी transaction में order बनेगा।
- Insufficient balance पर न order बनेगा, न debit होगा।
- हर recharge, debit, refund और adjustment का immutable ledger रहेगा।

D1 की शुरुआती schema `migrations/0001_wallet.sql` में है। विस्तृत architecture और सुरक्षा शर्तें `WALLET-ARCHITECTURE-HI.md` में हैं।

**महत्वपूर्ण स्थिति:** अभी यह schema/design foundation है, live Wallet feature नहीं। Cloudflare Worker authentication, trusted rate calculation, atomic debit/order creation, admin recharge verification और end-to-end tests पूरे होने तक इसे live financial use में न लें।

## 9. अभी शामिल नहीं
- PDF invoice / monthly statement export
- File/photo uploads (Firebase Storage billing requirement के कारण)
- WhatsApp automation
- Full LAN/multi-user conflict-safe accounting engine
- Server-verified pricing and immutable audit log
- Advanced staff permission matrix, backup/restore UI, expenses/suppliers

इनको production release से पहले अलग चरण में implement और test करना होगा।


## Payment gate (new)
- हर नया Agent order `Awaiting Payment` और `Unpaid` से शुरू होता है।
- पूरा भुगतान मिलने पर Admin/Staff Payments स्क्रीन में उसी Order को चुनकर भुगतान दर्ज करेगा। रिकॉर्ड होने पर Order `Paid` और `Queued` होगा।
- केवल `Paid` orders Production Queue में दिखाई देंगे। Unpaid order का production status आगे नहीं बढ़ सकता।
- इस चरण में partial payment स्वीकार नहीं है; पूरी order amount मिलने पर ही job queue में जाएगी।
- Agent स्वयं payment को Paid mark नहीं कर सकता।
