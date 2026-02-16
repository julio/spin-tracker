import { createHmac } from "https://deno.land/std@0.168.0/node/crypto.ts";

function percentEncode(str: string): string {
  return encodeURIComponent(str).replace(/[!'()*]/g, (c) =>
    `%${c.charCodeAt(0).toString(16).toUpperCase()}`
  );
}

function generateNonce(): string {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let result = "";
  for (let i = 0; i < 32; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

export function generateOAuthHeader(
  method: string,
  url: string,
  consumerKey: string,
  consumerSecret: string,
  token?: string,
  tokenSecret?: string,
  extraParams?: Record<string, string>,
): string {
  const timestamp = Math.floor(Date.now() / 1000).toString();
  const nonce = generateNonce();

  const oauthParams: Record<string, string> = {
    oauth_consumer_key: consumerKey,
    oauth_nonce: nonce,
    oauth_signature_method: "HMAC-SHA1",
    oauth_timestamp: timestamp,
    oauth_version: "1.0",
  };

  if (token) {
    oauthParams["oauth_token"] = token;
  }

  if (extraParams) {
    Object.assign(oauthParams, extraParams);
  }

  // Parse URL to extract query params
  const urlObj = new URL(url);
  const allParams: Record<string, string> = { ...oauthParams };
  urlObj.searchParams.forEach((value, key) => {
    allParams[key] = value;
  });

  // Build base URL (without query string)
  const baseUrl = `${urlObj.origin}${urlObj.pathname}`;

  // Sort and encode params for signature base string
  const paramString = Object.keys(allParams)
    .sort()
    .map((key) => `${percentEncode(key)}=${percentEncode(allParams[key])}`)
    .join("&");

  const signatureBaseString = `${method.toUpperCase()}&${percentEncode(baseUrl)}&${percentEncode(paramString)}`;
  const signingKey = `${percentEncode(consumerSecret)}&${percentEncode(tokenSecret || "")}`;

  const hmac = createHmac("sha1", signingKey);
  hmac.update(signatureBaseString);
  const signature = hmac.digest("base64") as string;

  oauthParams["oauth_signature"] = signature;

  // Build Authorization header (only oauth_ params, not extra params)
  const headerParams = Object.keys(oauthParams)
    .filter((key) => key.startsWith("oauth_"))
    .sort()
    .map((key) => `${percentEncode(key)}="${percentEncode(oauthParams[key])}"`)
    .join(", ");

  return `OAuth ${headerParams}`;
}
