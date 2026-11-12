
import sys
from collections import Counter

peticiones = []
tiempos = []
with open(sys.argv[1], encoding="utf-8") as f:
    for linea in f:
        momento, ip, metodo_ruta, estado, enviados, tardo = linea.split(" | ")
        ruta = metodo_ruta.split(" ")[1]
        peticiones.append((ruta, estado))
        tiempos.append((float(tardo.split()[0]), ruta)) # esto saca los segundos y la ruta

print(f"{len(peticiones)} peticiones")

print("Codigos de estado:")
for estado, n in Counter(e for r, e in peticiones).most_common():
    print(f"   {estado}  {n}")

print("Rutas mas pedidas:")
for ruta, n in Counter(r for r, e in peticiones).most_common(3):
    print(f"   {n}  {ruta}")

print("Rutas que dan 404:")
for ruta, n in Counter(r for r, e in peticiones if e == "404").most_common():
    print(f"   {n}  {ruta}")

print (f"Tiempo Medio: {sum(t, r in tiempos) / len(tiempos):.3f} s")
lenta, ruta = max(tiempos)
print (f"La mas lenta: {ruta} ({lenta:.3f} s)")

errores = [e for r, e in peticiones if int(e) >= 400]
print (f"Errores (400 o más): {100 * len(errores)/len(peticiones):.1f} %")
