import { serve } from "https://deno.land/std@0.131.0/http/server.ts";
import { GoogleAuth } from "npm:google-auth-library";
serve(async (req)=>{
  try {
    console.log("✅ Motivation trigger received");
    const payload = await req.json();
    console.log("📦 Payload received:", JSON.stringify(payload));
    const { name } = payload.record || {};
    if (!name) {
      console.error("❌ Missing 'name' in payload:", payload.record);
      return new Response("Invalid payload", {
        status: 400
      });
    }
    // Step 1: Get Google Access Token
    console.log("🔐 Getting Firebase access token");
    const auth = new GoogleAuth({
      credentials: JSON.parse(Deno.env.get("GOOGLE_SERVICE_ACCOUNT")),
      scopes: [
        "https://www.googleapis.com/auth/firebase.messaging"
      ]
    });
    const client = await auth.getClient();
    const accessToken = await client.getAccessToken();
    console.log("✅ Access token obtained");
    // Step 2: Supabase settings
    const supabaseUrl = Deno.env.get("SERVICE_SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    // Step 3: Fetch all device tokens
    const deviceTokensUrl = `${supabaseUrl}/rest/v1/device_tokens`;
    console.log("🔍 Fetching all device tokens");
    const deviceTokensRes = await fetch(deviceTokensUrl, {
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`
      }
    });
    if (!deviceTokensRes.ok) {
      const errorText = await deviceTokensRes.text();
      console.error("❌ Failed to fetch device tokens:", errorText);
      return new Response("Failed to fetch device tokens", {
        status: 500
      });
    }
    const deviceTokens = await deviceTokensRes.json();
    console.log(`📱 Device tokens found: ${deviceTokens.length}`);
    if (deviceTokens.length === 0) {
      console.warn("⚠️ No device tokens found");
      return new Response("No device tokens found", {
        status: 404
      });
    }
    // Step 4: Send notifications
    for (const tokenObj of deviceTokens){
      console.log("📤 Sending motivation notification to token:", tokenObj.fcm_token);
      const fcmRes = await fetch("https://fcm.googleapis.com/v1/projects/psyfi-f6f44/messages:send", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken.token}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          message: {
            token: tokenObj.fcm_token,
            notification: {
              title: "New Post",
              body: name
            },
            data: {
              type: "motivation"
            }
          }
        })
      });
      const fcmResponseText = await fcmRes.text();
      if (!fcmRes.ok) {
        console.error("❌ Failed to send FCM motivation notification:", fcmResponseText, "Token:", tokenObj.fcm_token);
      } else {
        console.log("✅ Motivation notification sent to token:", tokenObj.fcm_token);
      }
    }
    return new Response("Motivation notifications sent", {
      status: 200
    });
  } catch (error) {
    console.error("🔥 Error in motivation notification process:", error);
    return new Response(`Internal Server Error: ${error.message}`, {
      status: 500
    });
  }
});
