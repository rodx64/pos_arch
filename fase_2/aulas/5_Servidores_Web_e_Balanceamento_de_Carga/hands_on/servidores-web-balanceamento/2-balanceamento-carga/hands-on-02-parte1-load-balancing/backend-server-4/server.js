const http = require('http');

const SLOW_MS = 5000; // 5s para segurar a conexão só na rota principal

const server = http.createServer((req, res) => {
  // SOMENTE a rota principal é lenta neste backend
  if (req.method === 'GET' && (req.url === '/' || req.url === '/index.html')) {
    setTimeout(() => {
      res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('backend-4: resposta LENTA (5s) na rota principal /\n');
    }, SLOW_MS);
    return;
  }

  // (opcional) checagem rápida
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('ok\n');
    return;
  }

  // Demais rotas rápidas
  res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end('backend-4: resposta rápida nas outras rotas\n');
});

server.listen(80, () => console.log('backend-4 ouvindo na porta 80 ("/" lento)'));
