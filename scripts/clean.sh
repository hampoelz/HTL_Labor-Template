#
# Copyright (c) 2023 Rene Hampölz
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file under
# https://github.com/hampoelz/LaTeX-Template.
#

# usage: https://github.com/hampoelz/LaTeX-Template/wiki/02-Usage#preconfigured-scriptstasks

#!/bin/bash

git clean -Xdf
find . -type d -empty -print | grep -v .git | tr "\n" "\0" | xargs -0 -r rm -r

exit 0