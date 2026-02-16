import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { generateOAuthHeader } from "../_shared/oauth.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Verify user JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const consumerKey = Deno.env.get("DISCOGS_CONSUMER_KEY");
    const consumerSecret = Deno.env.get("DISCOGS_CONSUMER_SECRET");

    if (!consumerKey || !consumerSecret) {
      return new Response(
        JSON.stringify({ error: "Discogs credentials not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Verify user with anon key + user's JWT
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: userError } = await userClient.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Request token from Discogs
    const requestTokenUrl = "https://api.discogs.com/oauth/request_token";
    const oauthHeader = generateOAuthHeader(
      "POST",
      requestTokenUrl,
      consumerKey,
      consumerSecret,
      undefined,
      undefined,
      { oauth_callback: "needl://discogs-callback" },
    );

    const response = await fetch(requestTokenUrl, {
      method: "POST",
      headers: {
        "Authorization": oauthHeader,
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": "Needl/1.0",
      },
    });

    if (!response.ok) {
      const body = await response.text();
      return new Response(
        JSON.stringify({ error: "Discogs request token failed", details: body }),
        { status: response.status, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const body = await response.text();
    const params = new URLSearchParams(body);
    const requestToken = params.get("oauth_token");
    const requestTokenSecret = params.get("oauth_token_secret");

    if (!requestToken || !requestTokenSecret) {
      return new Response(
        JSON.stringify({ error: "Invalid response from Discogs" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Store temp tokens using service_role (bypasses RLS)
    const adminClient = createClient(supabaseUrl, supabaseServiceKey);
    const { error: upsertError } = await adminClient
      .from("discogs_oauth_temp")
      .upsert({
        user_id: user.id,
        request_token: requestToken,
        request_token_secret: requestTokenSecret,
      });

    if (upsertError) {
      return new Response(
        JSON.stringify({ error: "Failed to store request token", details: upsertError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({
        authorize_url: `https://discogs.com/oauth/authorize?oauth_token=${requestToken}`,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
