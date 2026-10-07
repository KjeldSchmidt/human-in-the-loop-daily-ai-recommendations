from pathlib import Path

from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

from langgraph.graph import StateGraph, START, END

from data import check_for_data
from evaluate_user_preference import evaluate_data
from human_review import human_review
from user_preferences import update_preferences, fetch_preferences
from state import ShoppingState

graph = StateGraph(ShoppingState)
graph.add_node("check_for_data", check_for_data)
graph.add_node("fetch_preferences", fetch_preferences)
graph.add_node("evaluate_user_preference", evaluate_data)
graph.add_node("human_review", human_review)
graph.add_node("update_preferences", update_preferences)

graph.add_edge(START, "check_for_data")
graph.add_edge("check_for_data", "fetch_preferences")
graph.add_edge("fetch_preferences", "evaluate_user_preference")

graph.add_conditional_edges(
    "evaluate_user_preference",
    lambda x: "human_review" if x["evaluation"].show_to_user else "done",
    { "human_review": "human_review", "done": END }
)

graph.add_edge("human_review", "update_preferences")
graph.add_edge("update_preferences", END)

app = graph.compile()
result = app.invoke({"user_id": "kjeld"}) # todo: dynamic user id
print(result)
