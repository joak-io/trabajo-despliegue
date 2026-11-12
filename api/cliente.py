import sys
import threading
import time
import urllib.request

URL = "http://127.0.0.1:8000/api/lenta"      # 127.0.0.1 y no localhost: en Windows tarda mas
N = int(sys.argv[1]) if len(sys.argv) > 1 else 4


def pedir():
    inicio = time.time()
    urllib.request.urlopen(URL).read()
    print(f"  una respuesta a los {time.time() - inicio:.2f} s")


hilos = [threading.Thread(target=pedir) for i in range(N)]
inicio = time.time()
for h in hilos:
    h.start()
for h in hilos:
    h.join()
print(f"TOTAL para {N} peticiones a la vez: {time.time() - inicio:.2f} s")