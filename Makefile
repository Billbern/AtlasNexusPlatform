.DEFAULT_GOAL := help

PROJECT := Atlas Nexus


VLLM_COMPOSE := compose/vllm/compose.yaml


.PHONY: \
help \
bootstrap \
host-install \
host-check \
host-update \
storage-init \
vllm-up \
vllm-down \
vllm-restart \
vllm-logs \
vllm-ps \
vllm-pull \
vllm-health \
access-install \
access-up \
access-down


help:
	@echo ""
	@echo "======================================================"
	@echo "                $(PROJECT)"
	@echo "======================================================"
	@echo ""
	@echo "Host"
	@echo "------------------------------------------------------"
	@echo "  make host-install     Install host dependencies"
	@echo "  make host-check       Verify host readiness"
	@echo "  make host-update      Update host packages"
	@echo ""
	@echo "Storage"
	@echo "------------------------------------------------------"
	@echo "  make storage-init     Create storage directories"
	@echo ""
	@echo "vLLM"
	@echo "------------------------------------------------------"
	@echo "  make vllm-up          Start vLLM"
	@echo "  make vllm-down        Stop vLLM"
	@echo "  make vllm-restart     Restart vLLM"
	@echo "  make vllm-logs        Follow logs"
	@echo "  make vllm-ps          Show container status"
	@echo "  make vllm-pull        Pull latest image"
	@echo "  make vllm-health      Check vLLM health status"
	@echo ""
	@echo "Bootstrap"
	@echo "------------------------------------------------------"
	@echo "  make bootstrap        Run full provisioning pipeline"
	@echo ""
	@echo "Access"
	@echo "------------------------------------------------------"
	@echo "  sudo make access-install  Install cloudflared"
	@echo "  make access-up            Start Cloudflare tunnel"
	@echo "  make access-down          Stop Cloudflare tunnel"
	@echo ""



host-install:
	sudo ./scripts/host-install.sh

host-check:
	./scripts/host-check.sh

host-update:
	sudo ./scripts/host-update.sh


storage-init:
	./scripts/storage-init.sh


vllm-up:
	docker compose -f $(VLLM_COMPOSE) up -d

vllm-down:
	docker compose -f $(VLLM_COMPOSE) down

vllm-restart:
	docker compose -f $(VLLM_COMPOSE) restart

vllm-logs:
	docker compose -f $(VLLM_COMPOSE) logs -f

vllm-ps:
	docker compose -f $(VLLM_COMPOSE) ps

vllm-pull:
	docker compose -f $(VLLM_COMPOSE) pull

vllm-health:
	./scripts/vllm-health.sh


bootstrap:
	./scripts/bootstrap.sh

access-install:
	sudo ./scripts/access-install.sh

access-up:
	./scripts/access-up.sh

access-down:
	./scripts/access-down.sh
