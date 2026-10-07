from typing import TypedDict
from pydantic import BaseModel

class EvaluationResult(BaseModel):
    show_to_user: bool = Field(description="Decides whether human-in-the-loop feedback is requested. Should be True if the user is reasonably likely to like the movie, and False if they are unlikely to like it.")
    title: str = Field(description="The title of the movie.")
    reason: str = Field(description="A short explanation for the confidence level and final show_to_user decision.")
    pro_arguments: list[str] = Field(description="A list of arguments in favor of the show_to_user decision.")
    con_arguments: list[str] = Field(description="A list of arguments against the show_to_user decision.")
    enjoyment_prediction: float = Field(description="A confidence score between 0 and 1 indicating the confidence in the show_to_user decision. 0 means absolute certainty that the user will not like the movie, and 1 means absolute certainty that the user will like the movie.")

class ShoppingState(TypedDict):
    data: dict
    evaluation: EvaluationResult
    human_feedback: str
    classification: str
    user_id: str
    relevant_preferences: list[str]