import litellm
import asyncio
from litellm.integrations.custom_logger import CustomLogger

# The exact model aliases from your config.yaml
ARCHITECT_MODEL = "deepseek-architect"
ENGINE_MODEL = "qwen3-engine"

class PromptArchitectPlugin(CustomLogger):
    async def async_pre_call_hook(
        self, user_api_key_dict, cache, data, call_type
    ):
        """
        Intercepts the request BEFORE it hits the primary engine.
        If the target is the engine, it pings the Architect first.
        """
        # Only intercept if the user is calling the primary engine
        if call_type == "completion" and data.get("model") == ENGINE_MODEL:
            
            original_messages = data.get("messages", [])
            raw_user_input = original_messages[-1].get("content", "") if original_messages else ""
            
            # Step 1: Query the Architect internally
            architect_prompt = (
                f"You are the System Architect. Analyze this request and output "
                f"a rigid, step-by-step engineering specification. "
                f"Request: {raw_user_input}"
            )
            
            print(f"[Architect Plugin] Pinging {ARCHITECT_MODEL}...")
            
            try:
                # Use litellm.acompletion to make an internal async call to the refiner
                architect_response = await litellm.acompletion(
                    model=ARCHITECT_MODEL,
                    messages=[{"role": "user", "content": architect_prompt}],
                    max_tokens=1000
                )
                
                blueprint = architect_response.choices[0].message.content
                print(f"[Architect Plugin] Blueprint generated successfully.")
                
                # Step 2: Rewrite the payload going to the Engine
                system_instruction = (
                    "You are a Principal Engineer. Execute the following blueprint strictly."
                )
                
                # Overwrite the message array sent to Qwen3
                data["messages"] = [
                    {"role": "system", "content": system_instruction},
                    {"role": "user", "content": blueprint}
                ]
                
            except Exception as e:
                print(f"[Architect Plugin Error] Failed to ping Refiner: {str(e)}")
                # If the architect fails, fallback to the original user input
                pass 
            
        # Return the modified data dictionary to continue the proxy flow
        return data