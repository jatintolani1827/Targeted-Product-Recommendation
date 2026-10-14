# Targeted Product Recommendation

Course project for a targeted product recommendation system. The repository contains a Flask backend, PostgreSQL schema and seed scripts, and React frontend source.

## Project layout

- `db/backend/` — Flask API, database access, queue worker, and scheduler
- `db/database/` — SQL schema, views, procedures, indexes, roles, and seed data
- `db/frontend/src/` — React application source
- `db/scripts/` — database bootstrap scripts
- `db/tests/` — backend tests and flash sale simulation

## Backend setup

1. Create and activate a Python virtual environment.
2. Install dependencies with `pip install -r db/backend/requirements.txt`.
3. Create a PostgreSQL database named `recommendation_engine` and configure `DATABASE_URL` and `ADMIN_DATABASE_URL` in a local `.env` file if your credentials differ from the local development defaults.
4. Run the SQL files in `db/database/` in numeric order, or use the bootstrap script in `db/scripts/`.
5. Start the API with `python -m flask --app db.backend.app run`.

The database role passwords in the SQL scripts and fallback connection URLs are development examples. Change them before using this project outside a local development environment.

## Frontend

The React source is in `db/frontend/src/`. The original project directory does not include a frontend package manifest, so the frontend dependencies and start command are not recorded here.
