#!/bin/bash

set -e

PREFIX=${HOME}/miniconda3

IGUIDE_ENV_NAME=${1-iguide}
OUTPUT=${2-/dev/stdout}

# Update install directory in simulation config file
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
DIR=${DIR::-4}
sed -i '/Install_Directory/c\Install_Directory : "'"${DIR}"'"'  ${DIR}/configs/simulation.config.yml
sed -i '/source activate/c\source activate '${IGUIDE_ENV_NAME}''  ${DIR}/tests/test.sh

install_conda () {
    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh -b -p ${PREFIX} >> ${OUTPUT}
    export PATH=${PATH}:${PREFIX}/bin
    command -v conda > /dev/null 2>&1 || { echo "Conda still is not on the path, try installing manually"; exit 1; }
    conda update -n base conda --yes
    rm Miniconda3-latest-Linux-x86_64.sh
}

command -v conda > /dev/null 2>&1 || { echo "Conda not installed, installing now ..."; install_conda; }

conda config --prepend channels 'bushmanlab'
conda config --prepend channels 'conda-forge'
conda config --prepend channels 'r'
conda config --prepend channels 'bioconda'

# Create enviroment if it does not exist
conda env list | grep -Fxq ${IGUIDE_ENV_NAME} || {
    conda env create --name ${IGUIDE_ENV_NAME} --file bin/build.v0.1.0.yml >> ${OUTPUT}
    source activate ${IGUIDE_ENV_NAME}
    Rscript bin/setup.R >> ${OUTPUT}
    cd tools
    git clone https://github.com/cnobles/dualDemultiplexR.git >> ${OUTPUT}
    git clone https://github.com/cnobles/seqTrimR.git >> ${OUTPUT}
    git clone https://github.com/cnobles/seqFiltR.git >> ${OUTPUT}
    git clone https://github.com/cnobles/seqConsolidateR.git >> ${OUTPUT}
    git clone https://github.com/cnobles/blatCoupleR.git >> ${OUTPUT}
    cd ../
    echo -e "iGUIDE successfully installed.\n" ;
}

echo -e "To get started, ensure ${PREFIX}/bin is in your path and\n" \
  "run 'source activate ${IGUIDE_ENV_NAME}'\n\n" \
  "To ensure ${PREFIX}/bin is in your path each time you long in,\n" \
  "append the following to your .bashrc or .bash_profile:\n\n" \
  "# Append miniconda3/bin to path\n" \
  "export PATH='~/miniconda3/bin:${PATH}'\n"
