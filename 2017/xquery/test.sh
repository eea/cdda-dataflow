#!/bin/sh
basex/bin/basex -bsource_url=cdda_dummy.xml cdda-designatedarea-linkeddataset-2017.xquery > out.html && google-chrome-stable out.html