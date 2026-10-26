# noise-to-signal

A personal news aggregator: subscribe to RSS feeds, pre-filter a daily brief against your taste, give relevance feedback, and answer short follow-up questions. The **web UI** is a Django app; the **AI/LangGraph core** lives under `runner/` and is developed separately.

## Repository layout

| Path | Role |
|------|------|
| [`web/`](web/) | Django + UV frontend MVP (placeholder ranking) |
| [`runner/`](runner/) | Hand-written LangGraph / Bedrock core — keep separate |
| [`infrastructure/`](infrastructure/) | Lambda + Function URL + ECR; DBs on shared tck-labs RDS |

## Architecture overview (AI core)

The recommendation pipeline is a **LangGraph** state machine with **LangChain** LLM calls on **Amazon Bedrock**. Runs evaluate candidates against preferences, pause for human review, then fold feedback back into taste. Observability uses LangGraph event streaming. Daily candidate input is designed as an event-driven batch into a per-user inbox.

```
Feeds / events ──► Inbox batch
                      │
                      ▼
              Fetch preferences
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
               Done     Human review / follow-ups
                              │
                              ▼
                    Update preferences
```

## Web MVP

Clickable product shell with **placeholder AI**:

- Google sign-in (django-allauth; no end-user passwords)
- Curated feed catalog, recommendations, custom RSS URL
- Daily brief with relevance feedback (relevant / not / skip)
- Taste follow-up questions

See [`web/README.md`](web/README.md) for local run and Google OAuth.

```bash
cd web
cp .env.example .env   # add GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET
just sync
just setup
just run
```

## Hosting (AWS)

- **Compute:** Lambda + CloudFront (scale to zero) — see [`infrastructure/README.md`](infrastructure/README.md)
- **Database:** dedicated Postgres DBs `noise_to_signal_dev` / `noise_to_signal_prod` on the shared [tck-labs-base](../tck-labs-base) RDS host (not Render)
