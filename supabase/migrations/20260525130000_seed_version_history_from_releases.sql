-- Histórico inicial alinhado às GitHub Releases (somente changelog; sem APK antigo)
-- https://github.com/firmisbr/facilite-plus/releases

insert into public.app_version_history (version, build, changelog, released_at)
values
  (
    '1.2.0',
    6,
    '- Folga aos domingos em empréstimos diários (Configurações > Ajustes)' || E'\n' ||
    '- Cronograma seg–sáb; empréstimos já cadastrados recalculam na hora',
    '2026-05-24T20:47:16Z'::timestamptz
  ),
  (
    '1.1.0',
    5,
    '- Central de Suporte: bugs, sugestoes e chamados' || E'\n' ||
    '- Painel admin para responder e alterar status' || E'\n' ||
    '- Sync offline-first e mensagens em tempo real',
    '2026-05-24T20:28:50Z'::timestamptz
  ),
  (
    '1.0.4',
    4,
    '- Logo compacta nos lembretes de cobrança (Android)' || E'\n' ||
    '- Marca colorida no cartão da notificação',
    '2026-05-23T14:13:53Z'::timestamptz
  ),
  (
    '1.0.3',
    3,
    '- Config: versao instalada na conta; toque abre Atualizacoes; tela de atualizacoes com notas da versao atual e da nova' || E'\n' ||
    '- Sync automatico (abrir app, rede, restore backup); bolinha vermelha na aba Config se houver envio pendente' || E'\n' ||
    '- Backup: contagem atualiza apos pagamento, sincronizar ou restaurar — sem reiniciar' || E'\n' ||
    '- Emprestimos: selecionar varios e excluir; dialog no padrao do app; animacao ao excluir (sem tela emprestimo nao encontrado)',
    '2026-05-23T13:58:22Z'::timestamptz
  ),
  (
    '1.0.2',
    2,
    '- Relatórios: gráfico Recebido vs. a receber na aba Por período (conforme o filtro escolhido)' || E'\n' ||
    '- Relatórios: na Visão geral, o gráfico da carteira deixa claro que é o total da carteira (rótulo Carteira)' || E'\n' ||
    '- Correção: filtro Esta semana passa a incluir o domingo da semana atual' || E'\n' ||
    '- Correção: em Personalizar datas, o campo Até aceita datas futuras para ver o que ainda vai vencer no período',
    '2026-05-23T13:11:33Z'::timestamptz
  ),
  (
    '1.0.1',
    1,
    'Teste do sistema OTA',
    '2026-05-23T03:47:45Z'::timestamptz
  )
on conflict (version, build) do update set
  changelog = excluded.changelog,
  released_at = excluded.released_at;
