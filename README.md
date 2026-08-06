# TwinForge — Landing (Claude Meetup)

Landing de apresentação do [TwinForge](https://docs.twinforge.webjump.ai/) sob a identidade AI/R.

## Rodar

Não há build step. Abra `index.html` no navegador, ou sirva a pasta:

```sh
python3 -m http.server 8000
```

## Estrutura

```
index.html      página completa, CSS inline
assets/
  air-logo.svg        logo AI/R (header, 99×32)
  air-logo-full.svg   logo AI/R (footer, 164×79)
  favicon.svg         símbolo O₂
  fonts/              Roboto Mono — Light, Regular, Medium, Bold
docs/superpowers/specs/   spec de design
```

## Tipografia

- **Corpo:** Neue Haas Grotesk Display Pro → fallback `Helvetica Neue`.
  A fonte é licenciada e **não** é distribuída neste repo.
- **Títulos e dados:** Roboto Mono (Apache 2.0), servida localmente
  a partir de `assets/fonts/` para a página funcionar offline.

## Cor

Paleta primária AI/R em grayscale. Um único acento: `#D7EF25`, a cor do
Forge AI na paleta de plataformas. O acento é reservado para o que um gate
determinístico confirmou — `exit 0`, estados de verificação, heartbeat — e
para a ação primária. Não usar como decoração.

## Slot de inscrição

O botão de inscrição ainda não existe. Três CTAs estão marcados com
`data-signup` e a classe `.js-signup`, apontando hoje para as docs:

- header
- hero
- seção de fecho

Para ligar a página de inscrição, trocar `href` **e** rótulo nos três pontos.

## Faixa do evento

O bloco `[data-event-banner]` no topo diz "Apresentado no Claude Meetup".
Remover essa `<div>` reaproveita a landing fora do contexto do meetup.

## Referência

O design está documentado em
[`docs/superpowers/specs/2026-08-06-twinforge-landing-design.md`](docs/superpowers/specs/2026-08-06-twinforge-landing-design.md).
