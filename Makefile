# Deevnet Tenant Fabric
#
# Credentials are never stored, here or anywhere: every target below fetches the
# hypervisor's Proxmox token per run with the image factory's scripts/pve-creds
# (OpenBao by default, the inventory vault as fallback) and evals it into its
# own environment. Nothing is written to disk (Build-Time Secrets runbook).

SHELL := /usr/bin/bash
.SHELLFLAGS := -euo pipefail -c
.ONESHELL:
.DEFAULT_GOAL := help

IMAGE_FACTORY ?= $(CURDIR)/../deevnet-image-factory
# The hypervisor, by inventory name, which since ADR-0008 is also its Proxmox
# node name. It used to be the slot name "pve2", read from a rendered file that
# was never refreshed - the stale node name pve-node-rename.md warns about.
PVE_HOST      ?= dv02hyp002p02
PVE_CREDS     := $(IMAGE_FACTORY)/scripts/pve-creds
CREDS         := eval "$$($(PVE_CREDS) $(PVE_HOST) $(PVE_HOST))"

FABRIC  ?= fabric/mobile-dv02hyp002p02

# Extra args for apply/destroy. Terraform prompts for approval by default and
# that is the right default for a human at a terminal; pass AUTO=1 for a
# non-interactive run (no TTY, CI, or an agent driving it).
TF_APPROVE := $(if $(AUTO),-auto-approve,)

.PHONY: help fabric-init fabric-plan fabric-apply fmt validate

help:
	@echo "Deevnet tenant fabric - the hypervisor's readiness for tenants."
	@echo
	@echo "  fabric-init    terraform init"
	@echo "  fabric-plan    terraform plan"
	@echo "  fabric-apply   terraform apply       (AUTO=1 to skip approval)"
	@echo "  validate       fmt check + validate"
	@echo
	@echo "Tenants are not built here: the Deevnet API builds them (ADR-0015)."

fabric-init:
	$(CREDS)
	terraform -chdir=$(FABRIC) init

fabric-plan:
	$(CREDS)
	terraform -chdir=$(FABRIC) plan

fabric-apply:
	$(CREDS)
	terraform -chdir=$(FABRIC) apply $(TF_APPROVE)

fmt:
	terraform fmt -recursive

validate:
	terraform fmt -check -recursive
	terraform -chdir=$(FABRIC) init -backend=false -input=false >/dev/null
	terraform -chdir=$(FABRIC) validate
