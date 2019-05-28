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
BENCH_SOURCE=${BENCH_ROOT}/Unibench/benchmarks/Polybench

cd $BENCH_ROOT
if test -d debug-out
then
	echo debug-out exists. Script stops. 
	exit 1
else 
	mkdir debug-out 
fi

DEBUG_DIR=${BENCH_ROOT}/debug-out


declare -a bm_names=("2DCONV" "2MM" "3DCONV" "3MM" 
                     "ATAX" "BICG" "CORR" "COVAR" 
					 "FDTD-2D" "GEMM" "GESUMMV" "GRAMSCHM"
 					 "MVT" "SYR2K" "SYRK")
declare -a file_names=("2DConvolution.c" "2mm.c"
                       "3DConvolution.c" "3mm.c"
					   "atax.c" "bicg.c" "correlation.c" "covariance.c"
					   "fdtd2d.c" "gemm.c" "gesummv.c" "gramschmidt.c"
					   "mvt.c" "syr2k.c" "syrk.c")

cd ${DEBUG_DIR}

for i in "${!bm_names[@]}"; do
	printf '${AR[%s]}=%s %s\n' "$i" "${bm_names[i]}" "${file_names[i]}"
done

for i in "${!bm_names[@]}"
do 
	echo ${BENCH_SOURCE}/"${bm_names[i]}"/src
	mkdir ./"${bm_names[i]}"
	cd ./"${bm_names[i]}"
	clang -O3 -fopenmp -fopenmp-targets=nvptx64 -Xopenmp-target \
		-march=sm_61 -I${BENCH_SOURCE}/../common/ -DRUN_POLYBENCH_SIZE=1 \
		-DRUN_TEST=1 -DDEVICE_ID=0 -mllvm -openmp-tregion-runtime=1 \
		-mllvm -stats \
		${BENCH_SOURCE}/"${bm_names[i]}"/src/"${file_names[i]}" \
		-o ../bin/${bm_names[i]} 2> ${bm_names[i]}.log
	clang -O3 -fopenmp -fopenmp-targets=nvptx64 -Xopenmp-target \
		-march=sm_61 -I${BENCH_SOURCE}/../common/ -DRUN_POLYBENCH_SIZE=1 \
		-DRUN_TEST=1 -DDEVICE_ID=0 -mllvm -openmp-tregion-runtime=1 \
		-mllvm -debug-only=openmp-opt \
		${BENCH_SOURCE}/"${bm_names[i]}"/src/"${file_names[i]}" \
		-o ../bin/${bm_names[i]} 2> ${bm_names[i]}.ll 
	cd ..
done 

cd $BENCH_ROOT
