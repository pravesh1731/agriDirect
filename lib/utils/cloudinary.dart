// Cloudinary configuration (client-side)
// Keep cloud name and unsigned upload preset here. Do NOT store API secret in the mobile app.

const String kCloudinaryCloudName = 'dyvdmvudt';
const String kCloudinaryUploadPreset = 'presentMe';

// NOTE: Do NOT keep your Cloudinary API key/secret in the client. Use the server-side admin
// component (cloudinary_server/) which reads CLOUDINARY_API_KEY and CLOUDINARY_API_SECRET from
// environment variables. The client should only call that server for admin operations (delete).

// Server endpoint that performs admin operations (delete). Configure and run the provided server locally or on your host.
// Example: http://10.0.2.2:4000  (use 10.0.2.2 for Android emulator to reach localhost)
const String kCloudinaryServerUrl = 'http://10.0.2.2:4000';
// If you configure the server with a server key, set it here (optional). Prefer keeping the key only on your client during development.
const String kCloudinaryServerKey = '';

// NOTE: For production, do NOT put API secret here. Use the server in `cloudinary_server/` which uses CLOUDINARY_API_KEY and CLOUDINARY_API_SECRET from environment variables.
