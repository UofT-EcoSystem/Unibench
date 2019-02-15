/**
 * syrk_m.c: This file was adapted from PolyBench/GPU 1.0 test suite
 * to run on GPU with OpenMP 4.0 pragmas and OpenCL driver.
 *
 * http://www.cse.ohio-state.edu/~pouchet/software/polybench/GPU
 *
 * Contact: Marcio M Pereira <mpereira@ic.unicamp.br>
 *          Rafael Cardoso F Sousa <rafael.cardoso@students.ic.unicamp.br>
 *          Luís Felipe Mattos <ra107822@students.ic.unicamp.br>
 *
 */

#include "BenchmarksUtil.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <unistd.h>

// define the error threshold for the results "not matching"
#define ERROR_THRESHOLD 0.05

/* Problem size. */
#ifdef RUN_POLYBENCH_SIZE
#define SIZE 1024
#elif RUN_TEST
#define SIZE 1100
#elif RUN_BENCHMARK
#define SIZE 9600
#else
#define SIZE 1000
#endif

/* Problem size */
#define N SIZE
#define M SIZE

/* Declared constant values for alpha and beta */
/* (same as values in PolyBench 2.0) */
#define alpha 12435
#define beta 4546

/* Can switch DATA_TYPE between float and double */
typedef float DATA_TYPE;

DATA_TYPE A[N][M];
DATA_TYPE C[N][M];
DATA_TYPE D[N][M];
DATA_TYPE Dinit[N][M];

void init_arrays() {
  int i, j;

  for (i = 0; i < N; i++) {
    for (j = 0; j < M; j++) {
      A[i][j] = ((DATA_TYPE)i * j) / N;
    }
    for (j = 0; j < M; j++) {
      C[i][j] = ((DATA_TYPE)i * j + 2) / N;
      D[i][j] = 0;
      Dinit[i][j] = C[i][j];
    }
  }
}

void syrk() {
  int i, j, k;

  for (i = 0; i < N; i++) {
    for (j = 0; j < M; j++) {
      C[i][j] *= beta;
    }
  }

  for (i = 0; i < N; i++) {
    for (j = 0; j < M; j++) {
      for (k = 0; k < M; k++) {
        C[i][j] += alpha * A[i][k] * A[j][k];
      }
    }
  }
}

int compareResults() {
  int i, j, fail;
  fail = 0;

  // Compare C with D
  for (i = 0; i < N; i++) {
    for (j = 0; j < M; j++) {
      if (percentDiff(C[i][j], D[i][j]) > ERROR_THRESHOLD) {
        fail++;
      }
    }
  }

  // print results
  printf("Non-Matching CPU-GPU Outputs Beyond Error Threshold of %4.2f "
         "Percent: %d\n",
         ERROR_THRESHOLD, fail);

  return fail;
}

void syrkGPU() {
  int i, j, k;
  double t_start, t_end;

  t_start = rtclock();

#pragma omp target map(to : A, Dinit) map(tofrom : D) device(DEVICE_ID)
#pragma omp parallel for // collapse(2)
  for (i = 0; i < N; i++) {
    for (j = 0; j < M; j++) {
      D[i][j] = Dinit[i][j] * beta;
      for (k = 0; k < M; k++) {
        D[i][j] += alpha * A[i][k] * A[j][k];
      }
    }
  }

  t_end = rtclock();
  fprintf(stdout, "GPU Runtime: %0.6lfs\n", t_end - t_start);
}

int main() {
  double t_start, t_end;
  int fail = 0;

  fprintf(stdout, "<< Symmetric rank-k operations modified size: %d>>\n", SIZE);
  
  init_arrays();
  t_start = rtclock();
  syrkGPU();
  t_end = rtclock();

#ifdef RUN_TEST
  t_start = rtclock();
  syrk();
  t_end = rtclock();
  fprintf(stdout, "CPU Runtime: %0.6lfs\n", t_end - t_start);
  fail = compareResults();
#endif

  return fail;
}
