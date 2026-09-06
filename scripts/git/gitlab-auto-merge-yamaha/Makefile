SCRIPT := ./merge-sync.sh
IMP_CONFIG := ./config/yamaha_imp.conf
PHASE_2_CONFIG := ./config/yamaha_phase_2.conf
PORTAL_CONFIG := ./config/yamaha_portal.conf


.PHONY: help pull-imp pull-imp-dry-run test pull-phase-2 pull-phase-2-dry-run pull-portal pull-portal-dry-run

help:
	@printf '%s\n' 'Available commands:'
	@printf '%s\n' '  make pull-imp          Synchronize Yamaha IMP branches.'
	@printf '%s\n' '  make pull-imp-dry-run  Preview the Yamaha IMP synchronization.'
	@printf '%s\n' '  make test              Run offline workflow tests.'

pull-imp:
	@$(SCRIPT) --config $(IMP_CONFIG)

pull-imp-dry-run:
	@$(SCRIPT) --config $(IMP_CONFIG) --dry-run --verbose

pull-phase-2:
	@$(SCRIPT) --config $(PHASE_2_CONFIG)

pull-phase-2-dry-run:
	@$(SCRIPT) --config $(PHASE_2_CONFIG) --dry-run --verbose

pull-portal:
	@$(SCRIPT) --config $(PORTAL_CONFIG)

pull-portal-dry-run:
	@$(SCRIPT) --config $(PORTAL_CONFIG) --dry-run --verbose



test:
	@bash ./tests/test-config.sh
	@./tests/test-merge-request.sh
