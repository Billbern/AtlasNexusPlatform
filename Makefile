.DEFAULT_GOAL := help

PROJECT := Atlas Nexus

ATLAS_NEXUS_NETWORK := atlas-nexus-net

VLLM_ENV := configs/vllm.env
VLLM_COMPOSE := compose/vllm/compose.yaml

LITELLM_ENV := configs/litellm.env
LITELLM_COMPOSE := compose/litellm/compose.yaml


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
access-down \
litellm-up \
litellm-down \
litellm-restart \
litellm-logs \
litellm-health


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
	@echo "LiteLLM"
	@echo "------------------------------------------------------"
	@echo "  make litellm-up       Start LiteLLM"
	@echo "  make litellm-down     Stop LiteLLM"
	@echo "  make litellm-restart  Restart LiteLLM"
	@echo "  make litellm-health   Check LiteLLM health"
	@echo "  make litellm-logs     Tail LiteLLM logs"
	@echo ""
	@echo "Access"
	@echo "------------------------------------------------------"
	@echo "  sudo make access-install  Install cloudflared"
	@echo "  make access-up            Start Cloudflare tunnel"
	@echo "  make access-down          Stop Cloudflare tunnel"
	@echo ""
	@echo "Bootstrap"
	@echo "------------------------------------------------------"
	@echo "  make bootstrap        Run full provisioning pipeline"
	@echo ""



host-install:
	sudo ./scripts/host-install.sh

host-check:
	./scripts/host-check.sh

host-update:
	sudo ./scripts/host-update.sh


storage-init:
	./scripts/storage-init.sh

network-init:
	docker network create --driver bridge $(ATLAS_NEXUS_NETWORK)

network-check:
	docker network inspect $(ATLAS_NEXUS_NETWORK) >/dev/null 2>&1 || network-init

network-clean:
	docker network rm $(ATLAS_NEXUS_NETWORK)

vllm-up:
	docker compose --env-file $(VLLM_ENV) -f $(VLLM_COMPOSE) up -d

vllm-down:
	docker compose --env-file $(VLLM_ENV) -f $(VLLM_COMPOSE) down

vllm-restart:
	docker compose --env-file $(VLLM_ENV) -f $(VLLM_COMPOSE) restart

vllm-logs:
	docker compose --env-file $(VLLM_ENV) -f $(VLLM_COMPOSE) logs -f

vllm-ps:
	docker compose --env-file $(VLLM_ENV) -f $(VLLM_COMPOSE) ps

vllm-pull:
	docker compose --env-file $(VLLM_ENV) -f $(VLLM_COMPOSE) pull

vllm-health:
	./scripts/vllm-health.sh

litellm-up:
	docker compose --env-file $(LITELLM_ENV) -f $(LITELLM_COMPOSE) up -d

litellm-down:
	docker compose --env-file $(LITELLM_ENV) -f $(LITELLM_COMPOSE) down

litellm-restart:
	docker compose --env-file $(LITELLM_ENV) -f $(LITELLM_COMPOSE) restart

litellm-logs:
	docker compose --env-file $(LITELLM_ENV) -f $(LITELLM_COMPOSE) logs -f

litellm-health:
	./scripts/litellm-health.sh


bootstrap:
	./scripts/bootstrap.sh

access-install:
	sudo ./scripts/access-install.sh

access-up:
	./scripts/access-up.sh

access-down:
	./scripts/access-down.sh
