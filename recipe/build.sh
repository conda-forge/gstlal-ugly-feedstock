#!/bin/bash

set -ex

mkdir -p _build
pushd _build

# conda-forge/conda-forge.github.io#621
find ${PREFIX} -name "*.la" -delete

# only link libraries we actually use
export GSL_LIBS="-L${PREFIX}/lib -lgsl"
export GSTLAL_LIBS="-L${PREFIX}/lib -lgstlal -lgstlaltags -lgstlaltypes"
export framecpp_CFLAGS=" "
export LAL_LIBS="-L${PREFIX}/lib -llal"
if [[ "$(uname)" = "Linux" ]]; then
  export gds_framexmit_LIBS="-L${PREFIX}/lib -lframexmit"
  WITH_GDS="yes"
else
  WITH_GDS="no"
fi

# replace '/usr/bin/env python3' with '/usr/bin/python'
# so that conda-build will then replace it with the $PREFIX/bin/python
sed -i.tmp 's/\/usr\/bin\/env python3/\/usr\/bin\/python/g' ${SRC_DIR}/bin/gstlal_*

# configure
${SRC_DIR}/configure \
  --enable-gtk-doc=no \
  --enable-gtk-doc-html=no \
  --enable-gtk-doc-pdf=no \
  --enable-introspection \
  --prefix=${PREFIX} \
  --with-doxygen=no \
  --with-framecpp=yes \
  --with-gds="${WITH_GDS}" \
  --with-nds=yes \
;

# build
make -j ${CPU_COUNT} V=1 VERBOSE=1

# install
make -j ${CPU_COUNT} V=1 VERBOSE=1 install

# test (not when cross-compiling without an emulator)
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
  make -j ${CPU_COUNT} V=1 VERBOSE=1 check
fi
