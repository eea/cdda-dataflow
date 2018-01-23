#!/bin/sh
../../../dev/basex/bin/basex -bsource_url=cdda_dummy.xml dist/cdda-2017-qa-checks.xquery > out.html && google-chrome-stable out.html