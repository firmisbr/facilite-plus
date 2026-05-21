# PRD — Aplicativo de Empréstimos Offline-First

## Visão Geral

Aplicativo de gestão de empréstimos pessoais com funcionamento offline-first, sincronização automática em nuvem, backup automático, controle financeiro avançado e suporte multiplataforma.

O aplicativo segue a identidade visual **Facilite Plus**: estética moderna, sofisticada, minimalista e premium, com referências a Stripe, Linear, Notion e Ramp.

Suporte completo a:

* tema claro (light mode)
* tema escuro (dark mode)

**Diferencial da paleta:** verde premium (`#4C6B5A`) como cor principal — transmite segurança financeira, estabilidade e crescimento, sem o visual agressivo de fintechs genéricas ou verde neon.

Implementação no app: `lib/core/theme/app_colors.dart` e `lib/core/theme/app_theme.dart`.

━━━━━━━━━━━━━━━━━━
🌑 TEMA ESCURO
━━━━━━━━━━━━━━━━━━

**Objetivo**

Criar uma interface sofisticada, moderna e acolhedora, transmitindo confiança, organização e estabilidade financeira.

**Paleta atualizada**

| Token | Cor |
|-------|-----|
| Fundo principal | `#141513` |
| Superfícies / cards | `#1F1F1D` |
| Accent principal (verde premium) | `#4C6B5A` |
| Accent secundário (verde suave) | `#A7C3A1` |
| Destaque / detalhes premium | `#E3C88D` |
| Texto principal | `#F4F1EA` |
| Texto secundário | `#A7A398` |
| Bordas sutis | `#2E2E2B` |

**Sensação visual:** elegante, premium, confiável, moderna, humana, minimalista.

Referências: Notion, Linear, Ramp.

| Elemento | Cor |
|----------|-----|
| Botões principais | `#4C6B5A` |
| Fundo / scaffold | `#141513` |
| Cards | `#1F1F1D` |
| Badges e destaques premium | `#E3C88D` |
| Texto secundário / ícones | `#A7A398` |

━━━━━━━━━━━━━━━━━━
☀️ TEMA CLARO
━━━━━━━━━━━━━━━━━━

**Objetivo**

Manter a identidade premium do dark mode com aparência leve, limpa e sofisticada.

**Paleta atualizada**

| Token | Cor |
|-------|-----|
| Fundo principal | `#F7F5F1` |
| Superfícies / cards | `#FFFFFF` |
| Accent principal (verde premium) | `#4C6B5A` |
| Accent secundário (verde suave) | `#A7C3A1` |
| Destaque / detalhes premium | `#E3C88D` |
| Texto principal | `#232320` |
| Texto secundário | `#6F6A62` |
| Bordas sutis | `#E7E0D6` |

**Sensação visual:** clean, sofisticado, moderno, leve, profissional, acolhedor.

| Elemento | Cor |
|----------|-----|
| Botões principais | `#4C6B5A` |
| Fundo geral | `#F7F5F1` |
| Cards | `#FFFFFF` |
| Divisores e bordas | `#E7E0D6` |
| Destaques financeiros | `#E3C88D` |

━━━━━━━━━━━━━━━━━━
✍️ TIPOGRAFIA
━━━━━━━━━━━━━━━━━━

**Fonte principal:** Inter

**Estilo desejado**

* moderno
* minimalista
* alta legibilidade
* aparência profissional
* elegante sem parecer “banco antigo”
* interface semelhante a Stripe, Linear, Notion

| Uso | Peso |
|-----|------|
| Títulos | 700 |
| Subtítulos | 600 |
| Texto padrão | 400 |
| Labels/UI | 500 |

━━━━━━━━━━━━━━━━━━
🎨 CORES AUXILIARES (UI)
━━━━━━━━━━━━━━━━━━

| Semântica | Cor | Uso típico |
|-----------|-----|------------|
| Sucesso | `#5FA36A` | Parcela paga, confirmações |
| Atenção | `#D6A85F` | Alertas, vencimentos próximos |
| Erro | `#C46A6A` | Atraso, falhas, exclusão |
| Informação | `#6B8FA3` | Dicas, pagamento antecipado |

