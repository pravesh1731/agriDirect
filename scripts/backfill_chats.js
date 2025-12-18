/*
Backfill script: populate `participants` array for existing chats that are missing it.
Usage:
1) Install firebase-admin: npm install firebase-admin
2) Export service account credentials: export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccount.json"
3) Run: node scripts/backfill_chats.js

The script will scan all documents in `chats` collection, and for each doc missing `participants` or with an empty participants array,
it will set `participants = [buyerId, farmerId].filter(Boolean)` if buyerId/farmerId are present.
It is safe to re-run; it will skip docs that already have a non-empty participants array.
*/

const admin = require('firebase-admin');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('ERROR: Set GOOGLE_APPLICATION_CREDENTIALS to your service account json path before running.');
  process.exit(1);
}

admin.initializeApp();
const db = admin.firestore();

async function backfill() {
  console.log('Scanning chats collection...');
  const snapshot = await db.collection('chats').get();
  console.log(`Found ${snapshot.size} chat docs.`);
  let changed = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const participants = data.participants;
    if (Array.isArray(participants) && participants.length > 0) {
      // already fine
      continue;
    }
    const buyerId = typeof data.buyerId === 'string' ? data.buyerId : '';
    const farmerId = typeof data.farmerId === 'string' ? data.farmerId : '';
    const newParts = [];
    if (buyerId) newParts.push(buyerId);
    if (farmerId && farmerId !== buyerId) newParts.push(farmerId);
    if (newParts.length === 0) {
      console.log(`Skipping ${doc.id}: no buyerId/farmerId to build participants.`);
      continue;
    }
    try {
      await doc.ref.update({ participants: newParts });
      console.log(`Updated ${doc.id} -> participants: [${newParts.join(',')}]`);
      changed++;
    } catch (e) {
      console.error(`Failed to update ${doc.id}:`, e.message || e);
    }
  }
  console.log(`Backfill complete. Updated ${changed} documents.`);
}

backfill().catch(err => {
  console.error('Backfill failed:', err);
  process.exit(1);
});

