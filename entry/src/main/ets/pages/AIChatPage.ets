import router from '@ohos.router';
import { LLMService, ChatMessage } from '../service/LLMService';
import promptAction from '@ohos.promptAction';
import { UserSessionService } from '../service/UserSessionService';
import { AccountDAO } from '../dao/AccountDAO';
import { BillDAO } from '../dao/BillDAO';
import { Bill } from '../model/Bill';
import { Account } from '../model/Account';
import { BusinessError } from '@kit.BasicServicesKit';


class ModelOption {
  value: string;
  constructor(value: string) {
    this.value = value;
  }
}

@Entry
@Component
struct AIChatPage {
  @State messages: ChatMessage[] = [
    { role: 'system', content: 'You are a helpful financial assistant.' },
    { role: 'assistant', content: '你好！我是你的智能记账助手。有什么我可以帮你的吗？' }
  ];
  @State userInput: string = '';
  @State isLoading: boolean = false;
  @State selectedModel: string = 'qwen-turbo'; // Default model
  private scroller: Scroller = new Scroller();
  
  private modelOptions: ModelOption[] = [
    new ModelOption('qwen-turbo'),
    new ModelOption('qwen-plus'),
    new ModelOption('qwen-max'),
    new ModelOption('qwen-long') 
  ];

  async aboutToAppear() {
    await this.initFinancialContext();
  }

  async initFinancialContext() {
    try {
      if (!UserSessionService.isLoggedIn()) return;
      
      const userId = UserSessionService.getCurrentUserId();
      if (!userId) return; // Ensure userId is valid
      
      // 1. Fetch Data concurrently
      const results = await Promise.all([
        AccountDAO.getByUserId(userId),
        BillDAO.getTotalStats(userId),
        BillDAO.getBillsByUserId(userId)
      ]);
      const accounts = results[0];
      const totalStats = results[1];
      const bills = results[2];

      // 2. Build Context String
      let context = '\n\n【用户财务档案】\n';
      
      // Accounts
      context += '1. 资产状况:\n';
      accounts.forEach((acc) => {
        context += `   - ${acc.name} (${acc.type}): ${acc.balance.toFixed(2)}\n`;
      });

      // Overview
      context += `2. 收支概览 (总计):\n   - 总收入: ${totalStats.totalIncome.toFixed(2)}\n   - 总支出: ${totalStats.totalExpense.toFixed(2)}\n   - 净资产: ${totalStats.balance.toFixed(2)}\n`;

      // Recent Transactions (Limit to 10)
      context += '3. 最近 10 笔交易:\n';
      const recentBills = bills.slice(0, 10);
      recentBills.forEach((bill) => {
         const dateStr = bill.transactionDate.split('T')[0];
         context += `   - ${dateStr} [${bill.type === 'expense' ? '支出' : '收入'}] ${bill.amount.toFixed(2)} (${bill.note || '无备注'})\n`;
      });

      context += '\n请根据以上财务数据回答用户的问题。如果用户询问具体数字，请优先参考上述档案。';

      // 3. Inject into System Prompt
      if (this.messages.length > 0 && this.messages[0].role === 'system') {
        this.messages[0].content += context;
        console.info('[AIChatPage] User context injected successfully.');
      }

    } catch (error) {
      console.error('[AIChatPage] Failed to load financial context:', error);
    }
  }

  async sendMessage() {
    if (!this.userInput.trim()) return;

    const userMsg = this.userInput;
    this.userInput = ''; // Clear input immediately
    
    // Add User Message
    this.messages.push({ role: 'user', content: userMsg });
    this.scrollToBottom();

    this.isLoading = true;

    try {
      // Call LLM Service
      // Note: We send the full history context
      const reply = await LLMService.chat(this.messages, this.selectedModel);
      
      // Add Assistant Message
      this.messages.push({ role: 'assistant', content: reply });
      this.scrollToBottom();
    } catch (error) {
      console.error('Chat Error:', error);
      let errorMsg = `抱歉，出现了错误: ${error.message}`;
      // Check for specific network errors
      // Check for specific network errors (ArkTS compliant)
      const err = error as BusinessError;
      if (err.code === 2300006) {
           errorMsg = '网络连接失败，请检查设备或模拟器的网络连接。';
      }
      if (error.message.includes('API Key')) {
        errorMsg = '请先在设置中配置 API Key。';
      }
      this.messages.push({ role: 'assistant', content: `[系统消息] ${errorMsg}` });
      promptAction.showToast({ message: errorMsg });
    } finally {
      this.isLoading = false;
      this.scrollToBottom();
    }
  }

  scrollToBottom() {
    // Small delay to ensure list is updated
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 100);
  }

  build() {
    Navigation() {
      Column() {
        // Model Selector
        Row() {
          Text('模型: ')
            .fontSize(14)
            .fontColor(Color.Gray)
          Select(this.modelOptions)
            .selected(0)
            .value(this.selectedModel)
            .font({ size: 14 })
            .fontColor('#333333')
            .selectedOptionFont({ size: 14 })
            .optionFont({ size: 14 })
            .onSelect((index: number) => {
              this.selectedModel = this.modelOptions[index].value;
            })
        }
        .width('100%')
        .padding({ left: 15, right: 15, top: 10, bottom: 5 })
        .backgroundColor('#F9F9F9')
        .justifyContent(FlexAlign.End)

        // Chat History
        List({ scroller: this.scroller }) {
          ForEach(this.messages.filter(m => m.role !== 'system'), (msg: ChatMessage) => {
            ListItem() {
              this.MessageBubble(msg)
            }
          })
          if (this.isLoading) {
            ListItem() {
               Row() {
                 Text('AI 正在思考...')
                   .fontSize(12)
                   .fontColor(Color.Gray)
               }
               .width('100%')
               .justifyContent(FlexAlign.Center)
               .padding(10)
            }
          }
        }
        .layoutWeight(1)
        .width('100%')
        .padding(10)

        // Input Area
        Row() {
          TextInput({ placeholder: '输入您的问题...', text: this.userInput })
            .onChange((value) => {
              this.userInput = value;
            })
            .onSubmit(() => {
              this.sendMessage();
            })
            .layoutWeight(1)
            .margin({ right: 10 })
            .height(40)
            .backgroundColor(Color.White)
            .borderRadius(20)

          Button('发送')
            .onClick(() => {
              this.sendMessage();
            })
            .height(40)
            .type(ButtonType.Capsule)
            .enabled(!this.isLoading)
        }
        .padding(10)
        .backgroundColor('#F1F3F5')
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F9F9F9')
    }
    .title('智能助手')
    .titleMode(NavigationTitleMode.Mini)
  }

  @Builder
  MessageBubble(msg: ChatMessage) {
    Row() {
      if (msg.role === 'user') {
        // User (Right)
        Blank()
        Text(msg.content)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#007DFF')
          .padding(10)
          .borderRadius(10)
          .margin({ left: 40 })
      } else {
        // Assistant (Left)
        Text(msg.content)
          .fontSize(16)
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .padding(10)
          .borderRadius(10)
          .margin({ right: 40 })
        Blank()
      }
    }
    .width('100%')
    .padding({ top: 5, bottom: 5 })
  }
}
