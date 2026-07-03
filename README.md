# shrub <img src="media/hexlogo.png" align="right" height="150"/>

**Shell to R Utility Bridge**

<!-- badges: start -->
![version](https://img.shields.io/badge/version-0.1.0-blue)
![license](https://img.shields.io/badge/license-MIT-green)
<!-- badges: end -->

---

R a veces se siente como algo muy aislado y no tiene tanta integracion con la terminal. Shrub se trata d eso. Un conjunto mínimo de utilidades para navegar y explorar el filesystem desde la sesión de R, sin salir, sin `setwd()` a mano, sin perder el hilo.

Cero dependencias. Puro base R.
# <img src="media/img1.png" align="center" heigth="200"/>
## Instalación

```r
# install.packages("remotes")
remotes::install_github("jcarocont/shrub")
```

## Funciones

### `cdir()` — navegar por patrón

Busca directorios que coincidan con un patrón y cambia al mejor candidato. Si hay un único match, navega directo. Si hay varios, un sistema de scoring decide: podés preferir el directorio con nombre más corto, el más superficial en el árbol, o ambos.

```r
cdir("data")                               # navega al dir que matchea "data"
cdir("proj", rec = TRUE, dirname = "short") # si hay varios, elige el de nombre más corto
cdir("src",  rec = TRUE, dirpath = "short") # elige el más cercano a la raíz
```

El scoring es aditivo: `dirname` y `dirpath` se pueden combinar. Si ningún criterio resuelve el empate, imprime todos los matches y no mueve nada.

---

### `fzfind()` — buscar archivos y directorios

Filtra paths por regex en un árbol de directorios. Equivalente a un `find` liviano desde R.

```r
fzfind("README")                   # cualquier cosa que se llame README
fzfind("\\.csv$", type = "file")   # solo archivos .csv
fzfind("raw", type = "dir")        # solo directorios con "raw" en el nombre
```

---

### `cdp()` — subir niveles

Sube `n` niveles en el árbol de directorios. El equivalente de `cd ../../..`.

```r
cdp()    # sube un nivel
cdp(3)   # sube tres niveles
```

---

### `cdls()` — navegar y listar

Navega a un directorio (via `cdir()`) y lista su contenido de inmediato.

```r
cdls("data")   # entra a "data" y lista los archivos
```

---

### `rla()` — metadata de archivos

Devuelve un dataframe con metadata del contenido de un directorio. El `ls -la` de R.

```r
rla()           # directorio actual
rla("~/data")   # directorio específico
```
### `dv()` — alias corto de `list()`

Wrapper directo para no escribir `list(...)` cien veces en la consola.

```r
dv(a = 1, b = 2)
```

---

### `argsetter()` — setear defaults de argumentos, a nivel de sesión

Modifica los valores por omisión de los argumentos formales de una función existente. Persiste mientras dure la sesión. El estado original queda guardado en un slot interno (`.argsetter`) dentro de los atributos de la función, listo para revertir con `argclean()`.

```r
f <- function(a = 1, b = 2) a + b
f <- argsetter(f, dv(a = 10))
f()   # 12
```

---

### `argclean()` — restaurar los defaults originales

Revierte una función modificada con `argsetter()` a sus formals originales.

```r
f <- argclean(f)
f()   # 3
```

## Autor

Julián Caro — [jcaro.cont@gmail.com](mailto:jcaro.cont@gmail.com)

## Licencia

MIT