━━━━━━━━━━━━━━━━━━
🧠 IDENTIDADE TRANSMITIDA
━━━━━━━━━━━━━━━━━━

A paleta comunica:

* segurança financeira
* clareza
* estabilidade
* crescimento
* facilidade
* organização
* sofisticação moderna

**Evitar** o visual:

* agressivo de fintech genérica
* azul corporativo padrão
* laranja “varejo”
* verde neon de banco digital
* gradientes exagerados
* glassmorphism excessivo
* preto puro (`#000000`)

**Priorizar**

* muito espaçamento
* hierarquia visual limpa
* poucos elementos na tela
* sombras suaves
* animações discretas
* UI elegante e responsiva


Objetivo principal:
Permitir que gerentes realizem controle completo de clientes, empréstimos, cobranças, pagamentos e relatórios mesmo sem internet.

---

# Stack Tecnológica

## Frontend
- Flutter
- Dart
- Riverpod
- GoRouter

## Banco de Dados
### Local
- SQLite
- Drift ORM

### Nuvem
- Supabase PostgreSQL

### Sincronização
- Fila local (`sync_queue`) + envio manual/automático ao Supabase (implementado)
- PowerSync (legado no schema remoto; não usado no app atual)

---

# Funcionalidades Principais

## Autenticação
- Login com email e senha
- Recuperação de senha
- Sessão persistente
- Logout

## Clientes
- Cadastro completo
- Busca rápida
- Histórico financeiro
- Status de inadimplência

## Empréstimos
- Criar empréstimos
- Parcelamento
- Juros personalizados
- Datas de vencimento
- Histórico de pagamentos

## Pagamentos
- Registrar pagamentos
- Pagamento parcial
- Pagamento total
- Comprovantes

## Dashboard
- Total emprestado
- Total recebido
- Lucro
- Inadimplência
- Fluxo de caixa

## Relatórios
- PDF
- Compartilhamento
- Exportação

## Offline-First
- Funcionamento sem internet
- Cache local completo
- Sync automático

## Backup
- Backup automático
- Backup manual
- Exportação JSON
- Histórico de versões

---

# Estrutura de Banco

## users
```sql
id
name
email
created_at
```

## clients
```sql
id
user_id
name
phone
document
address
notes
created_at
```

## loans
```sql
id
client_id
amount
interest
installments
status
created_at
```

## payments
```sql
id
loan_id
amount
payment_date
method
created_at
```

---

# Fluxo Offline

1. Usuário cria alteração localmente
2. Drift salva no SQLite
3. Item entra na fila `sync_queue`
4. `SyncService` envia ao Supabase quando há sessão e rede
5. `pullRemoteChanges` baixa dados do Supabase para o dispositivo

---

# Segurança

- Row Level Security
- JWT Auth
- Dados separados por usuário
- Criptografia local futura

---

# Roadmap

## Fase 1
- Setup Flutter
- Supabase
- Login

## Fase 2
- Clientes
- Empréstimos
- Pagamentos

## Fase 3
- Dashboard
- Relatórios
- PDFs

## Fase 4
- Backup
- Sync avançado
- Auditoria

---

# Critérios de Aceite

- App funciona offline
- Sync automático funcional
- Backup funcionando
- Relatórios em PDF
- Performance estável
- Dados seguros

---

# Estrutura de Pastas

```txt
/lib
  /core
  /features
    /auth
    /clients
    /loans
    /payments
    /dashboard
  /shared
  /services
```

---

# Dependências Flutter

```yaml
flutter_riverpod:
go_router:
drift:
sqlite3_flutter_libs:
supabase_flutter:
powersync:
fl_chart:
pdf:
printing:
share_plus:
flutter_local_notifications:
```

---

# Objetivo Final

Criar um sistema profissional de empréstimos, escalável, robusto e preparado para múltiplos usuários e operação offline completa.
