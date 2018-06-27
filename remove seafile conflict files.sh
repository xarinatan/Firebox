#!/bin/bash
find . -iname "*(SFConflict*" -print0 | xargs -0 -I file mv file ./SFConflicts/
