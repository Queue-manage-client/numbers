import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  GoogleGenerativeAI,
  HarmCategory,
  HarmBlockThreshold,
} from "https://esm.sh/@google/generative-ai@0.21.0";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 認証チェック
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "認証が必要です" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const {
      data: { user },
    } = await supabaseClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "認証に失敗しました" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { message, history } = await req.json();

    if (!message || typeof message !== "string") {
      return new Response(
        JSON.stringify({ error: "メッセージが必要です" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // メッセージ長制限
    if (message.length > 5000) {
      return new Response(
        JSON.stringify({
          error: "メッセージが長すぎます（5000文字以内にしてください）",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ai_configから設定を取得
    let modelName = "gemini-2.5-flash";
    let systemPrompt =
      "あなたは就活支援AIアシスタントです。ユーザーの就職活動、インターンシップ、面接対策、自己PR、企業研究などの質問に対して、親切で的確なアドバイスを日本語で提供してください。回答は簡潔で分かりやすくしてください。";
    let temperature = 0.7;
    let maxTokens = 1024;
    let maxHistory = 50;

    try {
      const { data: config } = await supabaseClient
        .from("ai_config")
        .select()
        .eq("is_active", true)
        .limit(1)
        .maybeSingle();

      if (config) {
        modelName = config.model_name ?? modelName;
        systemPrompt = config.system_prompt ?? systemPrompt;
        temperature = config.temperature ?? temperature;
        maxTokens = config.max_output_tokens ?? maxTokens;
        maxHistory = config.max_history_length ?? maxHistory;
      }
    } catch {
      // フォールバック値を使用
    }

    const apiKey = Deno.env.get("GOOGLE_AI_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "AI機能の設定に問題があります" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: modelName,
      systemInstruction: systemPrompt,
      generationConfig: {
        temperature,
        maxOutputTokens: maxTokens,
      },
      safetySettings: [
        {
          category: HarmCategory.HARM_CATEGORY_HARASSMENT,
          threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
        },
        {
          category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
          threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
        },
      ],
    });

    // 会話履歴を構築
    const recentHistory = (history ?? []).slice(-maxHistory);
    const chatHistory = recentHistory.map(
      (msg: { role: string; content: string }) => ({
        role: msg.role === "user" ? "user" : "model",
        parts: [{ text: msg.content || "" }],
      })
    );

    const chat = model.startChat({ history: chatHistory });
    const result = await chat.sendMessage(message);
    const responseText =
      result.response.text() ?? "すみません、回答を生成できませんでした。";

    return new Response(JSON.stringify({ response: responseText }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const msg = String(e);
    let userMessage = "エラーが発生しました。しばらくしてからもう一度お試しください。";
    if (msg.includes("Resource exhausted") || msg.includes("429")) {
      userMessage =
        "ただいまアクセスが集中しています。少し時間をおいてから再度お試しください。";
    } else if (
      msg.includes("SocketException") ||
      msg.includes("ClientException")
    ) {
      userMessage = "ネットワーク接続を確認してください。";
    }

    return new Response(JSON.stringify({ error: userMessage }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
