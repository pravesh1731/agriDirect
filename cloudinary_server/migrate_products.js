/**
 * migrate_products.js
 *
 * Backfill ownerName and ownerLocation into top-level products documents by
 * reading users/{farmerId}. Run locally with a Firebase service account.
 *
 * Usage:
 * 1) npm init -y
 * 2) npm install firebase-admin
 * 3) export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"
 * 4) node migrate_products.js
 *
 * The script will iterate all documents in `products` and for each doc that has
 * a `farmerId` and missing `ownerName` or `ownerLocation`, it will read the
 * corresponding user doc and write ownerName/ownerLocation to the product doc.
 *
 * IMPORTANT: run on a small batch first to confirm results. This script updates
 * documents in place and cannot be undone automatically.
 */

const admin = require('firebase-admin');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('Set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON file path first.');
  process.exit(1);
}

admin.initializeApp();
const db = admin.firestore();

async function migrate(batchSize = 200) {
  console.log('Starting migration: backfilling ownerName and ownerLocation in products...');

  let lastDoc = null;
  let totalUpdated = 0;
  while (true) {
    let q = db.collection('products').orderBy('__name__').limit(batchSize);
    if (lastDoc) q = q.startAfter(lastDoc);
    const snap = await q.get();
    if (snap.empty) break;

    const writes = [];
    for (const doc of snap.docs) {
      const data = doc.data();
      const farmerId = data.farmerId || data.farmerUID || data.farmer || null;
      const needsOwnerName = !data.ownerName || data.ownerName === '';
      const needsOwnerLocation = !data.ownerLocation || data.ownerLocation === '';
      if (!farmerId || (!needsOwnerName && !needsOwnerLocation)) {
        continue; // nothing to do
      }

      try {
        const userDoc = await db.collection('users').doc(farmerId).get();
        if (!userDoc.exists) {
          console.warn(`User doc not found for farmerId=${farmerId} (product ${doc.id})`);
          continue;
        }
        const u = userDoc.data() || {};
        const ownerName = (u.displayName || u.name || u.fullName || u.seller || '').toString();
        const ownerLocation = (u.location || u.farmLocation || u.address || '').toString();

        const update = {};
        if (needsOwnerName && ownerName) update.ownerName = ownerName;
        if (needsOwnerLocation && ownerLocation) update.ownerLocation = ownerLocation;

        if (Object.keys(update).length > 0) {
          writes.push(db.collection('products').doc(doc.id).set(update, { merge: true }));
          totalUpdated++;
          console.log(`Will update product ${doc.id} with`, update);
        }
      } catch (err) {
        console.error('Error fetching user or updating product:', err);
      }
    }

    if (writes.length > 0) {
      await Promise.all(writes);
      console.log(`Committed ${writes.length} updates in this batch.`);
    } else {
      console.log('No updates needed in this batch.');
    }

    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < batchSize) break;
  }

  console.log(`Done. Total products updated: ${totalUpdated}`);
}

migrate().catch(err => {
  console.error('Migration failed:', err);
  process.exit(2);
});

