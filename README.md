<div align="center">
  <img src="assets/images/logo_extended_black.png#gh-light-mode-only" alt="Facilite Plus" height="56" />
  <img src="assets/images/logo_extended_white.png#gh-dark-mode-only" alt="Facilite Plus" height="56" />

  <br/>
  <br/>

  <p>Gestão de empréstimos pessoais — offline-first, sincronização em nuvem e relatórios completos.</p>

  ![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
  ![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase&logoColor=white)
  ![Android](https://img.shields.io/badge/Android-Disponível-3DDC84?logo=android&logoColor=white)
</div>

---

## Sobre

**Facilite Plus** é um aplicativo Android para gestão de empréstimos pessoais com foco em simplicidade e confiabilidade. Funciona completamente offline e sincroniza com a nuvem quando há conexão disponível.

## Funcionalidades

- **Dashboard** — visão geral de empréstimos ativos, cobranças do dia e métricas financeiras
- **Empréstimos** — cadastro com simulação de parcelas, juros e diferentes periodicidades
- **Cobranças** — controle de parcelas vencidas, a vencer e pagas com filtros avançados
- **Clientes** — cadastro completo com histórico de empréstimos por cliente
- **Relatórios** — resumo por período, inadimplência, previsão de recebimentos e exportação CSV
- **Backup** — exportar com PIN ou importar em outra conta
- **Sincronização** — dados na nuvem via Supabase, disponíveis em qualquer dispositivo após sync
- **Atualizações OTA** — sistema de atualização automática sem necessidade de loja de apps
- **Notificações** — lembretes configuráveis de parcelas a vencer
- **Tema claro e escuro** — alternância dinâmica de aparência

## Stack

| Camada | Tecnologia |
|--------|-----------|
| UI / Lógica | Flutter + Dart |
| Estado | Riverpod |
| Navegação | GoRouter |
| Banco local | Drift (SQLite) |
| Backend / Auth | Supabase |
| OTA | GitHub Releases + Supabase Manifest |

## Arquitetura

O app segue uma arquitetura **offline-first**:

```
Dispositivo (Drift/SQLite)  ←→  Fila de sync  →  Supabase (Postgres + Auth)
```

- Todas as operações são escritas localmente primeiro
- Uma fila de sincronização (`sync_queue`) registra operações pendentes
- A sync envia alterações locais e baixa dados da nuvem quando há internet
- O app funciona normalmente sem conexão

```
lib/
├── core/           # Roteamento, tema, configurações
├── features/       # Módulos por funcionalidade
│   ├── admin/      # Painel administrativo (role admin)
│   ├── auth/       # Login e recuperação de senha
│   ├── backup/     # Exportação e importação de dados
│   ├── clients/    # Gestão de clientes
│   ├── dashboard/  # Tela inicial e métricas
│   ├── loans/      # Empréstimos e parcelas
│   ├── payments/   # Cobranças e pagamentos
│   ├── reports/    # Relatórios e exportação
│   ├── settings/   # Configurações do app
│   ├── splash/     # Tela de carregamento
│   └── update/     # Sistema OTA
├── services/       # Banco de dados, Supabase, sync, notificações
└── shared/         # Widgets e utilitários reutilizáveis
```

## Releases

As versões são distribuídas via **GitHub Releases**. O app verifica automaticamente se há uma versão nova disponível e notifica o usuário com uma bolinha amarela no ícone de configurações.

Veja as [releases disponíveis →](../../releases)

## Desenvolvido por

**Bruno Maykon** · [www.firmis.com.br](https://www.firmis.com.br)
