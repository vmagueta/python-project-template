.ONESHELL:
ENV_PREFIX=$(shell python -c "if __import__('pathlib').Path('.venv/bin/pip').exists(): print('.venv/bin/')")
USING_POETRY=$(shell grep "tool.poetry" pyproject.toml && echo "yes")

.PHONY: help
help:             ## Show the help.
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@fgrep "##" Makefile | fgrep -v fgrep


.PHONY: show
show:             ## Show the current environment.
	@echo "Current environment:"
	@echo "Running using $(ENV_PREFIX)"
	@$(ENV_PREFIX)python -V
	@$(ENV_PREFIX)python -m site

.PHONY: install
install:          ## Install the project in dev mode.
	$(ENV_PREFIX)uv sync --all-extras --dev

.PHONY: fmt
fmt:              ## Format code using black & isort.
	$(ENV_PREFIX)uv run ruff format project_name/ tests/

.PHONY: lint
lint:             ## Run pep8, black, mypy linters.
#most are due to flashattention...
	$(ENV_PREFIX)uv run ruff check --fix project_name/ tests/

.PHONY: test
test: lint        ## Run tests and generate coverage report.
	$(ENV_PREFIX)uv run pytest -v --cov-config .coveragerc --cov=project_name -l --tb=short --maxfail=1 tests/
	$(ENV_PREFIX)uv run coverage xml
	$(ENV_PREFIX)uv run coverage html

.PHONY: clean
clean:            ## Clean unused files.
	@find ./ -name '*.pyc' -exec rm -f {} \;
	@find ./ -name '__pycache__' -exec rm -rf {} \;
	@find ./ -name 'Thumbs.db' -exec rm -f {} \;
	@find ./ -name '*~' -exec rm -f {} \;
	@rm -rf .cache
	@rm -rf .pytest_cache
	@rm -rf .mypy_cache
	@rm -rf build
	@rm -rf dist
	@rm -rf *.egg-info
	@rm -rf htmlcov
	@rm -rf .tox/
	@rm -rf docs/_build

.PHONY: virtualenv
virtualenv:       ## Create a virtual environment.
	@echo "creating virtualenv ..."
	@rm -rf .venv
	@uv venv
	@source .venv/bin/activate
	@make install
	@echo "!!! Please run 'source .venv/bin/activate' to enable the environment !!!"

.PHONY: release
release:          ## Create a new tag for release.
	@echo "WARNING: This operation will create s version tag and push to github"
	@read -p "Version? (provide the next x.y.z semver) : " TAG
	@echo "$${TAG}" > project_name/VERSION
	@sed -i 's/^version = .*/version = "'$${TAG}'"/' pyproject.toml
	@sed -i 's/__version__ = .*/__version__ = "'$${TAG}'"/' project_name/__init__.py
	@$(ENV_PREFIX)gitchangelog > HISTORY.md
	@git add project_name/VERSION HISTORY.md pyproject.toml
	@git commit -m "release: version $${TAG} 🚀"
	@echo "creating git tag : $${TAG}"
	@git tag $${TAG}
	@git push -u origin HEAD --tags
	@echo "Github Actions will detect the new tag and release the new version."
	@mkdocs gh-deploy
	@echo "Documentation deployed to https://author_name.github.io/project_name/"

.PHONY: docs
docs:             ## Build the documentation.
	@echo "building documentation ..."
	@$(ENV_PREFIX)mkdocs build
	URL="site/index.html"; xdg-open $$URL || sensible-browser $$URL || x-www-browser $$URL || gnome-open $$URL || open $$URL

.PHONY: init
init:             ## Initialize the project based on an application template.
	@./.github/init.sh
