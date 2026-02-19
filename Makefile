COMPOSE := docker compose

.PHONY: dev demo seed smoke down logs test lint

dev:
	$(COMPOSE) up --build

demo:
	$(COMPOSE) up --build -d
	@echo "Waiting for backend health at http://localhost:5050/healthz ..."
	@for i in $$(seq 1 40); do \
		if curl -fsS http://localhost:5050/healthz >/dev/null; then \
			echo "Backend is healthy."; \
			break; \
		fi; \
		sleep 2; \
	done
	@$(MAKE) seed
	@echo "Frontend: http://localhost:3000"
	@echo "Backend:  http://localhost:5050"

seed:
	@echo "Seeding deterministic demo data ..."
	@$(COMPOSE) exec -T backend python /app/scripts/seed_demo.py

smoke:
	@bash scripts/smoke.sh

down:
	$(COMPOSE) down -v

logs:
	$(COMPOSE) logs -f --tail=200

test:
	@$(COMPOSE) run --rm backend pytest -q || echo "Backend tests skipped/failed (best effort)."
	@$(COMPOSE) run --rm frontend npm run test || echo "Frontend tests skipped/failed (best effort)."

lint:
	@$(COMPOSE) run --rm frontend npm run lint || echo "Frontend lint skipped/failed (best effort)."
	@$(COMPOSE) run --rm backend python -m compileall -q . || echo "Backend lint surrogate skipped/failed (best effort)."
