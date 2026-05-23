# Comandos — release.ps1

Script de publicação OTA do **Facilite Plus**.  
Executa o fluxo completo: versão → build → GitHub Release → manifesto Supabase.

> Sempre rode na **raiz do projeto** (`C:\projetos-firmis\facilite-plus`).

---

## Pré-requisito

O arquivo `.env.release` deve existir na raiz com as variáveis abaixo.  
Copie `.env.release.example` como base:

```env
SUPABASE_URL=https://...supabase.co
SUPABASE_SERVICE_ROLE_KEY=...
GITHUB_REPO=firmisbr/facilite-plus
GITHUB_TOKEN=github_pat_...
```

---

## Parâmetros

### `-Bump` _(obrigatório, a menos que use `-Version`)_

Define o tipo de incremento automático de versão.

| Valor | O que faz | Exemplo |
|-------|-----------|---------|
| `patch` | Incrementa correção: `X.Y.Z+N` → `X.Y.Z+1+N+1` | `1.0.0` → `1.0.1` |
| `minor` | Incrementa funcionalidade: zera patch | `1.0.1` → `1.1.0` |
| `major` | Incrementa versão principal: zera minor e patch | `1.1.0` → `2.0.0` |

O número de build (`+N`) **sempre sobe +1** independente do tipo.

---

### `-Version` _(alternativa ao `-Bump`)_

Define a versão exata no formato `X.Y.Z`. O build sobe +1 automaticamente.

```powershell
.\scripts\release.ps1 -Version 1.5.0 -Changelog "..."
```

---

### `-Changelog` _(opcional)_

Texto que aparece na tela **Atualizações** do app, na seção "O que há de novo".

- Se omitido, usa `"Atualização vX.Y.Z"` automaticamente.
- Aceita múltiplas linhas com `` `n ``:

```powershell
-Changelog "- Nova funcionalidade`n- Correção de bug`n- Melhorias de desempenho"
```

---

### `-SkipBuild` _(switch)_

Pula o `flutter build apk`. Usa o APK já existente em:

```
build\app\outputs\flutter-apk\app-release.apk
```

Útil quando o build já foi feito e só o upload falhou.

---

### `-SkipVersionBump` _(switch)_

Não altera `pubspec.yaml` nem `app_version.dart`.  
Mantém a versão que já está no projeto.

Útil para **reenviar** um APK sem mudar a versão.

---

### `-SkipUpload` _(switch)_

Não envia nada ao GitHub nem ao Supabase.  
Apenas atualiza os arquivos locais (`pubspec.yaml`, `app_version.dart`) e opcionalmente builda.

---

### `-DryRun` _(switch)_

Simula o upload e o PATCH no Supabase **sem enviar nada**.  
Imprime as URLs e o payload que seriam enviados.  
Ainda altera `pubspec.yaml` e `app_version.dart` localmente (a menos que combine com `-SkipVersionBump`).

---
























## Exemplos prontos

### Release completa — correção de bug
```powershell
.\scripts\release.ps1 -Bump patch -Changelog "Correções na sincronização"
```
`1.0.0+1` → `1.0.1+2`

---

### Release completa — nova funcionalidade
```powershell
.\scripts\release.ps1 -Bump minor -Changelog "- Relatórios exportáveis`n- Melhorias no dashboard"
```
`1.0.1+2` → `1.1.0+3`

---

### Release completa — atualização grande (versão major)
```powershell
.\scripts\release.ps1 -Bump major -Changelog "Redesign completo e nova arquitetura"
```
`1.0.1+2` → `2.0.0+3`

Use quando houver mudança grande, breaking change ou nova versão principal (ex.: 1.x → 2.0).




























---

### Release com versão manual
```powershell
.\scripts\release.ps1 -Version 2.0.0 -Changelog "Redesign completo do app"
```

---

### Testar sem enviar nada (simulação)
```powershell
.\scripts\release.ps1 -Bump patch -DryRun
```

---

### Só buildar localmente (sem subir)
```powershell
.\scripts\release.ps1 -Bump patch -SkipUpload
```

---

### Só subir (APK já buildado, versão já bumped)
```powershell
.\scripts\release.ps1 -SkipBuild -SkipVersionBump -Changelog "Reenvio do APK"
```

---

### Repetir upload sem mudar versão nem rebuildar
```powershell
.\scripts\release.ps1 -SkipVersionBump -SkipBuild -Changelog "Descrição atualizada"
```

---

## O que o script faz por dentro (ordem de execução)

```
1. Lê .env.release
2. Lê versão atual do pubspec.yaml
3. Calcula próxima versão (-Bump ou -Version)
4. Atualiza pubspec.yaml  →  version: X.Y.Z+N
5. Atualiza app_version.dart  →  fallback = 'X.Y.Z'
6. flutter pub get
7. flutter build apk --release
8. Cria GitHub Release  →  vX.Y.Z
9. Faz upload do APK como asset da release
10. Monta URL pública de download
11. PATCH em app_update_manifest (id=1) no Supabase
12. Imprime URL final para teste
```

---

## Após a release

- Abra a **URL impressa** no navegador — deve baixar o APK.
- No celular com versão **anterior**: Config → bolinha amarela → **Atualizações** → Baixar e instalar.
- Faça commit dos arquivos alterados se quiser versionar:

```powershell
git add pubspec.yaml lib/core/config/app_version.dart
git commit -m "chore: release vX.Y.Z"
git push
```

---

## Erros comuns

| Mensagem | Causa | Solução |
|----------|-------|---------|
| `.env.release não encontrado` | Arquivo ausente ou fora da raiz | Criar na raiz do projeto |
| `Variável X ausente` | Linha faltando no `.env.release` | Verificar todas as 4 variáveis |
| `flutter build apk falhou` | Erro de compilação no app | Corrigir o código e tentar de novo |
| `401 / 403 no GitHub` | `GITHUB_TOKEN` inválido ou expirado | Gerar novo token em github.com/settings/tokens |
| `404 no download (app)` | Repositório privado | Tornar o repositório público |
| `Sem bolinha amarela no app` | Versão no manifesto não é maior que a instalada | Confirmar `version` na tabela `app_update_manifest` |
| `INSTALL_FAILED_NO_MATCHING_ABIS` | APK de ABI errado para o dispositivo | Usar APK universal (`flutter build apk --release` sem `--split-per-abi`) |
