# Shortcuts for django-helpdesk testing and development using make
#
# For standard installation of django-helpdesk as a library,
# see INSTALL and the documentation in docs/.
#
# For details about how to develop django-helpdesk,
# see CONTRIBUTING.rst.
UV = uv
PIP = pip3
TOX = tox


#: help - Display callable targets.
.PHONY: help
help:
	@echo "django-helpdesk make shortcuts"
	@echo "Here are available targets:"
	@egrep -o "^#: (.+)" [Mm]akefile  | sed 's/#: /* /'


#: develop - Install minimal development utilities for Python3.
.PHONY: develop
develop:
	$(UV) venv
	$(UV) sync --all-extras --dev --group test
	$(UV) tool install pre-commit --with pre-commit-uv --force-reinstall
	pre-commit install

#: sync - Synchronize the environment with the project configuration
.PHONY: sync
sync:
	$(UV) sync --all-extras --dev --group test


#: clean - Basic cleanup, mostly temporary files.
.PHONY: clean
clean:
	find . -name "*.pyc" -delete
	find . -name '*.pyo' -delete
	find . -name "__pycache__" -delete


#: distclean - Remove local builds, such as *.egg-info.
.PHONY: distclean
distclean: clean
	rm -rf *.egg
	rm -rf *.egg-info
	rm -rf helpdesk/attachments
	# remove the django-created database
	rm -f demodesk/*.sqlite3
	find $(STATIC_DIR) -mindepth 1 -maxdepth 1 ! -name 'flot' ! -name 'README.md' ! -name 'flot-tooltip' ! -name 'morrisjs' ! -name 'timeline3' -exec rm -rf {} +


#: maintainer-clean - Remove almost everything that can be re-generated.
.PHONY: maintainer-clean
maintainer-clean: distclean
	rm -rf build/
	rm -rf dist/
	rm -rf .tox/


#: test - Run test suites.
.PHONY: test
test:
	$(UV) run quicktest.py


#: format - Run the PEP8 formatter.
.PHONY: format
format:
	uv tool run ruff check --fix # Fix linting errors
	uv tool run ruff format # fix formatting errors


#: checkformat - checks formatting against configured format specifications for the project.
.PHONY: checkformat
checkformat:
	uv tool run ruff check # linting check
	uv tool run ruff format --check # format check


#: documentation - Build documentation (Sphinx, README, ...).
.PHONY: documentation
documentation: sphinx readme


#: sphinx - Build Sphinx documentation (docs).
.PHONY: sphinx
sphinx:
	$(TOX) -e sphinx


#: readme - Build standalone documentation files (README, CONTRIBUTING...).
.PHONY: readme
readme:
	$(TOX) -e readme


#: demo - Setup demo project using Python3.
# Requires using the PYTHONPATH prefix because the project directory is not set in the path
.PHONY: demo
demo:
	yarn install
	make static-vendor
	uv  sync  --all-extras --dev --group test --group teams
	uv run manage.py migrate --noinput
	# Install fixtures
	uv run manage.py loaddata emailtemplate.json
	# The password for the "admin" user is 'Pa33w0rd' for the demo project.
	uv run manage.py loaddata demo.json


#: rundemo - Run demo server using Python3.
.PHONY: rundemo
rundemo: demo
	uv run manage.py runserver 8080

#: migrations - Create Django migrations for this project.
.PHONY: migrations
migrations: demo
	uv run manage.py makemigrations


#: release - Tag and push to PyPI.
.PHONY: release
release:
	$(TOX) -e release

# Yarn
STATIC_DIR := src/helpdesk/static/helpdesk/vendor


# Use jq to read the top-level 'dependencies' keys from package.json
# The tr command converts newlines to spaces for Make.
VENDORS := $(shell jq -r '.dependencies | keys[]' package.json 2>/dev/null | tr '\n' ' ')

.PHONY: static-vendor setup-vendor-dirs
static-vendor: setup-vendor-dirs $(addprefix $(STATIC_DIR)/,$(VENDORS))
	@echo "Static vendor copy complete for: $(VENDORS)"

# Target to create the base vendor directory
setup-vendor-dirs:
	@mkdir -p $(STATIC_DIR)

# A Pattern Rule for copying each vendor
# This rule applies to every vendor listed in the VENDORS variable
$(STATIC_DIR)/%:
	@echo "Processing vendor: $*"; \
	\
	# Define source and destination paths \
	VENDOR_NAME=$*; \
	DEST_DIR=$(STATIC_DIR)/$$VENDOR_NAME; \
	\
	# Use logic to find the appropriate files (dist, umd, or root) \
	mkdir -p $$DEST_DIR; \
	if [ -d "node_modules/$$VENDOR_NAME/dist" ]; then \
		echo "  -> Copying 'dist' folder contents..."; \
		cp -r node_modules/$$VENDOR_NAME/dist/* $$DEST_DIR/; \
	elif [ -d "node_modules/$$VENDOR_NAME/umd" ]; then \
		echo "  -> Copying 'umd' folder contents..."; \
		cp -r node_modules/$$VENDOR_NAME/umd/* $$DEST_DIR/; \
	elif [ -f "node_modules/$$VENDOR_NAME/jquery.min.js" ]; then \
		# Specific case for libraries like jquery that put files at root \
		echo "  -> Copying root-level files (jquery.min.js only)..."; \
		cp node_modules/$$VENDOR_NAME/jquery.min.js $$DEST_DIR/; \
	else \
		# Fallback to copy the entire top-level module (use with caution) \
		echo "  -> WARNING: No standard assets found. Copying entire module..."; \
		cp -r node_modules/$$VENDOR_NAME/* $$DEST_DIR/; \
	fi

