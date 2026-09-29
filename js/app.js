'use strict';

document.addEventListener('click', async (event) => {
  const copiar = event.target.closest('[data-copy]');
  if (copiar) {
    const texto = document.getElementById(copiar.dataset.copy)?.innerText || '';
    const original = copiar.textContent;
    try {
      await navigator.clipboard.writeText(texto);
      copiar.textContent = 'Copiado';
    } catch {
      copiar.textContent = 'Cópia indisponível';
    }
    setTimeout(() => { copiar.textContent = original; }, 1400);
    return;
  }

  const botao = event.target.closest('[data-run]');
  if (!botao) return;
  const run = botao.dataset.run;
  let destino;
  let texto;

  if (run === '1') {
    destino = 'saida-1';
    const produtos = [...document.querySelectorAll('input[name="produto-1"]:checked')].map((item) => item.value);
    if (!produtos.length) {
      texto = 'Selecione ao menos um produto.';
    } else {
      const cidade = document.getElementById('cidade-1').value;
      const { subtotal, frete, total } = PW2.calculaValorTotalDaCompra(produtos, cidade);
      const moeda = (valor) => `R$ ${valor.toFixed(2).replace('.', ',')}`;
      texto = `Subtotal: ${moeda(subtotal)} | Frete: ${moeda(frete)} | Total: ${moeda(total)}`;
    }
  } else if (run === '2') {
    destino = 'saida-2';
    const entrada = document.getElementById('numeros-2').value.trim();
    const partes = entrada ? entrada.split(',').map((valor) => valor.trim()) : [];
    if (!partes.length || partes.some((valor) => !/^\d+$/.test(valor))) {
      texto = 'Informe inteiros positivos separados por vírgula.';
    } else {
      const numeros = partes.map(Number);
      texto = `Resultado: [${PW2.removeDuplicatas(numeros).join(', ')}]`;
    }
  } else if (run === '3-var') {
    destino = 'saida-3-var';
    texto = `Saída com var:\n${PW2.comVar().join('\n')}`;
  } else if (run === '3-let') {
    destino = 'saida-3-let';
    texto = `Saída com let:\n${PW2.comLet().join('\n')}`;
  } else if (run === '4') {
    destino = 'saida-4';
    texto = `Resultado: ${PW2.jogador()}`;
  } else if (run === '5') {
    destino = 'saida-5';
    const codigo = document.getElementById('status-select').value;
    texto = `Resultado: ${PW2.status(codigo)}`;
  }

  if (destino) document.getElementById(destino).textContent = texto;
});
