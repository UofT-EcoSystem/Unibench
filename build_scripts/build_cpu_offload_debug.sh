#!/usr/bin/bash

BENCH_ROOT=$1

if test -z $1
then 
	echo "usage: bash $0 \$BENCH_ROOT"
	exit 1
else
	echo Benchmark root at `realpath $BENCH_ROOT`
	echo continue?\[y/n\]
	read input
	if test $input != y
	then
		echo Aborted
		exit 1
	fi 
fi

BENCH_ROOT=`realpath $BENCH_ROOT`

cd $BENCH_ROOT
if test -d build-debug
then
	echo Build exists. Script will update existing build.  
else 
	mkdir build-debug
fi

BENCH_BUILD=${BENCH_ROOT}/cpu-build-debug
BENCH_SOURCE=${BENCH_ROOT}/Unibench
BENCH_INSTALL=${BENCH_ROOT}/cpu-install-debug

cd $BENCH_BUILD
echo ${BENCH_SOURCE}
cmake -DCMAKE_INSTALL_PREFIX=${BENCH_INSTALL} \
	-DCMAKE_C_COMPILER=clang \
	-DCMAKE_CXX_COMPILER=clang++ \
	-DCMAKE_BUILD_TYPE=Debug \
	-DRUN_TEST=1 \
	-DRUN_POLYBENCH_SIZE=1 \
	-DOMP_GPU_OFFLOAD=0 ${BENCH_SOURCE}

if test $? -ne 0
then
	echo cmake encountered an error
	exit 1
fi

echo Finished generating make files. 
echo Start building and then install? \[y/n\]
read input
if test $input != y
then
	echo Abort
	exit 1
fi

echo Start building and installing...

make -j8 install
if test $? -ne 0
then
	echo make encountered an error
	exit 1
fi

cd $BENCH_ROOT
echo Installation finished. 
