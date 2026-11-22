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

## 7. Agent order amount approval और वित्तीय सुरक्षा
नए Agent orders `billingStatus: PendingReview` के साथ बनते हैं। Admin Orders पेज में रकम जाँचकर सही रकम दर्ज करता है और **रकम मंजूर** दबाता है। केवल मंजूर orders ही नए Dashboard totals, monthly reports और ledgers में शामिल होते हैं। Staff केवल order status बदल सकता है; amount या billing approval नहीं। Firestore Rules भी यही सीमाएँ लागू करते हैं। पुराने orders जिनमें `billingStatus` नहीं है, वे पुराने रिकॉर्ड के रूप में मंजूर माने जाते हैं।

**महत्वपूर्ण:** Admin approval workflow client-side UI के साथ Firestore Rules से role-gated है; यह server-side formula calculation नहीं है। Admin को मंजूरी से पहले product, media, dimensions और rate जाँचने होंगे।

## 8. बहुत जरूरी वित्तीय सुरक्षा सीमा
इस build में Agent browser पर amount calculate करता है और Firestore order document में amount भेजता है। Firestore Rules केवल role और ownership validate करते हैं; वे मनमाने custom formula का सही result verify नहीं कर सकते। इसलिए technically knowledgeable user browser request बदलकर amount बदल सकता है। इस build को live financial billing के लिए तब तक final न मानें जब तक server-side price validation लागू न हो।

Firebase Spark plan पर Cloud Functions deploy करने के लिए billing/Blaze की जरूरत पड़ सकती है। बिना card/paid plan के विकल्प:
1. Orders को `Submitted` रखें और Admin द्वारा rate/amount verify करके approve करने के बाद ही bill/ledger में जोड़ें; या
2. ऐसा backend चुनें जो free tier में server-side functions देता हो और उसकी limits/terms पहले verify करें।

## 9. अभी शामिल नहीं
- PDF invoice / monthly statement export
- File/photo uploads (Firebase Storage billing requirement के कारण)
- WhatsApp automation
- Full LAN/multi-user conflict-safe accounting engine
- Server-verified pricing and immutable audit log
- Advanced staff permission matrix, backup/restore UI, expenses/suppliers

इनको production release से पहले अलग चरण में implement और test करना होगा।
