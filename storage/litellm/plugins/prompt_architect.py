import litellm
import asyncio
import re
from litellm.integrations.custom_logger import CustomLogger

# These MUST match the 'model_name' aliases in your config.yaml exactly
ARCHITECT_MODEL = "deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"
ENGINE_MODEL = "Qwen/Qwen3-8B"

class PromptArchitectPlugin(CustomLogger):
    async def async_pre_call_hook(
        self, user_api_key_dict, cache, data, call_type
    ):
        # Now this will correctly intercept the UI/App requests
        if call_type == "completion" and data.get("model") == ENGINE_MODEL:
            
            original_messages = data.get("messages", [])
            raw_user_input = original_messages[-1].get("content", "") if original_messages else ""
            
            architect_prompt = (
                "You are the System Architect. Analyze this request and output "
                "a rigid, step-by-step engineering specification.\n\n"
                f"Request: {raw_user_input}"
            )
            
            print(f"[Architect Plugin] Intercepted prompt. Pinging {ARCHITECT_MODEL}...")
            
            try:
                architect_response = await litellm.acompletion(
                    model=ARCHITECT_MODEL,
                    messages=[{"role": "user", "content": architect_prompt}],
                    max_tokens=1500
                )
                
                raw_blueprint = architect_response.choices[0].message.content
                
                # Strip out the <think>...</think> reasoning block
                # re.DOTALL ensures the regex matches across multiple lines
                cleaned_blueprint = re.sub(
                    r'<think>.*?</think>', 
                    '', 
                    raw_blueprint, 
                    flags=re.DOTALL
                ).strip()
                
                print("[Architect Plugin] Blueprint generated and reasoning stripped. Passing to Engine.")
                
                system_instruction = (
                    "You are a Principal Engineer. Execute the following blueprint strictly."
                )
                
                # Overwrite the payload going down to Qwen3
                data["messages"] = [
                    {"role": "system", "content": system_instruction},
                    {"role": "user", "content": cleaned_blueprint}
                ]
                
            except Exception as e:
                print(f"[Architect Plugin Error] Failed to ping Refiner: {str(e)}")
            
        return data