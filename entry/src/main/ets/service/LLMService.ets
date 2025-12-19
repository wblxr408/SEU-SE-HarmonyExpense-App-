import http from '@ohos.net.http';

/**
 * Message Interface
 */
export interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

interface LLMMessageContent {
  content: string;
}

interface LLMResponseChoice {
  message: LLMMessageContent;
}

interface LLMResponse {
  choices: LLMResponseChoice[];
}

/**
 * LLM Service
 * Handles communication with Large Language Model APIs
 */
export class LLMService {
  // Default configuration (User should replace these)
  private static readonly DEFAULT_API_URL = 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions'; 
  private static readonly API_KEY_KEY = 'llm_api_key';
  private static readonly API_URL_KEY = 'llm_api_url';

  /**
   * Send chat request to LLM
   * @param messages Conversation history
   * @param model Model name (e.g., qwen-turbo, qwen-plus)
   * @returns Full response string
   */
  static async chat(messages: ChatMessage[], model: string = 'qwen-turbo'): Promise<string> {
    try {
      // 1. Get Config
      // Use AppStorage/PersistentStorage
      if (!AppStorage.Has('LLM_API_KEY')) {
        PersistentStorage.PersistProp('LLM_API_KEY', '');
      }
      
      const apiUrl = LLMService.DEFAULT_API_URL;
      const apiKey = AppStorage.Get<string>('LLM_API_KEY');

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
          model: model, 
          messages: messages,
          stream: false // For simplicity in v1, we use non-streaming
        },
        readTimeout: 60000,
        connectTimeout: 60000
      });

      // 3. Parse Response
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as LLMResponse;
        if (result.choices && result.choices.length > 0) {
          return result.choices[0].message.content;
        } else {
          throw new Error('Invalid response format');
        }
      } else {
        throw new Error(`HTTP Error: ${response.responseCode}`);
      }
    } catch (error) {
      console.error('[LLMService]', JSON.stringify(error));
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error(JSON.stringify(error));
      }
    }
  }
}
