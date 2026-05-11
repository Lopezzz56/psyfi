import { serve } from "https://deno.land/std@0.131.0/http/server.ts";
import { GoogleAuth } from "npm:google-auth-library";

serve(async (req) => {
  try {
    console.log("✅ Request received");

    const payload = await req.json();
    console.log("📦 Payload received:", JSON.stringify(payload));

    const { sender_id, receiver_id, message, is_seen } = payload.record || {};

    if (!sender_id || !receiver_id || !message) {
      console.error("❌ Missing required fields in payload:", payload.record);
      return new Response("Invalid payload", { status: 400 });
    }

    if (is_seen !== false) {
      console.log("🔕 Message already seen — skipping notification");
      return new Response("Message already seen — skipping notification", { status: 200 });
    }

    // Step 1: Get Google Access Token
    console.log("🔐 Getting Firebase access token");
    const auth = new GoogleAuth({
      credentials: JSON.parse(Deno.env.get("GOOGLE_SERVICE_ACCOUNT")!),
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });

    const client = await auth.getClient();
    const accessToken = await client.getAccessToken();
    console.log("✅ Access token obtained");

    // Step 2: Supabase settings
    const supabaseUrl = Deno.env.get("SERVICE_SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Step 3: Fetch sender's info from users table
    const senderInfoUrl = `${supabaseUrl}/rest/v1/users?id=eq.${sender_id}`;
    const senderInfoRes = await fetch(senderInfoUrl, {
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
      },
    });

    if (!senderInfoRes.ok) {
      const errorText = await senderInfoRes.text();
      console.error("❌ Failed to fetch sender info:", errorText);
      return new Response("Failed to fetch sender info", { status: 500 });
    }

    const senderData = await senderInfoRes.json();
    const sender = senderData[0] || {};
    const senderName = sender.username || "Unknown";
    const senderImage = sender.image_url || "";

    // Step 4: Get receiver's device tokens
    const deviceTokensUrl = `${supabaseUrl}/rest/v1/device_tokens?user_id=eq.${receiver_id}`;
    console.log(`🔍 Fetching device tokens for receiver_id: ${receiver_id}`);

    const deviceTokensRes = await fetch(deviceTokensUrl, {
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
      },
    });

    if (!deviceTokensRes.ok) {
      const errorText = await deviceTokensRes.text();
      console.error("❌ Failed to fetch device tokens:", errorText);
      return new Response("Failed to fetch device tokens", { status: 500 });
    }

    const deviceTokens = await deviceTokensRes.json();
    console.log(`📱 Device tokens found: ${deviceTokens.length}`);

    if (deviceTokens.length === 0) {
      console.warn("⚠️ No device tokens found for receiver:", receiver_id);
      return new Response("No device tokens found", { status: 404 });
    }

    // Step 5: Send notifications
    for (const tokenObj of deviceTokens) {
      console.log("📤 Sending notification to token:", tokenObj.fcm_token);

      const fcmRes = await fetch(
        "https://fcm.googleapis.com/v1/projects/psyfi-f6f44/messages:send",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken.token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: tokenObj.fcm_token,
              notification: {
                title: senderName,
                body: message,
              },
              data: {
                type: "chat",
                sender_id: sender_id,
                sender_name: senderName,
                sender_image: senderImage,
              },
            },
          }),
        }
      );

      const fcmResponseText = await fcmRes.text();
      if (!fcmRes.ok) {
        console.error("❌ Failed to send FCM notification:", fcmResponseText, "Token:", tokenObj.fcm_token);
      } else {
        console.log("✅ Notification sent successfully to token:", tokenObj.fcm_token);
      }
    }

    return new Response("Notifications sent", { status: 200 });

  } catch (error) {
    console.error("🔥 Error during notification process:", error);
    return new Response(`Internal Server Error: ${error.message}`, { status: 500 });
  }
});
