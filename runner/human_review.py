from llm_model import get_model
from state import ShoppingState
from langgraph.types import interrupt

def human_review(state: ShoppingState) -> dict:
    evaluation = state["current_item"]

    human_readable_suggestion = f"""
    Title: {evaluation.title}
    Reason: {evaluation.reason}

    Pros: ✅
    { "\n-".join(evaluation.pro_arguments) }

    Cons: 🟨
    { "\n-".join(evaluation.con_arguments) }

    So what do you think?
    """

    feedback = interrupt(human_readable_suggestion)

    return {"human_feedback": feedback}