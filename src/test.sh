#!/bin/bash

bin/site2app --session=test --app=icapito --appurl=https://icapito.it --level=debug &
bin/site2app --app=icapito --appurl=https://icapito.it --level=debug --private --tray &
exit 0
