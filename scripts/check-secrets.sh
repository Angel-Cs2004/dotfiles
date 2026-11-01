#!/usr/bin/env bash
# Busca secretos y archivos privados antes de subir al repo.
# Uso: scripts/check-secrets.sh            -> revisa todo lo versionado
#      scripts/check-secrets.sh --staged   -> revisa solo lo que vas a commitear (lo usa el hook)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

if [[ ${1:-} == --staged ]]; then
    mapfile -t files < <(git diff --cached --name-only --diff-filter=ACMR)
else
    mapfile -t files < <(git ls-files)
fi
((${#files[@]})) || exit 0

fail=0
# 1) Nombres de archivo que jamás deben subirse
bad_names='(Cookies|Login Data|Web Data|History|Local Storage|Session Storage|leveldb|credentials|\.git-credentials|id_rsa|id_ed25519|\.pem$|\.key$|\.kdbx$|\.env$|\.pdf$)'
for f in "${files[@]}"; do
    if [[ $f =~ $bad_names ]]; then
        echo "✗ Archivo prohibido: $f"; fail=1
    fi
done

# 2) Contenido con pinta de token/clave
patterns='(ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|sk-[A-Za-z0-9_-]{30,}|sk-ant-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(CLIENT_SECRET|API_KEY|APIKEY|PASSWORD|TOKEN)[[:space:]]*[=:][[:space:]]*["'"'"']?[A-Za-z0-9_/+-]{12,})'
for f in "${files[@]}"; do
    [[ -f $f ]] || continue
    if grep -IEn "$patterns" -- "$f" >/dev/null 2>&1; then
        # Solo archivo:línea, sin mostrar el valor (podría quedar en un log)
        grep -IEn "$patterns" -- "$f" | cut -d: -f1 | sed "s|^|✗ Posible secreto en $f, línea |"
        fail=1
    fi
done

# 3) Archivos enormes (probable error)
for f in "${files[@]}"; do
    [[ -f $f ]] || continue
    size=$(stat -c %s -- "$f")
    if ((size > 20 * 1024 * 1024)); then echo "✗ Archivo de más de 20 MB: $f"; fail=1; fi
done

# 4) gitleaks, si está instalado, como segunda opinión
if command -v gitleaks >/dev/null; then
    if [[ ${1:-} == --staged ]]; then gitleaks protect --staged --no-banner -q || fail=1
    else gitleaks detect --no-banner -q || fail=1; fi
fi

if ((fail)); then
    echo; echo "Se encontraron posibles secretos. Corrige o quítalos antes de subir."
    exit 1
fi
echo "✓ Sin secretos detectados (${#files[@]} archivos revisados)"
