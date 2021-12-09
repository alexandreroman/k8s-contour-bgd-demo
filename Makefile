CARVEL_BINARIES := ytt kbld kapp

all: deploy

check-carvel:
	$(foreach exec,$(CARVEL_BINARIES),\
		$(if $(shell which $(exec)),,$(error "'$(exec)' not found. Carvel toolset is required. See instructions at https://carvel.dev/#install")))

deploy: check-carvel
	ytt -f config -f config-env | kbld -f- > _tmp.yml
	kapp deploy -a k8s-contour-bgd -f _tmp.yml -c -y

undeploy:
	kapp delete -a k8s-contour-bgd -y
