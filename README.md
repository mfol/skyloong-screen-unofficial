# SKYLOONG 4.0 Screen — Console Web (não oficial)

**🌐 Idioma / Language:** **Português** · [English](README.en.md)

Frontend alternativo, em **um único arquivo HTML**, para o teclado **SKYLOONG 4.0 Screen**
(teclado com tela LCD embutida e Wi‑Fi). Substitui a interface de fábrica servida pelo
próprio teclado em `http://<ip-do-teclado>/`, falando **diretamente** com a API HTTP do
dispositivo — sem build, sem servidor, sem dependências para instalar.

> ⚠️ Projeto independente, obtido por **engenharia reversa** da UI oficial. Não é afiliado
> à SKYLOONG. Use por sua conta e risco, apenas no seu próprio dispositivo.

---

## Sumário

- [O que é o dispositivo](#o-que-é-o-dispositivo)
  - [Hardware testado](#hardware-testado)
- [Como usar](#como-usar)
  - [Configurar o Wi‑Fi pela tela (V4)](#configurar-o-wi-fi-pela-tela-v4)
- [Funcionalidades](#funcionalidades)
- [Solução de problemas](#solução-de-problemas)
- [API do dispositivo (engenharia reversa)](#api-do-dispositivo-engenharia-reversa)
- [Por dentro: ESP32‑S3 e console serial](#por-dentro-esp32s3-e-console-serial)
  - [Trocar feature da tela pela serial](#trocar-feature-da-tela-pela-serial)
  - [Auto‑sleep e keep‑awake](#auto-sleep-e-keep-awake)
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
| IP em modo estação | definido pela sua rede (ex.: `192.168.100.11` — só exemplo; o seu será diferente) |
| IP em modo AP (fallback) | `192.168.4.1` (portal cativo em `/wifi`) |

### Hardware testado

Este projeto foi **testado** com o **SKYLOONG GK104 Pro** (Teclado Mecânico Sem Fio
Bluetooth, full‑size 100%, retroiluminação RGB, keycaps PBT, switches hot‑swap de baixo
ruído), com a **versão da tela na 4.0**.

> 💡 **Outras versões de tela:** a configuração de Wi‑Fi pela própria tela
> (veja [Configurar o Wi‑Fi pela tela](#configurar-o-wi-fi-pela-tela-v4)) e este console
> **talvez funcionem em telas mais antigas** (ex.: a 3.0). **Não tenho como testar**, pois só
> possuo a **4.0** — se você testar em outra versão, abra uma _issue_ contando o resultado.

---

## Como usar

1. Garanta que seu PC está na **mesma rede Wi‑Fi** que o teclado.
2. Descubra o IP do teclado (aparece na própria tela / no roteador). O valor `192.168.100.11`
   que aparece neste projeto é **só um exemplo** (foi o IP que a rede do autor atribuiu) — **o
   seu será diferente**. Veja [Configurar o Wi‑Fi pela tela](#configurar-o-wi-fi-pela-tela-v4)
   para descobrir o seu na seção **Servidor Web** da tela.
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

### Configurar o Wi‑Fi pela tela (V4)

Antes de conseguir falar com o teclado pela rede, ele precisa estar **conectado ao seu
Wi‑Fi**. Isso é feito **direto na telinha do teclado**, sem PC:

1. **Abra o menu da tela:** pressione e segure ao mesmo tempo **FN + Menu** (teclas à direita
   do **FN**, ou entre **FN** e **Ctrl**) por **pelo menos ~3 segundos**, com a tela LCD montada/ligada.
2. No primeiro item, pressione **Enter** no botão de **digitalização (scan)** para procurar redes Wi‑Fi.
3. Selecione sua rede e **digite a senha** usando as **setas** (para escolher caracteres) e **Enter** (para confirmar).
4. Depois de conectar, pressione a **seta para baixo** algumas vezes até ver a seção **Servidor Web** — ali aparece o **endereço IP** do teclado (ex.: `192.168.xx.yy`).
5. Use esse IP no campo do topo deste console (ou na barra de endereço do navegador) para acessar o teclado.

> Em algumas versões da tela, para **exibir** uma foto/vídeo enviado basta pressionar **FN + a
> tecla** correspondente na própria tela.

> 🙏 **Créditos:** o passo a passo de configuração do Wi‑Fi pela tela foi baseado no relato do
> usuário **AliExpress Shopper** (avaliação de 04/jul/2025) no anúncio do produto:
> <https://pt.aliexpress.com/item/1005006890321000.html>. Obrigado por documentar o processo!

---

## Funcionalidades

| Aba | O que faz |
|---|---|
| **Dashboard** | Estado do dispositivo (IP, SSID, fuso, idioma), status de cada widget, **barra de uso de memória** e prévia (com apelido) da imagem ativa. |
| **Imagens** | Upload com **reescala automática para 320×240 JPEG** (corte _cover_, centralizado); galeria com **miniatura + apelido editável** por arquivo; alternar **Imagem fixa ↔ Slideshow**; ajustar o **intervalo** (2–12 s); ligar/desligar; definir qual imagem aparece na tela; apagar. |
| **Vídeo / GIF** | Upload de vídeo (mp4/webm/mkv/avi) **ou GIF**, **convertido no próprio navegador** (ffmpeg.wasm) para o formato da tela (**MPEG‑1 320×240**, _cover_: escala até preencher e **corta** o excesso centralizado, então fontes não‑4:3 não esticam). O tamanho gerado é **validado contra a memória livre** antes do envio. Galeria com **miniatura (1º quadro) + apelido**; remoção; liga/desliga o app de vídeo. |
| **Apps da Tela** | Toggles dos widgets exibidos no teclado: **Clima**, **APS** (velocidade de digitação), **Info do sistema** (CPU/RAM), **Vídeo/GIF** e **Slideshow**. |
| **WiFi** | Escaneia redes próximas (com **força de sinal**) e envia novas credenciais para o teclado. |
| **Configurações** | **Tema** (0/1/2), **fuso horário**, **cidade** + **chave da API de clima** e **texto personalizado** exibido na tela. |
| **Trocar feature (serial)** | Botão na barra de conexão que **avança a tela para a próxima funcionalidade** (GIF, relógio, clima, APS, QR/Wi‑Fi…) por um comando na **porta serial (COM)** da tela. Útil até para **ligar o Wi‑Fi** (basta navegar até a tela do QR). Veja [Por dentro: ESP32‑S3 e console serial](#por-dentro-esp32s3-e-console-serial). |

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

### `DELETE ... blocked by CORS policy: Redirect is not allowed for a preflight request`
Apagar usava `DELETE` direto no teclado a partir de `http://localhost:8000` (origem diferente).
Métodos como `DELETE` disparam um **preflight `OPTIONS`**, e o servidor embarcado responde o
preflight com um **redirect** (→ portal `/wifi`) — o navegador proíbe redirect em preflight.
(Adicionar não dava erro porque `POST multipart/form-data` é "simple request", sem preflight.)
O app de fábrica não sofre isso por rodar **na mesma origem** do teclado.

**Corrigido:** quando o `server.py` está rodando, **todas** as chamadas ao teclado passam por ele
(`/dev/<host>/<path>`). A página fala só com `localhost` (mesma origem ⇒ sem CORS/preflight) e o
Python repassa ao teclado. Sem o `server.py`, as chamadas vão direto (o `DELETE` pode falhar).

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

## Por dentro: ESP32‑S3 e console serial

Investigando o teclado pela **porta USB serial** descobrimos como a tela funciona por dentro
— e isso abriu um **canal de controle novo**, que não depende da rede.

### A "telinha" é um módulo ESP32‑S3 destacável

- A tela é um **módulo independente** que encaixa no teclado por **12 pinos dourados** (pogo):
  **alimentação + um link UART** entre o teclado e a tela.
- **O Wi‑Fi está na TELA**, não no teclado. O cérebro dela é um **ESP32‑S3** (8 MB de PSRAM,
  codec de áudio ES8311) — é ele que roda o servidor HTTP, os GIFs, o relógio, os widgets, etc.
  O teclado em si é só a matriz de teclas, com seu próprio chip.
- A tela tem uma **USB‑C própria**. Plugada no PC, ela aparece como uma **porta serial**
  (ex.: `COM6`): `USB\VID_303A&PID_1001` = o **USB‑Serial‑JTAG** embutido do ESP32‑S3.

### Firmware open‑source

O firmware da tela é **aberto**: <https://github.com/JZ-Skyloong/esp32_screen_module>
(ESP‑IDF + Arduino + LVGL, sistema de arquivos **LittleFS**, projeto `GK87‑Screen`). Foi lendo
esse código que confirmamos os detalhes abaixo — inclusive que **os arquivos de mídia ficam em
`/littlefs/<número>.mpeg`** (o tal "nome numérico").

### O console serial é também um controle remoto da tela

A porta serial (115200 8N1) cospe os **logs do ESP‑IDF** ao vivo (ótimo pra ver a tela conectar
e qual IP ela pegou). Mas ela é **também um canal de entrada**: o firmware (tarefa
`debug_USB_UART`) mapeia **um caractere → uma tecla** da interface — os mesmos comandos que o
teclado manda pelos 12 pinos:

| Caractere enviado | Ação na tela |
|---|---|
| `` ` `` (crase) | **troca de app/feature** (GIF → relógio → clima → APS → QR/Wi‑Fi → …) |
| `/` | entra/sai do **modo Configuração** |
| `w` `a` `s` `d` | setas ↑ ← ↓ → |
| `Enter` | confirmar / clicar |

> ⚠️ **Só leitura/controle — nunca flashamos nada.** Abrir a porta **pode reiniciar** a tela
> (comportamento do USB‑Serial‑JTAG), mas é inofensivo (só um reboot).

Para **apenas monitorar** os logs: `reverse/serial-listen.ps1` (somente leitura; grava em
`reverse/com6.log`). Uso: `pwsh -File reverse\serial-listen.ps1`.

### Trocar feature da tela pela serial

O console tem um botão **`↻ Trocar feature`** (na barra de conexão, ao lado de um campo de
**porta COM**). Cada clique manda **um `` ` ``** pela serial e a tela **avança para a próxima
funcionalidade**. Assim dá pra navegar entre as telas — inclusive chegar na **tela do QR**, que
é o que **liga o Wi‑Fi** da tela.

Como o **navegador não acessa porta COM**, quem fala com a serial é o **`server.py`** (via
`serial-ctl.ps1`, usando `System.IO.Ports` do .NET — zero instalação). Endpoints:

| Método | Endpoint | Função |
|---|---|---|
| `GET` | `/api/serial/ports` | lista as portas COM disponíveis |
| `POST` | `/api/serial/switch` | manda **um `` ` ``** (troca de feature); responde `{ok, info}` com o app atual (ex.: `GIF`, `app 2`) |
| `POST` | `/api/serial/force` | manda `` ` `` + `/` e lê o log tentando extrair o **IP** que a tela pegou na LAN |
| `POST` | `/api/serial/exit` | manda `/` (sai do modo Configuração, sem reboot) |
| `POST` | `/api/serial/reset` | dá um **reset** na tela (pulso de RTS = reboot a quente); usado pelo keep‑awake |
| `POST` | `/api/serial/wakegif` | **reset + navega até o GIF** (a tela volta mostrando o GIF após o reboot) |

> 📌 **Requer a USB‑C da TELA plugada neste PC.** A porta `COMx` só existe quando a tela está
> ligada ao PC por USB — se só o **teclado** estiver conectado, a COM da tela **não aparece**
> (são dispositivos USB separados). O botão só é exibido quando o `server.py` responde em
> `/api/serial/ports`. A porta escolhida fica salva no `localStorage`.

### Auto‑sleep e keep‑awake

Pelo firmware (`task_powerOFF`), a tela entra em **deep sleep após ~10 min** sem o teclado
"conversar" com ela pelos 12 pinos. Como o wake é amarrado ao **pino da UART do teclado**,
**com a tela destacada (só no USB) ela dorme em 10 min — e a porta `COMx` desaparece** (o deep
sleep desliga o periférico USB). As teclas que mandamos pela USB **não** reiniciam esse contador.

Para uso prolongado com a tela no USB, o console tem um checkbox **`keep‑awake`**: a cada
**~9 min** ele dá um **reset** na tela pela serial (pulso de RTS = reboot a quente), o que
reinicia o contador de sono. Cada reboot **volta mostrando o GIF** (ação `wakegif` = reset +
navegação automática até o app de GIF).

> ⚠️ É um **reboot** (anima boot + reconecta o WiFi a cada ciclo) — mas **não desgasta** o
> ESP32: resetar é eletricamente inofensivo e o boot é **só leitura na flash**. E **não acorda
> se já dormiu** (sem porta COM, não há o que resetar) — então **ligue o keep‑awake logo após
> plugar a USB‑C**, com a tela ainda acordada.

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

### Proxy para o teclado

Além das thumbnails, o `server.py` também atua como **proxy** para o teclado:

| Método | Endpoint | Função |
|---|---|---|
| `* (qualquer)` | `/dev/<host>/<path>` | repassa a requisição para `http://<host>/<path>` |

O frontend, quando detecta o servidor local, manda **todas** as chamadas do device por aqui
(ex.: `/dev/192.168.100.11/edit?...`). Como a página passa a falar só com a **mesma origem**
(`localhost`), o navegador não dispara preflight de CORS — o que resolve o erro do `DELETE`
(veja [Solução de problemas](#delete--blocked-by-cors-policy-redirect-is-not-allowed-for-a-preflight-request)).

---

## Estrutura do projeto

```
skyloong/
├── skyloong-ui.html      ← o console (a página principal)
├── server.py             ← servidor local + API de thumbnails (SQLite) + serial (stdlib)
├── serial-ctl.ps1        ← controle da tela pela serial (COM) usado pelo server.py
├── serve.bat             ← inicia o server.py e abre o navegador (recomendado)
├── thumbnails.sqlite     ← banco gerado em runtime (ignorado pelo git)
├── README.md             ← este documento (português)
├── README.en.md          ← versão em inglês
└── reverse/              ← artefatos da engenharia reversa (referência)
    ├── index.js          ← bundle original do teclado (minificado)
    ├── index.pretty.js   ← mesmo bundle, formatado (legível)
    ├── index.css         ← CSS original
    ├── ffmpeg.js         ← wrapper ESM do @ffmpeg/ffmpeg do teclado
    ├── dev-worker.js     ← worker do ffmpeg servido pelo teclado
    └── serial-listen.ps1 ← monitor (somente leitura) do console serial da tela
```

---

## Notas técnicas

- **Sem build / sem dependências**: HTML + CSS + JS _vanilla_ (ES modules nativos do navegador).
- **Tema escuro**, responsivo, com notificações (toasts) e drag‑and‑drop.
- O IP base é detectado automaticamente quando a página é **servida pelo próprio teclado**
  (mesma origem); caso contrário usa o IP que você configurar no topo da página (o
  `192.168.100.11` que aparece pré‑preenchido é **só um exemplo** — troque pelo seu).
- Possível evolução: **hospedar este HTML no próprio teclado** (via `POST /edit`) para
  substituir a UI de fábrica e rodar tudo _same-origin_ — porém é arriscado (pode quebrar a
  interface original) e deve ser feito com cautela/backup.

---

### Licença

Distribuído sob a licença **MIT** — veja [LICENSE](LICENSE).

O software é fornecido **"COMO ESTÁ", sem garantia**, e o autor **não assume
nenhuma responsabilidade** por danos, perdas ou inutilização do dispositivo
decorrentes do uso. Use por sua conta e risco, apenas no seu próprio aparelho.
"SKYLOONG" é marca de seus respectivos donos; este projeto é independente e
**não oficial**.
