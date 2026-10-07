import random

from state import ShoppingState

def check_for_data(state: ShoppingState) -> ShoppingState:
    random_number = random.randint(0, 100)
    if random_number > 95:
        return {"data": {"description": "This movie, called A Night With Pablo,  is widely regarded to be a boring slog, with minor moments of great animation being insufficient to make it a worthwhile watch"}}

    if random_number < 1:
        return {"data": {"description": "This movie, called Farting on Faces, is genuinely awful. Under no circumstances should you watch it."}}

    return {"data": {"description": "This movie, called Burning Flowers, is widely regarded as a cultural touchstone that is widely recommended, despite it's low budget showing in the cinematogrophy."}}