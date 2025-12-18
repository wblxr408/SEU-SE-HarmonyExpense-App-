import http from '@ohos.net.http';

/**
 * Message Interface
 */
export interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

/**
 * LLM Service
 * Handles communication with Large Language Model APIs
 */
export class LLMService {
  // Default configuration (User should replace these)
  private static readonly DEFAULT_API_URL = 'https://api.deepseek.com/chat/completions'; // Example standard OpenAI-compatible endpoint
  private static readonly API_KEY_KEY = 'llm_api_key';
  private static readonly API_URL_KEY = 'llm_api_url';

  /**
   * Send chat request to LLM
   * @param messages Conversation history
   * @param onChunk Callback for stream updates (optional)
   * @returns Full response string
   */
  static async chat(messages: ChatMessage[]): Promise<string> {
    try {
      // 1. Get Config (In a real app, fetch from Preferences)
      // For now, we use hardcoded values for testing or require user input
      const apiUrl = LLMService.DEFAULT_API_URL;
      const apiKey = ''; // TODO: User needs to provide this

      // Check if API Key is set
      if (!apiKey) {
        throw new Error('API Key not configured');
      }

      // 2. Create HTTP Request
      const httpRequest = http.createHttp();
      
      const response = await httpRequest.request(apiUrl, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        extraData: {
          model: 'deepseek-chat', // or 'gpt-3.5-turbo', etc.
          messages: messages,
          stream: false // For simplicity in v1, we use non-streaming
        },
        readTimeout: 60000,
        connectTimeout: 60000
      });

      // 3. Parse Response
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string);
        if (result.choices && result.choices.length > 0) {
          return result.choices[0].message.content;
        } else {
          throw new Error('Invalid response format');
        }
      } else {
        throw new Error(`HTTP Error: ${response.responseCode}`);
      }
    } catch (error) {
      console.error('[LLMService]', error);
      throw error;
    }
  }
}
