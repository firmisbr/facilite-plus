# PRD — Aplicativo de Empréstimos Offline-First

## Visão Geral

Aplicativo de gestão de empréstimos pessoais com funcionamento offline-first, sincronização automática em nuvem, backup automático, controle financeiro avançado e suporte multiplataforma.

O aplicativo deve seguir fielmente a identidade visual do Claude (Anthropic), com uma estética moderna, sofisticada, minimalista e premium.

Quero suporte completo a:

* tema claro (light mode)
* tema escuro (dark mode)

As cores devem ser fortemente inspiradas no Claude, mantendo a mesma sensação visual:

* tons quentes
* neutros elegantes
* aparência clean
* visual confortável e refinado
* foco em legibilidade e espaçamento

━━━━━━━━━━━━━━━━━━
🎨 TEMA ESCURO
━━━━━━━━━━━━━━━━━━

Objetivo:
Criar uma interface elegante e aconchegante, com aparência premium e moderna.

Paleta:

* Fundo principal: #232320
* Superfícies/cards: #2B2B27
* Accent principal: #D97757
* Accent secundário: #F2CC8F
* Texto principal: #F4F1EA
* Texto secundário: #B7B2A8
* Bordas sutis: #3A3A35

━━━━━━━━━━━━━━━━━━
☀️ TEMA CLARO
━━━━━━━━━━━━━━━━━━

Objetivo:
Manter a mesma identidade do tema escuro, porém com aparência leve, limpa e sofisticada.

Paleta:

* Fundo principal: #F7F3ED
* Superfícies/cards: #FFFFFF
* Accent principal: #D97757
* Accent secundário: #E9C46A
* Texto principal: #2B2B27
* Texto secundário: #6B665E
* Bordas sutis: #E6DED3

━━━━━━━━━━━━━━━━━━
✍️ TIPOGRAFIA
━━━━━━━━━━━━━━━━━━

Fonte principal:

* Inter

Estilo desejado:

* moderno
* minimalista
* alta legibilidade
* aparência profissional
* interface semelhante ao Claude, Linear e Stripe

━━━━━━━━━━━━━━━━━━
⚡ DIREÇÃO VISUAL
━━━━━━━━━━━━━━━━━━

Priorizar:

* muito espaçamento
* hierarquia visual limpa
* poucos elementos na tela
* sombras suaves
* animações discretas
* aparência premium
* UI elegante e responsiva

Evitar:

* gradientes exagerados
* glassmorphism excessivo
* cores neon
* azul corporativo padrão
* excesso de informações visuais
* preto puro (#000000)


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
- PowerSync

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
3. PowerSync detecta mudança
4. Sync envia ao Supabase
5. Supabase replica para outros dispositivos

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
