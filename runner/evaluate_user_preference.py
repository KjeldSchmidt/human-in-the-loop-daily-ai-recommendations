import json

from state import ShoppingState, EvaluationResult
from llm_model import get_model

def evaluate_data(state: ShoppingState) -> ShoppingState:
    strcutured_model = get_model().with_structured_output(EvaluationResult)
    evaluation = strcutured_model.invoke(
        f"""
        Instruction: Evaluate whether the movie described here should be recommended to the end user. Set show_to_user to false if the movie is probably bad.
        
        This is the data to evaluate: {json.dumps(state['data'])}

        These are the users relevant preferences: {json.dumps(state['relevant_preferences'])}
        """
    )


    print(f"Data was: {state['data']}")
    print(f"LLM call response says: {evaluation}")
    return {"evaluation": evaluation}