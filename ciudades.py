import csv, io, sys, urllib.request, ssl, certifi, unicodedata

CSV_URL = "https://www.datos.gov.co/api/views/gdxc-w37w/rows.csv?accessType=DOWNLOAD"
OUT_SQL = "ciudades_departamentos.sql"

# Quitar tildes y caracteres especiales
def quitar_tildes(texto):
    return ''.join(
        c for c in unicodedata.normalize('NFD', texto)
        if unicodedata.category(c) != 'Mn'
    )

ctx = ssl.create_default_context(cafile=certifi.where())

with urllib.request.urlopen(CSV_URL, context=ctx) as r:
    content = r.read().decode("utf-8", errors="ignore")

reader = csv.DictReader(io.StringIO(content))

col_municipio = [k for k in reader.fieldnames if "Nombre Municipio" in k][0]
col_departamento = [k for k in reader.fieldnames if "Nombre Departamento" in k][0]

municipios = []
seen = set()
for row in reader:
    nombre = quitar_tildes(row[col_municipio].strip())
    depto = quitar_tildes(row[col_departamento].strip())
    if nombre and depto:
        ciudad_depto = f"{nombre} - {depto}"
        if ciudad_depto not in seen:
            seen.add(ciudad_depto)
            municipios.append(ciudad_depto)

with open(OUT_SQL, "w", encoding="utf-8") as f:
    f.write(
        "CREATE TABLE IF NOT EXISTS ciudades (\n"
        "  id SERIAL PRIMARY KEY,\n"
        "  ciudad TEXT NOT NULL UNIQUE\n"
        ");\n\n"
    )
    f.write("INSERT INTO ciudades (ciudad) VALUES\n")
    for i, m in enumerate(municipios):
        m_sql = m.replace("'", "''")
        sep = "," if i < len(municipios)-1 else ";"
        f.write(f"('{m_sql}'){sep}\n")

print(f"✅ OK: generado {OUT_SQL} con {len(municipios)} registros.")



