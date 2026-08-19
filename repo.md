medication-access-adherence/
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── backend-tests.yml
│       └── ml-tests.yml
│
├── client/                              # Flutter application
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── lib/
│   │   │
│   │   ├── core/
│   │   │   ├── config/
│   │   │   │   ├── app_config.dart
│   │   │   │   └── environment.dart
│   │   │   │
│   │   │   ├── constants/
│   │   │   ├── theme/
│   │   │   ├── routing/
│   │   │   └── utils/
│   │   │
│   │   ├── features/
│   │   │   │
│   │   │   ├── authentication/
│   │   │   │   ├── screens/
│   │   │   │   ├── widgets/
│   │   │   │   └── services/
│   │   │   │
│   │   │   ├── prescription/
│   │   │   │   ├── screens/
│   │   │   │   ├── widgets/
│   │   │   │   ├── models/
│   │   │   │   └── services/
│   │   │   │
│   │   │   ├── voice/
│   │   │   │   ├── screens/
│   │   │   │   ├── widgets/
│   │   │   │   ├── pipecat_service.dart
│   │   │   │   └── voice_state.dart
│   │   │   │
│   │   │   ├── medication/
│   │   │   │   ├── screens/
│   │   │   │   ├── widgets/
│   │   │   │   └── models/
│   │   │   │
│   │   │   ├── alternatives/
│   │   │   │   ├── screens/
│   │   │   │   ├── widgets/
│   │   │   │   └── models/
│   │   │   │
│   │   │   ├── recommendations/
│   │   │   │   ├── screens/
│   │   │   │   ├── widgets/
│   │   │   │   └── models/
│   │   │   │
│   │   │   └── approval/
│   │   │       ├── screens/
│   │   │       ├── widgets/
│   │   │       └── models/
│   │   │
│   │   ├── data/
│   │   │   ├── api/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   │
│   │   └── main.dart
│   │
│   ├── test/
│   ├── pubspec.yaml
│   └── README.md
│
│
├── server/                              # Python backend + agentic system
│   │
│   ├── app/
│   │   ├── main.py                      # FastAPI entrypoint
│   │   │
│   │   ├── api/
│   │   │   ├── routes/
│   │   │   │   ├── prescription.py
│   │   │   │   ├── formulary.py
│   │   │   │   ├── pa.py
│   │   │   │   ├── alternatives.py
│   │   │   │   ├── recommendation.py
│   │   │   │   ├── voice.py
│   │   │   │   └── health.py
│   │   │   │
│   │   │   └── dependencies.py
│   │   │
│   │   ├── agents/
│   │   │   │
│   │   │   ├── orchestrator/
│   │   │   │   ├── agent.py
│   │   │   │   ├── state.py
│   │   │   │   └── prompts.py
│   │   │   │
│   │   │   ├── voice/
│   │   │   │   ├── agent.py
│   │   │   │   └── intent.py
│   │   │   │
│   │   │   ├── prescription/
│   │   │   │   ├── agent.py
│   │   │   │   └── prompts.py
│   │   │   │
│   │   │   ├── patient_history/
│   │   │   │   └── agent.py
│   │   │   │
│   │   │   ├── formulary/
│   │   │   │   └── agent.py
│   │   │   │
│   │   │   ├── prior_authorization/
│   │   │   │   ├── agent.py
│   │   │   │   └── prompts.py
│   │   │   │
│   │   │   ├── alternative_discovery/
│   │   │   │   ├── agent.py
│   │   │   │   └── prompts.py
│   │   │   │
│   │   │   ├── clinical_safety/
│   │   │   │   └── agent.py
│   │   │   │
│   │   │   ├── recommendation/
│   │   │   │   └── agent.py
│   │   │   │
│   │   │   ├── verification/
│   │   │   │   └── agent.py
│   │   │   │
│   │   │   └── feedback/
│   │   │       └── agent.py
│   │   │
│   │   ├── graph/
│   │   │   ├── workflow.py               # LangGraph workflow
│   │   │   ├── nodes.py
│   │   │   ├── edges.py
│   │   │   └── state.py
│   │   │
│   │   ├── llm/
│   │   │   ├── client.py
│   │   │   ├── prompts/
│   │   │   └── structured_output.py
│   │   │
│   │   ├── rag/
│   │   │   ├── retriever.py
│   │   │   ├── embeddings.py
│   │   │   ├── pinecone_client.py
│   │   │   ├── ingestion.py
│   │   │   └── metadata.py
│   │   │
│   │   ├── tools/
│   │   │   ├── formulary_tools.py
│   │   │   ├── patient_tools.py
│   │   │   ├── drug_tools.py
│   │   │   ├── pa_tools.py
│   │   │   ├── pharmacy_tools.py
│   │   │   └── ml_tools.py
│   │   │
│   │   ├── services/
│   │   │   ├── prescription_service.py
│   │   │   ├── formulary_service.py
│   │   │   ├── pa_service.py
│   │   │   ├── alternative_service.py
│   │   │   ├── ranking_service.py
│   │   │   └── feedback_service.py
│   │   │
│   │   ├── ranking/
│   │   │   ├── scorer.py
│   │   │   ├── weights.py
│   │   │   └── rules.py
│   │   │
│   │   ├── schemas/
│   │   │   ├── prescription.py
│   │   │   ├── formulary.py
│   │   │   ├── pa.py
│   │   │   ├── alternative.py
│   │   │   ├── ml_prediction.py
│   │   │   ├── recommendation.py
│   │   │   └── agent_state.py
│   │   │
│   │   ├── db/
│   │   │   ├── database.py
│   │   │   ├── models/
│   │   │   │   ├── patient.py
│   │   │   │   ├── prescription.py
│   │   │   │   ├── drug.py
│   │   │   │   ├── formulary.py
│   │   │   │   ├── insurance.py
│   │   │   │   ├── claims.py
│   │   │   │   └── audit.py
│   │   │   └── repositories/
│   │   │
│   │   ├── voice/
│   │   │   ├── pipecat_pipeline.py
│   │   │   ├── stt.py
│   │   │   └── tts.py
│   │   │
│   │   ├── config/
│   │   │   └── settings.py
│   │   │
│   │   └── middleware/
│   │       ├── auth.py
│   │       ├── logging.py
│   │       └── error_handler.py
│   │
│   └── tests/
│       ├── agents/
│       ├── graph/
│       ├── rag/
│       ├── api/
│       └── services/
│
│
├── ml-model/                            # ML development + inference
│   │
│   ├── datasets/
│   │   ├── raw/
│   │   ├── processed/
│   │   ├── abandonment/
│   │   │   └── abandonment_dataset.csv
│   │   └── adherence/
│   │       └── adherence_dataset.csv
│   │
│   ├── notebooks/
│   │   ├── 01_eda.ipynb
│   │   ├── 02_abandonment_model.ipynb
│   │   ├── 03_adherence_model.ipynb
│   │   └── 04_model_evaluation.ipynb
│   │
│   ├── src/
│   │   ├── features/
│   │   │   ├── patient_features.py
│   │   │   ├── drug_features.py
│   │   │   ├── insurance_features.py
│   │   │   └── access_features.py
│   │   │
│   │   ├── abandonment/
│   │   │   ├── train.py
│   │   │   ├── predict.py
│   │   │   └── evaluate.py
│   │   │
│   │   ├── adherence/
│   │   │   ├── train.py
│   │   │   ├── predict.py
│   │   │   └── evaluate.py
│   │   │
│   │   ├── preprocessing/
│   │   │   ├── encoder.py
│   │   │   ├── scaler.py
│   │   │   └── pipeline.py
│   │   │
│   │   └── common/
│   │       ├── metrics.py
│   │       └── config.py
│   │
│   ├── models/
│   │   ├── abandonment/
│   │   │   ├── model.pkl
│   │   │   └── metadata.json
│   │   │
│   │   └── adherence/
│   │       ├── model.pkl
│   │       └── metadata.json
│   │
│   ├── tests/
│   ├── requirements.txt
│   └── README.md
│
│
├── etl/                                  # Data ingestion / preprocessing
│   │
│   ├── sources/
│   │   ├── cms/
│   │   ├── formulary/
│   │   ├── payer/
│   │   ├── drug/
│   │   └── claims/
│   │
│   ├── pipelines/
│   │   ├── formulary_pipeline.py
│   │   ├── drug_pipeline.py
│   │   ├── claims_pipeline.py
│   │   └── document_pipeline.py
│   │
│   ├── transformations/
│   │   ├── normalize_drug.py
│   │   ├── normalize_plan.py
│   │   └── clean_claims.py
│   │
│   ├── validators/
│   │   └── data_quality.py
│   │
│   └── README.md
│
│
├── rag-data/                             # RAG source documents
│   ├── payer-policies/
│   ├── prior-authorization/
│   ├── clinical-guidelines/
│   ├── drug-monographs/
│   └── formulary-documents/
│
│
├── handoff/                              # Existing handoff/integration area
│   ├── schemas/
│   ├── examples/
│   └── README.md
│
│
├── infra/                                # Deployment / AWS
│   ├── docker/
│   │   ├── backend.Dockerfile
│   │   ├── ml.Dockerfile
│   │   └── etl.Dockerfile
│   │
│   ├── aws/
│   │   ├── ec2/
│   │   ├── rds/
│   │   ├── s3/
│   │   ├── iam/
│   │   └── cloudwatch/
│   │
│   └── nginx/
│
│
├── scripts/
│   ├── seed_database.py
│   ├── ingest_rag.py
│   ├── train_models.py
│   ├── evaluate_models.py
│   └── run_etl.py
│
│
├── tests/
│   ├── integration/
│   └── end_to_end/
│
│
├── docs/
│   ├── architecture/
│   │   ├── system-architecture.md
│   │   ├── agent-flow.md
│   │   ├── ml-flow.md
│   │   └── rag-flow.md
│   │
│   ├── agents/
│   │   ├── voice-agent.md
│   │   ├── prescription-agent.md
│   │   ├── formulary-agent.md
│   │   ├── pa-agent.md
│   │   ├── alternative-agent.md
│   │   ├── safety-agent.md
│   │   ├── recommendation-agent.md
│   │   └── verification-agent.md
│   │
│   └── api/
│       └── agent-json-contracts.md
│
│
├── .env.example
├── .gitignore
├── docker-compose.yml
├── pyproject.toml
├── uv.lock
├── main.py
├── README.md
└── LICENSE