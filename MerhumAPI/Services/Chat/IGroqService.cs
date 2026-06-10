using MerhumAPI.Services.Groq;

namespace MerhumAPI.Services.Chat;

public interface IGroqService
{
    Task<string> GetChatResponseAsync(string systemPrompt, string userMessage, List<GroqMessage>? conversationHistory = null);
}
