# SKYLOONG 4.0 Screen — Console Web (não oficial)

Frontend alternativo, em **um único arquivo HTML**, para o teclado **SKYLOONG 4.0 Screen**
(teclado com tela LCD embutida e Wi‑Fi). Substitui a interface de fábrica servida pelo
próprio teclado em `http://<ip-do-teclado>/`, falando **diretamente** com a API HTTP do
dispositivo — sem build, sem servidor, sem dependências para instalar.

> ⚠️ Projeto independente, obtido por **engenharia reversa** da UI oficial. Não é afiliado
> à SKYLOONG. Use por sua conta e risco, apenas no seu próprio dispositivo.

---

## Sumário

- [O que é o dispositivo](#o-que-é-o-dispositivo)
- [Como usar](#como-usar)
- [Funcionalidades](#funcionalidades)
- [Solução de problemas](#solução-de-problemas)
- [API do dispositivo (engenharia reversa)](#api-do-dispositivo-engenharia-reversa)
- [Como a conversão de vídeo funciona](#como-a-conversão-de-vídeo-funciona)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Notas técnicas](#notas-técnicas)

---

## O que é o dispositivo

O **SKYLOONG 4.0 Screen** é um teclado mecânico com uma pequena tela **LCD 320×240 (4:3)**
e conectividade Wi‑Fi. Ele roda um **servidor HTTP embarcado** que entrega uma SPA
(Vue + Tailwind + axios + ffmpeg.wasm) para configurar a tela: enviar imagens/vídeos,
ativar widgets (clima, velocidade de digitação, info do sistema), trocar tema, etc.

Características relevantes do servidor embarcado:

| Item | Valor |
|---|---|
| Resolução da tela | **320 × 240** (4:3) |
| Armazenamento | ~**5,8 MB** (`total` ≈ 6.094.848 bytes) |
| CORS | aberto (`Access-Control-Allow-Origin: *`) |
| Conexões | **1 por vez** (`Connection: close`) — requisições precisam ser serializadas |
| IP em modo estação | definido pela sua rede (ex.: `192.168.100.11`) |
| IP em modo AP (fallback) | `192.168.4.1` (portal cativo em `/wifi`) |

---

## Como usar

1. Garanta que seu PC está na **mesma rede Wi‑Fi** que o teclado.
2. Descubra o IP do teclado (aparece na própria tela / no roteador). Padrão deste projeto: `192.168.100.11`.
3. **Sirva a página por `http://`** (recomendado) — dê **duplo clique em `serve.bat`**.
   Ele inicia o `server.py` (que habilita o **banco SQLite** de miniaturas/apelidos) e abre
   `http://localhost:8000/skyloong-ui.html` no navegador.
   Alternativa manual, na pasta do projeto:
   ```bash
   python server.py            # com banco SQLite (recomendado)
   # ou, sem banco (miniaturas só no navegador):
   # python -m http.server 8000
   # depois abra http://localhost:8000/skyloong-ui.html
   ```
   > Dica: o servidor escuta em `0.0.0.0`, então dá pra abrir do **celular** na mesma rede:
   > `http://<ip-do-pc>:8000/skyloong-ui.html`.
4. No topo da página, ajuste o **IP** do teclado se necessário e clique em **Conectar**.

> ### Por que não abrir o arquivo direto (`file://`)?
> Abrindo por `file://` a página tem origem "nula/opaca", e o navegador **bloqueia** a
> criação de Web Workers e o `import()` de módulos cross‑origin — é o que quebra a
> **conversão de vídeo** (erro do worker). Servindo por `http://` a página ganha uma origem
> real e tudo funciona. O Dashboard e a maioria das ações até funcionam via `file://`,
> mas a conversão de vídeo **não** — por isso prefira `serve.bat`.
>
> **Nunca** use `https://`: o teclado é `http://` e o navegador bloquearia por
> "conteúdo misto" (mixed content). Use `http://` (localhost) ou, no limite, `file://`.

O endereço informado fica salvo no `localStorage` para as próximas aberturas.

---

## Funcionalidades

| Aba | O que faz |
|---|---|
| **Dashboard** | Estado do dispositivo (IP, SSID, fuso, idioma), status de cada widget, **barra de uso de memória** e prévia (com apelido) da imagem ativa. |
| **Imagens** | Upload com **reescala automática para 320×240 JPEG** (corte _cover_, centralizado); galeria com **miniatura + apelido editável** por arquivo; alternar **Imagem fixa ↔ Slideshow**; ajustar o **intervalo** (2–12 s); ligar/desligar; definir qual imagem aparece na tela; apagar. |
| **Vídeo / GIF** | Upload de vídeo (mp4/webm/mkv/avi) ou GIF, **convertido no próprio navegador** (ffmpeg.wasm) para o formato da tela; galeria com **miniatura (1º quadro) + apelido**; remoção; liga/desliga o app de vídeo. |
| **Apps da Tela** | Toggles dos widgets exibidos no teclado: **Clima**, **APS** (velocidade de digitação), **Info do sistema** (CPU/RAM), **Vídeo/GIF** e **Slideshow**. |
| **WiFi** | Escaneia redes próximas (com **força de sinal**) e envia novas credenciais para o teclado. |
| **Configurações** | **Tema** (0/1/2), **fuso horário**, **cidade** + **chave da API de clima** e **texto personalizado** exibido na tela. |

Detalhes de robustez:

- **Fila serial de requisições** — respeita o limite de 1 conexão do servidor embarcado.
- **Heartbeat** a cada 8 s — detecta queda/volta da conexão e reconecta sozinho.
- **Miniaturas + apelidos em SQLite** — o teclado salva tudo com nome numérico
  (ex.: `1781402560644.mpeg`) e **não devolve** o conteúdo dos arquivos. Para você saber
  "quem é quem", o `server.py` guarda, por arquivo, uma **miniatura** e um **apelido** em um
  banco **SQLite** (veja [Banco de thumbnails](#banco-de-thumbnails-sqlite)). Ao **apagar** um
  arquivo no teclado, o registro é removido do banco junto. Sem o `server.py` (ex.: aberto via
  `file://`), cai para `localStorage` automaticamente.

---

## Solução de problemas

### `Refused to cross-origin redirects of the top-level worker script`
Ocorria ao carregar o motor de conversão de vídeo (ffmpeg.wasm). O `new Worker(...)` apontava
para uma URL do CDN que **redireciona** para outra origem, e o navegador **recusa redirect
cross-origin em script de worker**.

**Corrigido (parte 1):** o worker do ffmpeg agora é sempre carregado como **`blob:`** — o `fetch()`
segue o redirect internamente e o `Worker` recebe um blob _same-origin_, sem redirect.
O console tenta primeiro os arquivos do **próprio teclado** (`/ffmpeg.js` + `/assets/worker-*.js`)
e, se falhar, cai para o **unpkg com versão fixada**.

**Causa raiz (parte 2):** o erro aparece principalmente quando a página é aberta por
**`file://`**, onde o navegador bloqueia Workers e imports cross‑origin. **Solução:** rode por
**`http://`** (use o **`serve.bat`** / `python -m http.server`). Veja [Como usar](#como-usar).

### As requisições falham / "offline"
- Confirme o **IP** no topo e que está na **mesma rede**.
- Abra por **`file://`** ou **`http://`** (nunca `https://`).
- A conversão de vídeo precisa de **internet** (baixa o core do ffmpeg.wasm do unpkg) — o resto
  funciona **só com a rede local**.

### As miniaturas não aparecem para imagens antigas
Esperado: o dispositivo não serve os arquivos de volta. Só há prévia das imagens enviadas
por este mesmo navegador.

---

## API do dispositivo (engenharia reversa)

Base = `http://<ip>`. Todos os caminhos são relativos ao IP do teclado.

### Leitura
| Método | Endpoint | Retorno |
|---|---|---|
| `GET` | `/info` | `{mode, ssid, ip, theme, aps_enable, weather_enable, sysinfo_enable, gif_enable, jpg_enable, time_roll, jpg_mode, jpg_file, timezone, language, keytone, keytone_file}` |
| `GET` | `/config.json` | `{ip, port, weather, city, userdata}` |
| `GET` | `/list?dir=/` | `{size: usado, total: bytes, data: [{type, name, size}]}` |
| `GET` | `/scan_networks` | `{networks: [{ssid, rssi}]}` |

### Escrita / configuração
| Método | Endpoint | Observações |
|---|---|---|
| `POST` | `/config_wifi` | `multipart/form-data` com campos `ssid` e `password` |
| `POST` | `/config_app_weather?enable=<bool>` | liga/desliga widget de clima |
| `POST` | `/config_app_aps?enable=<bool>` | liga/desliga APS (velocidade) |
| `POST` | `/config_app_sysinfo?enable=<bool>` | liga/desliga info de CPU/RAM |
| `POST` | `/config_app_gif?enable=<bool>` | liga/desliga app de vídeo/GIF |
| `POST` | `/config_app_jpg?enable=<bool>&time_roll=<2000..12000>&jpg_mode=roll\|fixed&jpg_file=<nome>` | controla o slideshow |
| `POST` | `/config_theme?theme=0\|1\|2` | tema da tela |
| `POST` | `/config_timezone?timezone=<n>` | fuso (UTC+n) |
| `POST` | `/config_keytone?keytone=<0..4>&keytone_file=<nome>` | som das teclas |
| `POST` | `/config.json` | corpo JSON `{ip, port, weather, city, userdata}` |
| `POST` | `/edit` | upload de arquivo — `multipart/form-data`, campo **`data`** = File |
| `DELETE` | `/edit?filename=/<nome>` | apaga um arquivo |

### Pegadinhas importantes
- O servidor **não serve de volta** os arquivos enviados: qualquer caminho desconhecido
  responde **302 → `http://192.168.4.1/wifi`** (portal). Apenas os **assets de build**
  (`/index.js`, `/index.css`, `/ffmpeg.js`, `/assets/*.js`, `*.svg`, `*.png`, `favicon.ico`)
  são servidos.
- O servidor aceita **uma conexão por vez** — dispare as requisições em série.
- `enable` é enviado como string (`true`/`false`).
- Limites: imagem vira **JPEG 320×240**; arquivo de som de tecla **≤ 300 KB** (`.wav`/`.mp3`).

---

## Como a conversão de vídeo funciona

Igual à UI de fábrica: o vídeo é transcodificado **no navegador** com **ffmpeg.wasm** para
**MPEG‑1**, no tamanho da tela. Comando equivalente:

```
ffmpeg -i input \
  -vf "scale=w=320:h=240:force_original_aspect_ratio=decrease,fps=23.98" \
  -c:v mpeg1video -b:v 500k -maxrate 800k -an -f mpeg out.mpeg
```

- A classe `FFmpeg` (ESM) e o **worker** vêm do **próprio teclado** (`/ffmpeg.js`,
  `/assets/worker-*.js`); fallback para `unpkg @ffmpeg/ffmpeg@0.12.15`.
- O **core** (`ffmpeg-core.js` + `.wasm`) vem de `unpkg @ffmpeg/core@0.12.6/dist/esm`.
- Tudo é carregado via **`blob:`** para evitar bloqueios de worker cross‑origin.
- O resultado (`.mpeg`) é enviado para o teclado via `POST /edit`.

---

## Banco de thumbnails (SQLite)

O `server.py` usa **apenas a biblioteca padrão do Python** (`http.server` + `sqlite3`) — **nada
para instalar**. Ele serve os arquivos estáticos **e** expõe uma pequena API para guardar, por
arquivo do teclado, uma **miniatura** (data URL JPEG) e um **apelido**. Assim a galeria deixa de
mostrar só `1781402560644.mpeg` e passa a mostrar a imagem + o nome que você deu.

**Banco:** `thumbnails.sqlite` (criado ao lado do `server.py`, em modo WAL). Não vai pro git.

**Tabela:**

```sql
CREATE TABLE thumbs(
  name  TEXT PRIMARY KEY,  -- nome do arquivo no teclado (ex.: 1781402560644.mpeg)
  label TEXT,              -- apelido definido por você
  type  TEXT,              -- image | video | gif
  size  INTEGER,           -- bytes
  thumb TEXT,              -- miniatura em data URL (JPEG)
  ts    INTEGER            -- timestamp da última atualização
);
```

**API (mesma origem da página):**

| Método | Endpoint | Função |
|---|---|---|
| `GET` | `/api/health` | checagem (`{"ok":true}`) — o frontend usa para detectar o banco |
| `GET` | `/api/thumbs` | devolve `{ "<name>": {label,type,size,thumb,ts}, ... }` |
| `PUT`/`POST` | `/api/thumb` | upsert `{name, label?, type?, size?, thumb?}` (campos ausentes são preservados) |
| `DELETE` | `/api/thumb?name=...` | remove o registro |

**Sincronização:** ao enviar uma imagem/vídeo, o frontend gera a miniatura e faz `PUT`; ao
**apagar** o arquivo no teclado, faz `DELETE`. Renomear (editar o apelido na galeria) faz um
`PUT` só com o `label`. Se o `server.py` não estiver no ar (ex.: página aberta via `file://`),
tudo isso cai para o `localStorage` do navegador — sem erro.

---

## Estrutura do projeto

```
skyloong/
├── skyloong-ui.html      ← o console (a página principal)
├── server.py             ← servidor local + API de thumbnails em SQLite (stdlib)
├── serve.bat             ← inicia o server.py e abre o navegador (recomendado)
├── thumbnails.sqlite     ← banco gerado em runtime (ignorado pelo git)
├── README.md             ← este documento
└── reverse/              ← artefatos da engenharia reversa (referência)
    ├── index.js          ← bundle original do teclado (minificado)
    ├── index.pretty.js   ← mesmo bundle, formatado (legível)
    ├── index.css         ← CSS original
    ├── ffmpeg.js         ← wrapper ESM do @ffmpeg/ffmpeg do teclado
    └── dev-worker.js     ← worker do ffmpeg servido pelo teclado
```

---

## Notas técnicas

- **Sem build / sem dependências**: HTML + CSS + JS _vanilla_ (ES modules nativos do navegador).
- **Tema escuro**, responsivo, com notificações (toasts) e drag‑and‑drop.
- O IP base é detectado automaticamente quando a página é **servida pelo próprio teclado**
  (mesma origem); caso contrário usa o IP configurado (padrão `192.168.100.11`).
- Possível evolução: **hospedar este HTML no próprio teclado** (via `POST /edit`) para
  substituir a UI de fábrica e rodar tudo _same-origin_ — porém é arriscado (pode quebrar a
  interface original) e deve ser feito com cautela/backup.

---

### Licença
Uso pessoal/educacional. "SKYLOONG" é marca de seus respectivos donos; este projeto não é oficial.
