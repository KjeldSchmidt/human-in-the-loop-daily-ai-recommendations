from llm_model import get_model
from state import ShoppingState

def human_review(state: ShoppingState) -> dict:
    evaluation = state['evaluation']

    print(evaluation.title)
    print()
    print(evaluation.reason)
    print()
    
    print("Pros: ✅")
    for argument in evaluation.pro_arguments:
        print(argument)

    print()
    print("Cons: 🟨")
    for argument in evaluation.con_arguments:
        print(argument)

    print()
    print("So what do you think?")
    feedback = input()
    return {"human_feedback": feedback}