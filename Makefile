APPNAME = stokenserver
DEPS =
VIRTUALENV = virtualenv
PYTHON = $(CURDIR)/bin/python
NOSE = bin/nosetests -s --with-xunit
FLAKE8 = bin/flake8
COVEROPTS = --cover-html --cover-html-dir=html --with-coverage --cover-package=appsync
TESTS = stokenserver
PKGS = stokenserver
COVERAGE = bin/coverage
PYLINT = bin/pylint
SERVER = dev-auth.services.mozilla.com
SCHEME = https
PYPI = http://pypi.python.org/simple
PYPI2 = http://pypi.python.org/packages
PYPI2RPM = bin/pypi2rpm.py --index=$(PYPI)
PYPIOPTIONS = -i $(PYPI)
CHANNEL = dev
RPM_CHANNEL = dev
PIP_CACHE = /tmp/pip-cache.${USER}
BUILD_TMP = /tmp/stoken-build.${USER}
INSTALL = bin/pip install --download-cache=$(PIP_CACHE)
BUILDAPP = bin/buildapp --download-cache=$(PIP_CACHE)
BUILDRPMS = bin/buildrpms --download-cache=$(PIP_CACHE)
INSTALLOPTIONS = -U -i $(PYPI)
TIMEOUT = 300
DURATION = 30
CYCLES = 5:10:20
HOST = http://localhost:5000
BIN = ../bin
RPMDIR= $(CURDIR)/rpms

ifdef PYPIEXTRAS
	PYPIOPTIONS += -e $(PYPIEXTRAS)
	INSTALLOPTIONS += -f $(PYPIEXTRAS)
endif

ifdef PYPISTRICT
	PYPIOPTIONS += -s
	ifdef PYPIEXTRAS
		HOST = `python -c "import urlparse; print urlparse.urlparse('$(PYPI)')[1] + ',' + urlparse.urlparse('$(PYPIEXTRAS)')[1]"`

	else
		HOST = `python -c "import urlparse; print urlparse.urlparse('$(PYPI)')[1]"`
	endif

endif

INSTALL += $(INSTALLOPTIONS)

.PHONY: all build build_rpms test update

all:	build

build:
	$(VIRTUALENV) --no-site-packages --distribute .
	$(INSTALL) Distribute
	$(INSTALL) MoPyTools
	$(INSTALL) nose
	$(INSTALL) WebTest
	$(INSTALL) wsgi_intercept
	$(INSTALL) https://github.com/mozilla-services/wimms/zipball/master
	$(BUILDAPP) -t $(TIMEOUT) -c $(CHANNEL) $(PYPIOPTIONS) $(DEPS)

update:
	$(BUILDAPP) -t $(TIMEOUT) -c $(CHANNEL) $(PYPIOPTIONS) $(DEPS)

test:
	$(NOSE) $(TESTS)

build_rpms:
	mkdir -p ${BUILD_TMP}
	rm -f ${BUILD_TMP}/master.zip
	wget -O ${BUILD_TMP}/master.zip https://github.com/Pylons/pyramid/zipball/master --no-check-certificate
	rm -rf rpms
	mkdir rpms
	bin/pypi2rpm.py ${BUILD_TMP}/master.zip --dist-dir=$(RPMDIR)
	$(BUILDRPMS) -t $(TIMEOUT) -c $(RPM_CHANNEL) $(DEPS)

mock: build build_rpms
	mock init
	mock --install python26 python26-setuptools
	cd rpms; wget http://mrepo.mozilla.org/mrepo/5-x86_64/RPMS.mozilla-services/gunicorn-0.11.2-1moz.x86_64.rpm
	cd rpms; wget http://mrepo.mozilla.org/mrepo/5-x86_64/RPMS.mozilla/nginx-0.7.65-4.x86_64.rpm
	mock --install rpms/*
	mock --chroot "python2.6 -m stokenserver.run"

clean:
	rm -rf bin lib include local docs/build
