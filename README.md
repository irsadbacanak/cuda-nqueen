# N-Queen Solver — CUDA

N-Queen problemini CUDA ile paralel backtracking kullanarak çözen C++ programı.

## Nasıl Çalışır?

İlk satırdaki her kolon pozisyonu ayrı bir CUDA thread'ine atanır. Her thread kendi alt problemini `__device__` backtracking ile bağımsız olarak çözer; bulunan çözümler `atomicAdd` ile ortak sayaca eklenir.

```
Kernel: <<<1 blok, N thread>>>

  thread 0   → ilk satırda kolon 0 sabit → backtrack (satır 1..N-1)
  thread 1   → ilk satırda kolon 1 sabit → backtrack (satır 1..N-1)
  ...
  thread N-1 → ilk satırda kolon N-1 sabit → backtrack (satır 1..N-1)
                                                       ↓
                                              atomicAdd(toplam)
```

### Bileşenler

| Fonksiyon | Tür | Görev |
|---|---|---|
| `isSafe()` | `__device__` | Verilen pozisyon güvenli mi? |
| `solve()` | `__device__` | Rekürsif backtracking |
| `nqueensKernel()` | `__global__` | Thread başlatıcı, ilk satırı sabitler |

## Gereksinimler

- CUDA Toolkit 11.0+
- CMake 3.18+
- Compute Capability 5.0+ GPU (Maxwell ve üzeri)
- Linux veya Windows (WSL2 dahil)

> macOS desteklenmez — Apple CUDA desteğini bırakmıştır.

## Derleme

```bash
mkdir build && cd build

# GPU mimarisini otomatik algıla (CMake 3.24+)
cmake ..

# veya GPU mimarisini elle belirt
cmake .. -DCMAKE_CUDA_ARCHITECTURES=86   # RTX 3050 Ti / 3000 serisi
cmake .. -DCMAKE_CUDA_ARCHITECTURES=75   # RTX 2000 serisi
cmake .. -DCMAKE_CUDA_ARCHITECTURES=70   # Tesla V100

cmake --build . -j$(nproc)
```

### Yaygın GPU Mimarileri

| GPU | Mimari | `CUDA_ARCHITECTURES` |
|---|---|---|
| RTX 3050 Ti / 3060 / 3080 | Ampere | `86` |
| RTX 2060 / 2080 | Turing | `75` |
| GTX 1060 / 1080 | Pascal | `61` |
| Tesla V100 | Volta | `70` |

## Çalıştırma

```bash
./nqueen
```

```
N degerini girin (1-16): 8
N = 8 icin toplam cozum sayisi : 92
Gecen sure                      : 0.243 ms
```

## Referans Çözüm Sayıları

| N | Çözüm Sayısı |
|---|---|
| 1 | 1 |
| 4 | 2 |
| 6 | 4 |
| 8 | 92 |
| 10 | 724 |
| 12 | 14200 |
| 14 | 365596 |
| 16 | 14772512 |

## Kısıtlar

- Maksimum N = 16
- Yalnızca çözüm sayısı hesaplanır, board konfigürasyonları saklanmaz
- Her CUDA API çağrısı sonrasında hata kontrolü yapılır (`CUDA_CHECK` makrosu)
