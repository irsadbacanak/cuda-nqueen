#include <cuda_runtime.h>
#include <stdio.h>
#include <stdlib.h>

#define MAX_N 16

#define CUDA_CHECK(call)                                                        \
    do {                                                                        \
        cudaError_t _err = (call);                                              \
        if (_err != cudaSuccess) {                                              \
            fprintf(stderr, "CUDA hatasi %s:%d — %s\n",                        \
                    __FILE__, __LINE__, cudaGetErrorString(_err));              \
            exit(EXIT_FAILURE);                                                 \
        }                                                                       \
    } while (0)

// Satir 'row' icin 'col' kolonuna vezir koymak guvenli mi?
// board[i] = i. satirda vezirin bulundugu kolon
__device__ bool isSafe(const int* board, int row, int col)
{
    for (int i = 0; i < row; i++) {
        int rowDiff = row - i;           // her zaman pozitif (i < row)
        int colDiff = board[i] - col;
        // ayni kolon veya ayni capraz
        if (colDiff == 0 || colDiff == rowDiff || colDiff == -rowDiff)
            return false;
    }
    return true;
}

// row satirindan itibaren backtracking ile cozumleri say
__device__ void solve(int* board, int row, int n, int* count)
{
    if (row == n) {
        atomicAdd(count, 1);
        return;
    }
    for (int col = 0; col < n; col++) {
        if (isSafe(board, row, col)) {
            board[row] = col;
            solve(board, row + 1, n, count);
        }
    }
}

// Her thread, ilk satirda farkli bir kolon pozisyonu ile baslar
__global__ void nqueensKernel(int n, int* totalCount)
{
    int firstCol = threadIdx.x;  // thread indeksi = ilk satirda kolon
    if (firstCol >= n) return;

    int board[MAX_N];
    board[0] = firstCol;         // ilk satir sabit, kalan satirlar solve ile doldurulur

    solve(board, 1, n, totalCount);
}

int main(void)
{
    int n;
    printf("N degerini girin (1-%d): ", MAX_N);
    if (scanf("%d", &n) != 1 || n < 1 || n > MAX_N) {
        fprintf(stderr, "Gecersiz N. 1 ile %d arasinda bir deger girin.\n", MAX_N);
        return EXIT_FAILURE;
    }

    // Recursive __device__ fonksiyonlar icin yeterli stack bellek ayir
    CUDA_CHECK(cudaDeviceSetLimit(cudaLimitStackSize, 32768));

    // Cozum sayaci
    int* d_count;
    CUDA_CHECK(cudaMalloc(&d_count, sizeof(int)));
    CUDA_CHECK(cudaMemset(d_count, 0, sizeof(int)));

    // Zamanlama
    cudaEvent_t evStart, evStop;
    CUDA_CHECK(cudaEventCreate(&evStart));
    CUDA_CHECK(cudaEventCreate(&evStop));

    // N thread, her biri ilk satirda bir kolon pozisyonu
    CUDA_CHECK(cudaEventRecord(evStart));
    nqueensKernel<<<1, n>>>(n, d_count);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());
    CUDA_CHECK(cudaEventRecord(evStop));
    CUDA_CHECK(cudaEventSynchronize(evStop));

    float elapsedMs;
    CUDA_CHECK(cudaEventElapsedTime(&elapsedMs, evStart, evStop));

    // Sonucu CPU'ya aktar
    int h_count = 0;
    CUDA_CHECK(cudaMemcpy(&h_count, d_count, sizeof(int), cudaMemcpyDeviceToHost));

    printf("N = %d icin toplam cozum sayisi : %d\n", n, h_count);
    printf("Gecen sure                      : %.3f ms\n", elapsedMs);

    // Temizlik
    CUDA_CHECK(cudaFree(d_count));
    CUDA_CHECK(cudaEventDestroy(evStart));
    CUDA_CHECK(cudaEventDestroy(evStop));

    return EXIT_SUCCESS;
}
