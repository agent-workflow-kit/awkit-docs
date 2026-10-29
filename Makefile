# Local checks for awkit-docs. CI runs the same markdown lint through awkit-ci docs-ci.yml.

PYMARKDOWN := uvx --from pymarkdownlnt==0.9.41 pymarkdown

.PHONY: verify mdlint

verify: mdlint

mdlint:
	$(PYMARKDOWN) --config .pymarkdown.json scan -r --respect-gitignore .
