# LangChain Bike Shopper

A recommendation pipeline that scores incoming items against a user’s preferences, surfaces the strongest matches for human review, and folds that feedback back into the preference model.

## Architecture overview

The system is built as a **LangGraph** state machine, with **LangChain** handling LLM calls. Each run moves through a fixed sequence of steps: ingest data, load preferences, evaluate and rank candidates, pause for human review when warranted, then update preferences and continue with the next candidate.

```
Daily data ──► Check / load data
                      │
                      ▼
              Fetch user preferences
                      │
                      ▼
              Evaluate & rank (LLM)
                      │
                      ▼
              Present next best item
                 │            │
            (below bar)   (worth showing)
                 │            │
                 ▼            ▼
               Done     Human review
                              │
                              ▼
                    Update preferences
                              │
                              └──► next item
```

### Orchestration (LangGraph)

LangGraph owns the control flow: nodes for data loading, preference lookup, evaluation, item selection, human-in-the-loop review, and preference updates. Conditional edges decide whether to keep presenting items or end the run. Durable checkpoints keep runs resumable across interrupts (for example while waiting on human feedback).

### Models (LangChain + AWS Bedrock)

All generative work goes through LangChain chat models backed by **Amazon Bedrock** (Converse API). Structured outputs drive evaluation results—relevance, ranking scores, and short rationales—so downstream steps can rank and filter without ad-hoc parsing.

### Preferences & learning loop

User preferences are stored and retrieved via a memory service keyed by user. Before evaluation, the graph pulls preferences relevant to the current batch. After human review, feedback is written back so later runs better reflect taste.

### Human-in-the-loop

When an item clears the enjoyment threshold, the graph interrupts and presents a concise recommendation (rationale, pros, cons). The user’s response resumes the graph and feeds preference updates.

### Observability & evaluation (LangGraph)

Runs are executed with LangGraph’s event streaming so each node transition and interrupt is observable end-to-end. That same event surface supports tracing, inspection of intermediate state, and evaluation of how recommendations and human feedback evolve across a run—without treating the pipeline as a black box.

### Event-driven daily data input

New candidate items arrive on a **daily event-driven schedule**: an upstream process emits a batch of listings (or equivalent catalog updates) each day. Those events trigger a graph run for the target user(s), so evaluation and review stay aligned with fresh inventory rather than a static dataset.
