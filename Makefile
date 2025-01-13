##
# Project Title
#
# @file
# @version 0.1

COVERAGE_DIR := ./coverage
COVERAGE_JSON := $(COVERAGE_DIR)/kcov-merged/coverage.json

CHROOT_CMD = FAKECHROOT_EXCLUDE_PATH=/tmp:/dev:/bin:/usr/bin:/usr/share/shunit2:$(CURDIR) fakechroot chroot test/chroot ./cd-exec $(CURDIR)
KCOV_CMD = kcov --bash-parse-files-in-dir=generators --exclude-path=/usr/bin/shunit2,$(CURDIR)/test $(COVERAGE_DIR)

all:

test:
	$(CHROOT_CMD) $(CURDIR)/test/20-local-repo-upgrade.sh
	$(CHROOT_CMD) $(CURDIR)/test/60local.sh

coverage:
	$(CHROOT_CMD) $(KCOV_CMD) $(CURDIR)/test/20-local-repo-upgrade.sh
	$(CHROOT_CMD) $(KCOV_CMD) $(CURDIR)/test/60local.sh
	if [ -f "$(COVERAGE_JSON)" ] ; then jq '"Total Code Coverage: \(.percent_covered) %"' $(COVERAGE_JSON) ; fi

.PHONY: test coverage

# end
