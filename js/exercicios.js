'use strict';

const caixaPadrao = new Map([
  ['Arroz', 7.10], ['Feijão', 2.30], ['Macarrão', 4.70], ['Refrigerante', 3.00]
]);
const fretesPadrao = new Map([
  ['São Paulo', 10.10], ['Rio de Janeiro', 12.30], ['Brasília', 14.70], ['Outros', 13.00]
]);

window.PW2 = {
  calculaValorTotalDaCompra(produtos, cidade, caixa = caixaPadrao, fretes = fretesPadrao) {
    let subtotal = 0;
    for (const produto of produtos) {
      if (!caixa.has(produto)) throw new RangeError(`Produto desconhecido: ${produto}`);
      subtotal += caixa.get(produto);
    }
    const frete = fretes.has(cidade) ? fretes.get(cidade) : fretes.get('Outros');
    return { subtotal, frete, total: subtotal + frete };
  },
  removeDuplicatas(numeros) {
    return [...new Set(numeros)];
  },
  comVar() {
    const saida = [];
    var arrayFuncoes = [];
    for (var i = 0; i < 10; i++) arrayFuncoes.push(function(){ saida.push(i); });
    arrayFuncoes.forEach(function(funcao){ funcao(); });
    return saida;
  },
  comLet() {
    const saida = [];
    const arrayFuncoes = [];
    for (let i = 0; i < 10; i++) arrayFuncoes.push(function(){ saida.push(i); });
    arrayFuncoes.forEach(function(funcao){ funcao(); });
    return saida;
  },
  jogador() {
    const jogador = {};
    jogador.nome = 'Rodrigo';
    jogador.idade = 33;
    return jogador.nome + '_' + jogador.idade;
  },
  status(codigoAtual) {
    const status = [
      { codigo: 'OK', resposta: 'Sucesso' },
      { codigo: 'FAILED', resposta: 'Erro' },
      { codigo: 'PENDING', resposta: 'Pendente' }
    ];
    let mensagem = '';
    for (let i = 0; i < status.length; i++) {
      if (status[i].codigo === codigoAtual) mensagem = status[i].resposta;
    }
    return mensagem;
  }
};
