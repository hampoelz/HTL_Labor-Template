#
# Copyright (c) 2022 Rene Hampölz
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file under
# https://github.com/hampoelz/LaTeX-Template.
#

#!/bin/bash

git clean -Xdf
find . -type d -empty -print | grep -v .git | tr "\n" "\0" | xargs -0 -r rm -r

exit 0