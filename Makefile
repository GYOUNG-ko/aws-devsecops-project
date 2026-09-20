.PHONY: check-contracts validate-infra test-devops verify-app render-gitops

check-contracts:
	python3 devops/scripts/check_contracts.py
	python3 devops/scripts/install_ci_tools.py --check

validate-infra: check-contracts test-devops
	python3 devops/scripts/validate_iac.py

test-devops:
	python3 -m unittest discover -s devops/tests -v

verify-app:
	mvn -f backend/pom.xml --batch-mode --no-transfer-progress verify

render-gitops:
	kubectl kustomize kubernetes/app
