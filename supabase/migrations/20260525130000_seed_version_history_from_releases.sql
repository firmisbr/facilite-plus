-- Histórico inicial alinhado às GitHub Releases (somente changelog; sem APK antigo)
-- https://github.com/firmisbr/facilite-plus/releases

insert into public.app_version_history (version, build, changelog, released_at)
values
  (
    '1.2.0',
    6,
    E'- Folga aos domingos em empr\u00e9stimos di\u00e1rios (Configura\u00e7\u00f5es > Ajustes)\n- Cronograma seg\u2013s\u00e1b; empr\u00e9stimos j\u00e1 cadastrados recalculam na hora',
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
    E'- Logo compacta nos lembretes de cobran\u00e7a (Android)\n- Marca colorida no cart\u00e3o da notifica\u00e7\u00e3o',
    '2026-05-23T14:13:53Z'::timestamptz
  ),
  (
    '1.0.3',
    3,
    E'- Config: versao instalada na conta; toque abre Atualizacoes; tela de atualizacoes com notas da versao atual e da nova\n- Sync automatico (abrir app, rede, restore backup); bolinha vermelha na aba Config se houver envio pendente\n- Backup: contagem atualiza apos pagamento, sincronizar ou restaurar \u2014 sem reiniciar\n- Emprestimos: selecionar varios e excluir; dialog no padrao do app; animacao ao excluir (sem tela emprestimo nao encontrado)',
    '2026-05-23T13:58:22Z'::timestamptz
  ),
  (
    '1.0.2',
    2,
    E'- Relat\u00f3rios: gr\u00e1fico Recebido vs. a receber na aba Por per\u00edodo (conforme o filtro escolhido)\n- Relat\u00f3rios: na Vis\u00e3o geral, o gr\u00e1fico da carteira deixa claro que \u00e9 o total da carteira (r\u00f3tulo Carteira)\n- Corre\u00e7\u00e3o: filtro Esta semana passa a incluir o domingo da semana atual\n- Corre\u00e7\u00e3o: em Personalizar datas, o campo At\u00e9 aceita datas futuras para ver o que ainda vai vencer no per\u00edodo',
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
